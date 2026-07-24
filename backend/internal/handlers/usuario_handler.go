package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gestao-transporte/backend/internal/auth"
	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type UsuarioHandler struct {
	usuarioRepo *repository.UsuarioRepository
}

func NewUsuarioHandler(usuarioRepo *repository.UsuarioRepository) *UsuarioHandler {
	return &UsuarioHandler{usuarioRepo: usuarioRepo}
}

type UsuarioRequest struct {
	EmpresaID *string `json:"empresa_id,omitempty"`
	Nome      string  `json:"nome"`
	Email     string  `json:"email"`
	Senha     string  `json:"senha,omitempty"`
	Perfil    string  `json:"perfil"`
	Ativo     bool    `json:"ativo"`
}

func (h *UsuarioHandler) canManage(claims *auth.Claims, targetEmpresaID *string) bool {
	if claims == nil {
		return false
	}
	if claims.Perfil == string(models.PerfilSuporte) {
		return true
	}
	if claims.Perfil != string(models.PerfilAdmin) {
		return false
	}
	if targetEmpresaID == nil {
		return false
	}
	return *targetEmpresaID == claims.EmpresaID
}

func (h *UsuarioHandler) targetEmpresaID(claims *auth.Claims, req *UsuarioRequest) *string {
	if claims.Perfil == string(models.PerfilSuporte) {
		return req.EmpresaID
	}
	if claims.Perfil == string(models.PerfilAdmin) {
		return &claims.EmpresaID
	}
	return nil
}

func (h *UsuarioHandler) List(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	empresaID := ""
	if claims.Perfil == string(models.PerfilAdmin) {
		empresaID = claims.EmpresaID
	}

	usuarios, err := h.usuarioRepo.List(empresaID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao listar usuários")
		return
	}
	writeJSON(w, http.StatusOK, usuarios)
}

func (h *UsuarioHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	var req UsuarioRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" || req.Email == "" || req.Senha == "" || req.Perfil == "" {
		writeError(w, http.StatusBadRequest, "nome, e-mail, senha e perfil são obrigatórios")
		return
	}
	if req.Perfil != string(models.PerfilAdmin) && req.Perfil != string(models.PerfilOperador) {
		writeError(w, http.StatusBadRequest, "perfil inválido")
		return
	}

	targetEmpresaID := h.targetEmpresaID(claims, &req)
	if targetEmpresaID == nil || *targetEmpresaID == "" {
		writeError(w, http.StatusBadRequest, "empresa não identificada")
		return
	}

	senhaHash, err := auth.HashPassword(req.Senha)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao processar senha")
		return
	}

	u := &models.Usuario{
		EmpresaID: targetEmpresaID,
		Nome:      req.Nome,
		Email:     req.Email,
		Perfil:    models.Perfil(req.Perfil),
		Ativo:     req.Ativo,
	}
	if err := h.usuarioRepo.Create(u, senhaHash); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao criar usuário")
		return
	}
	writeJSON(w, http.StatusCreated, u)
}

func (h *UsuarioHandler) Update(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	id := r.PathValue("id")
	existente, err := h.usuarioRepo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "usuário não encontrado")
		return
	}
	if !h.canManage(claims, existente.EmpresaID) {
		writeError(w, http.StatusForbidden, "sem permissão para editar este usuário")
		return
	}

	var req UsuarioRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.Nome == "" || req.Email == "" || req.Perfil == "" {
		writeError(w, http.StatusBadRequest, "nome, e-mail e perfil são obrigatórios")
		return
	}
	if req.Perfil != string(models.PerfilAdmin) && req.Perfil != string(models.PerfilOperador) {
		writeError(w, http.StatusBadRequest, "perfil inválido")
		return
	}

	newEmpresaID := h.targetEmpresaID(claims, &req)
	if newEmpresaID == nil || *newEmpresaID == "" {
		writeError(w, http.StatusBadRequest, "empresa não identificada")
		return
	}
	// Admin não pode transferir usuário para outra empresa.
	if claims.Perfil == string(models.PerfilAdmin) && (existente.EmpresaID == nil || *existente.EmpresaID != *newEmpresaID) {
		writeError(w, http.StatusForbidden, "não é permitido alterar a empresa do usuário")
		return
	}

	existente.EmpresaID = newEmpresaID
	existente.Nome = req.Nome
	existente.Email = req.Email
	existente.Perfil = models.Perfil(req.Perfil)
	existente.Ativo = req.Ativo

	if err := h.usuarioRepo.Update(existente); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao atualizar usuário")
		return
	}
	if req.Senha != "" {
		senhaHash, err := auth.HashPassword(req.Senha)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "erro ao processar senha")
			return
		}
		if err := h.usuarioRepo.UpdatePassword(id, senhaHash); err != nil {
			writeError(w, http.StatusInternalServerError, "erro ao atualizar senha")
			return
		}
	}
	writeJSON(w, http.StatusOK, existente)
}

func (h *UsuarioHandler) Delete(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	id := r.PathValue("id")
	if claims.UsuarioID == id {
		writeError(w, http.StatusBadRequest, "não é possível excluir o próprio usuário")
		return
	}

	existente, err := h.usuarioRepo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "usuário não encontrado")
		return
	}
	if !h.canManage(claims, existente.EmpresaID) {
		writeError(w, http.StatusForbidden, "sem permissão para excluir este usuário")
		return
	}

	if err := h.usuarioRepo.Delete(id); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao excluir usuário")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
