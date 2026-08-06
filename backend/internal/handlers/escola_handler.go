package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type EscolaHandler struct {
	repo *repository.EscolaRepository
}

func NewEscolaHandler(repo *repository.EscolaRepository) *EscolaHandler {
	return &EscolaHandler{repo: repo}
}

type EscolaRequest struct {
	EmpresaID        string  `json:"empresa_id,omitempty"`
	Nome             string  `json:"nome"`
	EnderecoCompleto string  `json:"endereco_completo"`
	CEP              *string `json:"cep,omitempty"`
	Numero           *string `json:"numero,omitempty"`
	Telefone         string  `json:"telefone,omitempty"`
	Ativa            bool    `json:"ativa"`
}

func (h *EscolaHandler) List(w http.ResponseWriter, r *http.Request) {
	empresaID := empresaIDFromClaims(r)
	escolas, err := h.repo.List(empresaID)
	if err != nil {
		log.Printf("erro ao listar escolas: %v", err)
		writeError(w, http.StatusInternalServerError, "erro ao listar escolas")
		return
	}
	writeJSON(w, http.StatusOK, escolas)
}

func (h *EscolaHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	var req EscolaRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" || req.EnderecoCompleto == "" {
		writeError(w, http.StatusBadRequest, "nome e endereço são obrigatórios")
		return
	}

	var telefone *string
	if strings.TrimSpace(req.Telefone) != "" {
		telefone = &req.Telefone
	}

	empresaID := claims.EmpresaID
	if claims.Perfil == string(models.PerfilSuporte) {
		empresaID = req.EmpresaID
	}
	if empresaID == "" {
		writeError(w, http.StatusBadRequest, "empresa não identificada")
		return
	}

	e := &models.Escola{
		EmpresaID:        empresaID,
		Nome:             req.Nome,
		EnderecoCompleto: req.EnderecoCompleto,
		CEP:              req.CEP,
		Numero:           req.Numero,
		Telefone:         telefone,
		Ativa:            req.Ativa,
	}
	if err := h.repo.Create(e); err != nil {
		log.Printf("erro ao criar escola: %v", err)
		writeError(w, http.StatusInternalServerError, "erro ao criar escola")
		return
	}
	writeJSON(w, http.StatusCreated, e)
}

func (h *EscolaHandler) Update(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	id := pathValue(r, "id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "escola não encontrada")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para editar esta escola")
		return
	}

	var req EscolaRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" || req.EnderecoCompleto == "" {
		writeError(w, http.StatusBadRequest, "nome e endereço são obrigatórios")
		return
	}

	existente.Nome = req.Nome
	existente.EnderecoCompleto = req.EnderecoCompleto
	existente.CEP = req.CEP
	existente.Numero = req.Numero
	if strings.TrimSpace(req.Telefone) != "" {
		existente.Telefone = &req.Telefone
	} else {
		existente.Telefone = nil
	}
	existente.Ativa = req.Ativa
	if err := h.repo.Update(existente); err != nil {
		log.Printf("erro ao atualizar escola: %v", err)
		writeError(w, http.StatusInternalServerError, "erro ao atualizar escola")
		return
	}
	writeJSON(w, http.StatusOK, existente)
}

func (h *EscolaHandler) Delete(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	id := pathValue(r, "id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "escola não encontrada")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para excluir esta escola")
		return
	}

	if err := h.repo.Delete(id); err != nil {
		log.Printf("erro ao excluir escola: %v", err)
		writeError(w, http.StatusInternalServerError, "erro ao excluir escola")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
