package handlers

import (
	"encoding/json"
	"net/http"

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
	EmpresaID        string `json:"empresa_id,omitempty"`
	Nome             string `json:"nome"`
	EnderecoCompleto string `json:"endereco_completo"`
	Ativa            bool   `json:"ativa"`
}

func (h *EscolaHandler) List(w http.ResponseWriter, r *http.Request) {
	empresaID := empresaIDFromClaims(r)
	escolas, err := h.repo.List(empresaID)
	if err != nil {
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
		Ativa:            req.Ativa,
	}
	if err := h.repo.Create(e); err != nil {
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

	id := r.PathValue("id")
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
	existente.Ativa = req.Ativa
	if err := h.repo.Update(existente); err != nil {
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

	id := r.PathValue("id")
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
		writeError(w, http.StatusInternalServerError, "erro ao excluir escola")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
