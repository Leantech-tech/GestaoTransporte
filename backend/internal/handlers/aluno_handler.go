package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

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
	CEP                   *string `json:"cep,omitempty"`
	Numero                *string `json:"numero,omitempty"`
	Mensalidade           float64 `json:"mensalidade"`
	Valor                 float64 `json:"valor"`
	DiaVencimento         int     `json:"dia_vencimento"`
	ResponsavelFinanceiro string  `json:"responsavel_financeiro"`
	ResponsavelTelefone   string  `json:"responsavel_telefone"`
	DataInicioContrato    string  `json:"data_inicio_contrato,omitempty"`
	DataFimContrato       string  `json:"data_fim_contrato,omitempty"`
	Ativo                 bool    `json:"ativo"`
}

func (h *AlunoHandler) List(w http.ResponseWriter, r *http.Request) {
	empresaID := empresaIDFromClaims(r)
	alunos, err := h.repo.List(empresaID)
	if err != nil {
		log.Printf("erro ao listar alunos: %v", err)
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
	if empresaID == "" {
		empresaID = req.EmpresaID
	}
	if empresaID == "" {
		writeError(w, http.StatusBadRequest, "empresa não identificada")
		return
	}

	var dataInicioContrato *time.Time
	var dataFimContrato *time.Time
	if req.DataInicioContrato != "" || req.DataFimContrato != "" {
		if req.DataInicioContrato == "" || req.DataFimContrato == "" {
			writeError(w, http.StatusBadRequest, "informe data inicial e data final do contrato")
			return
		}
		dti, err := parseDate(req.DataInicioContrato)
		if err != nil {
			writeError(w, http.StatusBadRequest, "data inicial de contrato inválida")
			return
		}
		dtf, err := parseDate(req.DataFimContrato)
		if err != nil {
			writeError(w, http.StatusBadRequest, "data final de contrato inválida")
			return
		}
		if dtf.Before(dti) {
			writeError(w, http.StatusBadRequest, "data final deve ser igual ou posterior à data inicial")
			return
		}
		dataInicioContrato = &dti
		dataFimContrato = &dtf
	}

	a := &models.Aluno{
		EmpresaID:             empresaID,
		EscolaID:              req.EscolaID,
		Nome:                  req.Nome,
		Endereco:              req.Endereco,
		CEP:                   req.CEP,
		Numero:                req.Numero,
		Mensalidade:           req.Mensalidade,
		Valor:                 req.Valor,
		DiaVencimento:         req.DiaVencimento,
		ResponsavelFinanceiro: req.ResponsavelFinanceiro,
		ResponsavelTelefone:   req.ResponsavelTelefone,
		DataInicioContrato:    dataInicioContrato,
		DataFimContrato:       dataFimContrato,
		Ativo:                 req.Ativo,
	}
	if err := h.repo.Create(a); err != nil {
		log.Printf("erro ao criar aluno: %v", err)
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

	id := pathValue(r, "id")
	existente, err := h.repo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "aluno não encontrado")
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

	if claims.Perfil != string(models.PerfilSuporte) {
		if claims.EmpresaID != "" && existente.EmpresaID != claims.EmpresaID {
			writeError(w, http.StatusForbidden, "sem permissão para editar este aluno")
			return
		}
		if claims.EmpresaID == "" && req.EmpresaID != "" && req.EmpresaID != existente.EmpresaID {
			writeError(w, http.StatusForbidden, "sem permissão para alterar a empresa deste aluno")
			return
		}
	}

	empresaID := existente.EmpresaID
	if req.EmpresaID != "" {
		empresaID = req.EmpresaID
	}
	if claims.EmpresaID != "" {
		empresaID = claims.EmpresaID
	}

	existente.EmpresaID = empresaID
	existente.EscolaID = req.EscolaID
	existente.Nome = req.Nome
	existente.Endereco = req.Endereco
	existente.CEP = req.CEP
	existente.Numero = req.Numero
	existente.Mensalidade = req.Mensalidade
	existente.Valor = req.Valor
	existente.DiaVencimento = req.DiaVencimento
	existente.ResponsavelFinanceiro = req.ResponsavelFinanceiro
	existente.ResponsavelTelefone = req.ResponsavelTelefone
	if req.DataInicioContrato != "" || req.DataFimContrato != "" {
		if req.DataInicioContrato == "" || req.DataFimContrato == "" {
			writeError(w, http.StatusBadRequest, "informe data inicial e data final do contrato")
			return
		}
		dti, err := parseDate(req.DataInicioContrato)
		if err != nil {
			writeError(w, http.StatusBadRequest, "data inicial de contrato inválida")
			return
		}
		dtf, err := parseDate(req.DataFimContrato)
		if err != nil {
			writeError(w, http.StatusBadRequest, "data final de contrato inválida")
			return
		}
		if dtf.Before(dti) {
			writeError(w, http.StatusBadRequest, "data final deve ser igual ou posterior à data inicial")
			return
		}
		existente.DataInicioContrato = &dti
		existente.DataFimContrato = &dtf
	}
	existente.Ativo = req.Ativo

	if err := h.repo.Update(existente); err != nil {
		log.Printf("erro ao atualizar aluno: %v", err)
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

	id := pathValue(r, "id")
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
		log.Printf("erro ao excluir aluno: %v", err)
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
