package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type LinhaHandler struct {
	repo *repository.LinhaRepository
}

func NewLinhaHandler(repo *repository.LinhaRepository) *LinhaHandler {
	return &LinhaHandler{repo: repo}
}

type LinhaRequest struct {
	ColaboradorID string `json:"colaborador_id"`
	VeiculoID     string `json:"veiculo_id"`
	Nome          string `json:"nome"`
	Origem        string `json:"origem"`
	Destino       string `json:"destino"`
}

type LinhaListRequest struct {
	NomeLinha       string `json:"nome_linha,omitempty"`
	NomeColaborador string `json:"nome_colaborador,omitempty"`
	NomeVeiculo     string `json:"nome_veiculo,omitempty"`
}

func (h *LinhaHandler) List(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	filter := repository.LinhaFilter{}
	if claims.Perfil != string(models.PerfilSuporte) {
		filter.EmpresaID = claims.EmpresaID
	}

	// Filtros podem vir por query string (GET) ou por body JSON.
	filter.NomeLinha = r.URL.Query().Get("nome_linha")
	filter.NomeColaborador = r.URL.Query().Get("nome_colaborador")
	filter.NomeVeiculo = r.URL.Query().Get("nome_veiculo")

	linhas, err := h.repo.List(filter)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao listar linhas")
		return
	}
	writeJSON(w, http.StatusOK, linhas)
}

func (h *LinhaHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && claims.Perfil != string(models.PerfilAdmin) {
		writeError(w, http.StatusForbidden, "acesso restrito")
		return
	}

	var req LinhaRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.ColaboradorID == "" || req.VeiculoID == "" || req.Nome == "" || req.Origem == "" || req.Destino == "" {
		writeError(w, http.StatusBadRequest, "colaborador, veículo, nome, origem e destino são obrigatórios")
		return
	}

	empresaID := claims.EmpresaID
	if claims.Perfil == string(models.PerfilSuporte) {
		// Suporte pode vincular a qualquer empresa; porém o frontend deve enviar empresa_id se necessário.
		// Como o modelo atual não recebe empresa_id no request, mantemos a empresa do usuário logado.
		// Para suporte sem empresa, exigimos que informe no futuro; por enquanto rejeitamos.
		if empresaID == "" {
			writeError(w, http.StatusBadRequest, "suporte deve informar a empresa vinculada")
			return
		}
	}
	if empresaID == "" {
		writeError(w, http.StatusBadRequest, "empresa não identificada")
		return
	}

	l := &models.Linha{
		EmpresaID:     empresaID,
		ColaboradorID: req.ColaboradorID,
		VeiculoID:     req.VeiculoID,
		Nome:          req.Nome,
		Origem:        req.Origem,
		Destino:       req.Destino,
	}
	if err := h.repo.Create(l); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao criar linha")
		return
	}
	writeJSON(w, http.StatusCreated, l)
}

func (h *LinhaHandler) Update(w http.ResponseWriter, r *http.Request) {
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
		writeError(w, http.StatusNotFound, "linha não encontrada")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para editar esta linha")
		return
	}

	var req LinhaRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if req.ColaboradorID == "" || req.VeiculoID == "" || req.Nome == "" || req.Origem == "" || req.Destino == "" {
		writeError(w, http.StatusBadRequest, "colaborador, veículo, nome, origem e destino são obrigatórios")
		return
	}

	existente.ColaboradorID = req.ColaboradorID
	existente.VeiculoID = req.VeiculoID
	existente.Nome = req.Nome
	existente.Origem = req.Origem
	existente.Destino = req.Destino

	if err := h.repo.Update(existente); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao atualizar linha")
		return
	}
	writeJSON(w, http.StatusOK, existente)
}

func (h *LinhaHandler) Delete(w http.ResponseWriter, r *http.Request) {
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
		writeError(w, http.StatusNotFound, "linha não encontrada")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para excluir esta linha")
		return
	}

	if err := h.repo.Delete(id); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao excluir linha")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
