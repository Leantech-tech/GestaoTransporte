package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/gestao-transporte/backend/internal/auth"
	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type AuthHandler struct {
	usuarioRepo *repository.UsuarioRepository
	empresaRepo *repository.EmpresaRepository
}

func NewAuthHandler(ur *repository.UsuarioRepository, er *repository.EmpresaRepository) *AuthHandler {
	return &AuthHandler{usuarioRepo: ur, empresaRepo: er}
}

type LoginRequest struct {
	Email string `json:"email"`
	Senha string `json:"senha"`
}

type LoginResponse struct {
	Token   string         `json:"token"`
	Usuario models.Usuario `json:"usuario"`
	Empresa *models.Empresa `json:"empresa,omitempty"`
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo da requisição inválido")
		return
	}
	req.Email = strings.TrimSpace(req.Email)
	req.Senha = strings.TrimSpace(req.Senha)

	if strings.ToLower(req.Email) == "suporte" {
		h.loginSuporte(w, req.Senha)
		return
	}

	h.loginUsuario(w, req.Email, req.Senha)
}

func (h *AuthHandler) loginSuporte(w http.ResponseWriter, senha string) {
	senhaEsperada := auth.SenhaSuporte(time.Now())
	senhaEsperadaAntiga := auth.SenhaSuporteAntiga(time.Now())
	if senha != senhaEsperada && senha != senhaEsperadaAntiga {
		writeError(w, http.StatusUnauthorized, "senha de suporte inválida")
		return
	}

	token, err := auth.GenerateToken("suporte", "", string(models.PerfilSuporte))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao gerar token")
		return
	}

	writeJSON(w, http.StatusOK, LoginResponse{
		Token: token,
		Usuario: models.Usuario{
			ID:     "suporte",
			Nome:   "Suporte",
			Email:  "suporte@sistema.com",
			Perfil: models.PerfilSuporte,
			Ativo:  true,
		},
	})
}

func (h *AuthHandler) loginUsuario(w http.ResponseWriter, email, senha string) {
	usuario, senhaHash, err := h.usuarioRepo.FindByEmailWithPassword(email)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao buscar usuário")
		return
	}
	if usuario == nil || !auth.CheckPassword(senha, senhaHash) {
		writeError(w, http.StatusUnauthorized, "e-mail ou senha inválidos")
		return
	}

	empresaID := ""
	if usuario.EmpresaID != nil {
		empresaID = *usuario.EmpresaID
	}

	token, err := auth.GenerateToken(usuario.ID, empresaID, string(usuario.Perfil))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao gerar token")
		return
	}

	_ = h.usuarioRepo.UpdateUltimoAcesso(usuario.ID)

	var empresa *models.Empresa
	if usuario.EmpresaID != nil {
		empresa, _ = h.empresaRepo.FindByID(*usuario.EmpresaID)
	}

	writeJSON(w, http.StatusOK, LoginResponse{
		Token:   token,
		Usuario: *usuario,
		Empresa: empresa,
	})
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	if claims.UsuarioID == "suporte" {
		writeJSON(w, http.StatusOK, models.Usuario{
			ID:     "suporte",
			Nome:   "Suporte",
			Email:  "suporte@sistema.com",
			Perfil: models.PerfilSuporte,
			Ativo:  true,
		})
		return
	}

	usuario, err := h.usuarioRepo.FindByID(claims.UsuarioID)
	if err != nil || usuario == nil {
		writeError(w, http.StatusNotFound, "usuário não encontrado")
		return
	}
	writeJSON(w, http.StatusOK, usuario)
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": message})
}
