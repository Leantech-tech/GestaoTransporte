package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gestao-transporte/backend/internal/auth"
	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type EmpresaHandler struct {
	repo *repository.EmpresaRepository
}

func NewEmpresaHandler(repo *repository.EmpresaRepository) *EmpresaHandler {
	return &EmpresaHandler{repo: repo}
}

func (h *EmpresaHandler) canRead(claims *auth.Claims) bool {
	return claims != nil && (claims.Perfil == string(models.PerfilSuporte) || claims.Perfil == string(models.PerfilAdmin))
}

func (h *EmpresaHandler) canWrite(claims *auth.Claims) bool {
	return claims != nil && claims.Perfil == string(models.PerfilSuporte)
}

func (h *EmpresaHandler) List(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if !h.canRead(claims) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	empresas, err := h.repo.ListAll()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao listar empresas")
		return
	}
	writeJSON(w, http.StatusOK, empresas)
}

func (h *EmpresaHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if !h.canRead(claims) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	id := pathValue(r, "id")
	empresa, err := h.repo.FindByID(id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao buscar empresa")
		return
	}
	if empresa == nil {
		writeError(w, http.StatusNotFound, "empresa não encontrada")
		return
	}
	writeJSON(w, http.StatusOK, empresa)
}

func (h *EmpresaHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if !h.canWrite(claims) {
		writeError(w, http.StatusForbidden, "acesso restrito a suporte")
		return
	}

	var e models.Empresa
	if err := json.NewDecoder(r.Body).Decode(&e); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if e.Nome == "" {
		writeError(w, http.StatusBadRequest, "nome é obrigatório")
		return
	}

	if err := h.repo.Create(&e); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao criar empresa")
		return
	}
	writeJSON(w, http.StatusCreated, e)
}

func (h *EmpresaHandler) Update(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if !h.canWrite(claims) {
		writeError(w, http.StatusForbidden, "acesso restrito a suporte")
		return
	}

	id := pathValue(r, "id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "empresa não encontrada")
		return
	}

	var req models.Empresa
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" {
		writeError(w, http.StatusBadRequest, "nome é obrigatório")
		return
	}

	existente.Nome = req.Nome
	existente.CNPJ = req.CNPJ
	existente.Telefone = req.Telefone
	existente.Endereco = req.Endereco
	existente.Ativa = req.Ativa

	if err := h.repo.Update(existente); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao atualizar empresa")
		return
	}
	writeJSON(w, http.StatusOK, existente)
}

func (h *EmpresaHandler) Delete(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if !h.canWrite(claims) {
		writeError(w, http.StatusForbidden, "acesso restrito a suporte")
		return
	}

	id := pathValue(r, "id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "empresa não encontrada")
		return
	}

	if err := h.repo.Delete(id); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao excluir empresa")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
