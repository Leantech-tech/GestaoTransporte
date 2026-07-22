package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type AlunoHandler struct {
	repo *repository.AlunoRepository
}

func NewAlunoHandler(repo *repository.AlunoRepository) *AlunoHandler {
	return &AlunoHandler{repo: repo}
}

type AlunoRequest struct {
	EmpresaID             string  `json:"empresa_id,omitempty"`
	EscolaID              string  `json:"escola_id"`
	Nome                  string  `json:"nome"`
	Endereco              string  `json:"endereco"`
	Mensalidade           float64 `json:"mensalidade"`
	Valor                 float64 `json:"valor"`
	DiaVencimento         int     `json:"dia_vencimento"`
	ResponsavelFinanceiro string  `json:"responsavel_financeiro"`
	ResponsavelTelefone   string  `json:"responsavel_telefone"`
	Ativo                 bool    `json:"ativo"`
}

func (h *AlunoHandler) List(w http.ResponseWriter, r *http.Request) {
	empresaID := empresaIDFromClaims(r)
	alunos, err := h.repo.List(empresaID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao listar alunos")
		return
	}
	writeJSON(w, http.StatusOK, alunos)
}

func (h *AlunoHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	var req AlunoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if err := validateAlunoRequest(req); err != "" {
		writeError(w, http.StatusBadRequest, err)
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

	a := &models.Aluno{
		EmpresaID:             empresaID,
		EscolaID:              req.EscolaID,
		Nome:                  req.Nome,
		Endereco:              req.Endereco,
		Mensalidade:           req.Mensalidade,
		Valor:                 req.Valor,
		DiaVencimento:         req.DiaVencimento,
		ResponsavelFinanceiro: req.ResponsavelFinanceiro,
		ResponsavelTelefone:   req.ResponsavelTelefone,
		Ativo:                 req.Ativo,
	}
	if err := h.repo.Create(a); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao criar aluno")
		return
	}
	writeJSON(w, http.StatusCreated, a)
}

func (h *AlunoHandler) Update(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	id := r.PathValue("id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "aluno não encontrado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para editar este aluno")
		return
	}

	var req AlunoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if err := validateAlunoRequest(req); err != "" {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	existente.EscolaID = req.EscolaID
	existente.Nome = req.Nome
	existente.Endereco = req.Endereco
	existente.Mensalidade = req.Mensalidade
	existente.Valor = req.Valor
	existente.DiaVencimento = req.DiaVencimento
	existente.ResponsavelFinanceiro = req.ResponsavelFinanceiro
	existente.ResponsavelTelefone = req.ResponsavelTelefone
	existente.Ativo = req.Ativo

	if err := h.repo.Update(existente); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao atualizar aluno")
		return
	}
	writeJSON(w, http.StatusOK, existente)
}

func (h *AlunoHandler) Delete(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	id := r.PathValue("id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "aluno não encontrado")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para excluir este aluno")
		return
	}

	if err := h.repo.Delete(id); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao excluir aluno")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func validateAlunoRequest(req AlunoRequest) string {
	if req.Nome == "" {
		return "nome é obrigatório"
	}
	if req.Endereco == "" {
		return "endereço é obrigatório"
	}
	if req.EscolaID == "" {
		return "escola é obrigatória"
	}
	if req.DiaVencimento < 1 || req.DiaVencimento > 31 {
		return "dia de vencimento inválido"
	}
	if req.ResponsavelFinanceiro == "" {
		return "responsável financeiro é obrigatório"
	}
	if req.ResponsavelTelefone == "" {
		return "telefone do responsável é obrigatório"
	}
	return ""
}
