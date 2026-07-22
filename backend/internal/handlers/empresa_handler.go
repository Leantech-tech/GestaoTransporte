package handlers

import (
	"net/http"

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

func (h *EmpresaHandler) List(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil || claims.Perfil != string(models.PerfilSuporte) {
		writeError(w, http.StatusForbidden, "acesso restrito a suporte")
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
	id := r.PathValue("id")
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
