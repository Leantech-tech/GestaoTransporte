package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type VeiculoHandler struct {
	repo *repository.VeiculoRepository
}

func NewVeiculoHandler(repo *repository.VeiculoRepository) *VeiculoHandler {
	return &VeiculoHandler{repo: repo}
}

type VeiculoRequest struct {
	Nome  string `json:"nome"`
	Placa string `json:"placa"`
	Ativo bool   `json:"ativo"`
}

func (h *VeiculoHandler) List(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	empresaID := ""
	if claims.Perfil != string(models.PerfilSuporte) {
		empresaID = claims.EmpresaID
	}

	veiculos, err := h.repo.List(empresaID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao listar veículos")
		return
	}
	writeJSON(w, http.StatusOK, veiculos)
}

func (h *VeiculoHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	var req VeiculoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" || req.Placa == "" {
		writeError(w, http.StatusBadRequest, "nome e placa são obrigatórios")
		return
	}

	veiculo := &models.Veiculo{
		EmpresaID: claims.EmpresaID,
		Nome:      req.Nome,
		Placa:     req.Placa,
		Ativo:     req.Ativo,
	}

	if err := h.repo.Create(veiculo); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao criar veículo")
		return
	}
	writeJSON(w, http.StatusCreated, veiculo)
}

func (h *VeiculoHandler) Update(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	id := pathValue(r, "id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "veículo não encontrado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para editar este veículo")
		return
	}

	var req VeiculoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" || req.Placa == "" {
		writeError(w, http.StatusBadRequest, "nome e placa são obrigatórios")
		return
	}

	existente.Nome = req.Nome
	existente.Placa = req.Placa
	existente.Ativo = req.Ativo

	if err := h.repo.Update(existente); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao atualizar veículo")
		return
	}
	writeJSON(w, http.StatusOK, existente)
}

func (h *VeiculoHandler) Delete(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	id := pathValue(r, "id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "veículo não encontrado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para excluir este veículo")
		return
	}

	if err := h.repo.Delete(id); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao excluir veículo")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
