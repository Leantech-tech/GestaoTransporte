package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type ColaboradorHandler struct {
	repo *repository.ColaboradorRepository
}

func NewColaboradorHandler(repo *repository.ColaboradorRepository) *ColaboradorHandler {
	return &ColaboradorHandler{repo: repo}
}

type ColaboradorRequest struct {
	Nome     string `json:"nome"`
	Tipo     string `json:"tipo"`
	Telefone string `json:"telefone"`
	CPF      string `json:"cpf"`
	Ativa    bool   `json:"ativa"`
}

func (h *ColaboradorHandler) List(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	empresaID := ""
	if claims.Perfil != string(models.PerfilSuporte) {
		empresaID = claims.EmpresaID
	}

	colaboradores, err := h.repo.List(empresaID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao listar colaboradores")
		return
	}
	writeJSON(w, http.StatusOK, colaboradores)
}

func (h *ColaboradorHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	var req ColaboradorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" || req.Tipo == "" || req.Telefone == "" || req.CPF == "" {
		writeError(w, http.StatusBadRequest, "nome, tipo, telefone e cpf são obrigatórios")
		return
	}

	tipo := req.Tipo
	switch tipo {
	case "motorista", "professor", "monitor":
	case "professor(a)":
		tipo = "professor"
	case "monitor(a)":
		tipo = "monitor"
	default:
		writeError(w, http.StatusBadRequest, "tipo de colaborador inválido")
		return
	}

	colaborador := &models.Colaborador{
		EmpresaID: claims.EmpresaID,
		Nome:      req.Nome,
		Tipo:      tipo,
		Telefone:  req.Telefone,
		CPF:       req.CPF,
		Ativa:     req.Ativa,
	}

	if err := h.repo.Create(colaborador); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao criar colaborador")
		return
	}
	writeJSON(w, http.StatusCreated, colaborador)
}

func (h *ColaboradorHandler) Update(w http.ResponseWriter, r *http.Request) {
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
		writeError(w, http.StatusNotFound, "colaborador não encontrado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para editar este colaborador")
		return
	}

	var req ColaboradorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" || req.Tipo == "" || req.Telefone == "" || req.CPF == "" {
		writeError(w, http.StatusBadRequest, "nome, tipo, telefone e cpf são obrigatórios")
		return
	}

	tipo := req.Tipo
	switch tipo {
	case "motorista", "professor", "monitor":
	case "professor(a)":
		tipo = "professor"
	case "monitor(a)":
		tipo = "monitor"
	default:
		writeError(w, http.StatusBadRequest, "tipo de colaborador inválido")
		return
	}

	existente.Nome = req.Nome
	existente.Tipo = tipo
	existente.Telefone = req.Telefone
	existente.CPF = req.CPF
	existente.Ativa = req.Ativa

	if err := h.repo.Update(existente); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao atualizar colaborador")
		return
	}
	writeJSON(w, http.StatusOK, existente)
}

func (h *ColaboradorHandler) Delete(w http.ResponseWriter, r *http.Request) {
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
		writeError(w, http.StatusNotFound, "colaborador não encontrado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para excluir este colaborador")
		return
	}

	if err := h.repo.Delete(id); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao excluir colaborador")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
