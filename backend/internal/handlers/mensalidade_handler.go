package handlers

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

type MensalidadeHandler struct {
	mensalidadeRepo *repository.MensalidadeRepository
	alunoRepo       *repository.AlunoRepository
}

func NewMensalidadeHandler(mensalidadeRepo *repository.MensalidadeRepository, alunoRepo *repository.AlunoRepository) *MensalidadeHandler {
	return &MensalidadeHandler{
		mensalidadeRepo: mensalidadeRepo,
		alunoRepo:       alunoRepo,
	}
}

type MensalidadeRequest struct {
	AlunoID        string     `json:"aluno_id"`
	Valor          float64    `json:"valor"`
	DataVencimento string     `json:"data_vencimento"`
	DataPagamento  *string    `json:"data_pagamento,omitempty"`
	Status         string     `json:"status"`
	Observacao     string     `json:"observacao,omitempty"`
}

type GerarMensalidadesRequest struct {
	AlunoID      string  `json:"aluno_id,omitempty"`
	Quantidade   int     `json:"quantidade"`
	GerarTodos   bool    `json:"gerar_todos"`
	DataEmissao  *string `json:"data_emissao,omitempty"`
}

type GerarMensalidadesResponse struct {
	Geradas int `json:"geradas"`
}

func (h *MensalidadeHandler) List(w http.ResponseWriter, r *http.Request) {
	empresaID := empresaIDFromClaims(r)
	mensalidades, err := h.mensalidadeRepo.List(empresaID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao listar mensalidades")
		return
	}
	writeJSON(w, http.StatusOK, mensalidades)
}

func (h *MensalidadeHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	var req MensalidadeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}

	if err := validateMensalidadeRequest(req); err != "" {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	aluno, err := h.alunoRepo.FindByID(req.AlunoID)
	if err != nil || aluno == nil {
		writeError(w, http.StatusNotFound, "aluno não encontrado")
		return
	}

	empresaID := claims.EmpresaID
	if claims.Perfil == string(models.PerfilSuporte) {
		empresaID = aluno.EmpresaID
	}

	dataVencimento, err := parseDate(req.DataVencimento)
	if err != nil {
		writeError(w, http.StatusBadRequest, "data de vencimento inválida")
		return
	}

	var dataPagamento *time.Time
	if req.DataPagamento != nil {
		dp, err := parseDate(*req.DataPagamento)
		if err != nil {
			writeError(w, http.StatusBadRequest, "data de pagamento inválida")
			return
		}
		dataPagamento = &dp
	}

	m := &models.Mensalidade{
		EmpresaID:      empresaID,
		AlunoID:        req.AlunoID,
		Valor:          req.Valor,
		DataVencimento: dataVencimento,
		DataPagamento:  dataPagamento,
		Status:         req.Status,
		Observacao:     req.Observacao,
	}
	if err := h.mensalidadeRepo.Create(m); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao criar mensalidade")
		return
	}
	writeJSON(w, http.StatusCreated, m)
}

func (h *MensalidadeHandler) BulkGenerate(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	var req GerarMensalidadesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}

	if req.Quantidade < 1 {
		writeError(w, http.StatusBadRequest, "quantidade deve ser pelo menos 1")
		return
	}

	var alunos []models.Aluno
	if req.GerarTodos {
		empresaID := claims.EmpresaID
		if claims.Perfil == string(models.PerfilSuporte) {
			empresaID = ""
		}
		lista, err := h.alunoRepo.List(empresaID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "erro ao listar alunos")
			return
		}
		for _, a := range lista {
			if a.Ativo {
				alunos = append(alunos, a)
			}
		}
	} else {
		if req.AlunoID == "" {
			writeError(w, http.StatusBadRequest, "aluno é obrigatório quando não gerar todos")
			return
		}
		aluno, err := h.alunoRepo.FindByID(req.AlunoID)
		if err != nil || aluno == nil {
			writeError(w, http.StatusNotFound, "aluno não encontrado")
			return
		}
		if !aluno.Ativo {
			writeError(w, http.StatusBadRequest, "aluno está inativo")
			return
		}
		alunos = append(alunos, *aluno)
	}

	geradas := 0
	dataEmissao := time.Now().UTC()
	if req.DataEmissao != nil {
		d, err := parseDate(*req.DataEmissao)
		if err != nil {
			writeError(w, http.StatusBadRequest, "data de emissão inválida")
			return
		}
		dataEmissao = d
	}
	currentYear, currentMonth, currentDay := dataEmissao.Date()

	for _, aluno := range alunos {
		// Se a emissão ocorreu antes ou no dia do vencimento, a primeira mensalidade é no mês atual.
		// Se a emissão ocorreu depois do dia do vencimento, a primeira mensalidade é no mês seguinte.
		mesesAdicionais := 0
		if currentDay > aluno.DiaVencimento {
			mesesAdicionais = 1
		}

		for i := 0; i < req.Quantidade; i++ {
			totalMonths := int(currentMonth) + mesesAdicionais + i
			year := currentYear + (totalMonths-1)/12
			month := time.Month((totalMonths-1)%12 + 1)
			day := aluno.DiaVencimento
			lastDay := lastDayOfMonth(year, month)
			if day > lastDay {
				day = lastDay
			}

			dataVencimento := time.Date(year, month, day, 0, 0, 0, 0, time.UTC)

			existente, err := h.mensalidadeRepo.FindByAlunoMes(aluno.ID, dataVencimento)
			if err != nil {
				msg := fmt.Sprintf("erro ao verificar mensalidade existente: %v", err)
				log.Printf("%s (aluno=%s data=%v)", msg, aluno.ID, dataVencimento)
				writeError(w, http.StatusInternalServerError, msg)
				return
			}
			if existente != nil {
				continue
			}

			m := &models.Mensalidade{
				EmpresaID:      aluno.EmpresaID,
				AlunoID:        aluno.ID,
				Valor:          aluno.Valor,
				DataVencimento: dataVencimento,
				Status:         "pendente",
			}
			if err := h.mensalidadeRepo.Create(m); err != nil {
				msg := fmt.Sprintf("erro ao gerar mensalidade: %v", err)
				log.Printf("%s (aluno=%s data=%v)", msg, aluno.ID, dataVencimento)
				writeError(w, http.StatusInternalServerError, msg)
				return
			}
			geradas++
		}
	}

	writeJSON(w, http.StatusCreated, GerarMensalidadesResponse{Geradas: geradas})
}

func (h *MensalidadeHandler) Update(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	id := r.PathValue("id")
	existente, err := h.mensalidadeRepo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "mensalidade não encontrada")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para editar esta mensalidade")
		return
	}

	var req MensalidadeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "corpo inválido")
		return
	}
	if err := validateMensalidadeRequest(req); err != "" {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	dataVencimento, err := parseDate(req.DataVencimento)
	if err != nil {
		writeError(w, http.StatusBadRequest, "data de vencimento inválida")
		return
	}

	var dataPagamento *time.Time
	if req.DataPagamento != nil {
		dp, err := parseDate(*req.DataPagamento)
		if err != nil {
			writeError(w, http.StatusBadRequest, "data de pagamento inválida")
			return
		}
		dataPagamento = &dp
	}

	existente.AlunoID = req.AlunoID
	existente.Valor = req.Valor
	existente.DataVencimento = dataVencimento
	existente.DataPagamento = dataPagamento
	existente.Status = req.Status
	existente.Observacao = req.Observacao

	if err := h.mensalidadeRepo.Update(existente); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao atualizar mensalidade")
		return
	}
	writeJSON(w, http.StatusOK, existente)
}

func (h *MensalidadeHandler) Delete(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "não autenticado")
		return
	}

	id := r.PathValue("id")
	existente, err := h.mensalidadeRepo.FindByID(id)
	if err != nil || existente == nil {
		writeError(w, http.StatusNotFound, "mensalidade não encontrada")
		return
	}
	if claims.Perfil != string(models.PerfilSuporte) && existente.EmpresaID != claims.EmpresaID {
		writeError(w, http.StatusForbidden, "sem permissão para excluir esta mensalidade")
		return
	}

	if err := h.mensalidadeRepo.Delete(id); err != nil {
		writeError(w, http.StatusInternalServerError, "erro ao excluir mensalidade")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func validateMensalidadeRequest(req MensalidadeRequest) string {
	if req.AlunoID == "" {
		return "aluno é obrigatório"
	}
	if req.DataVencimento == "" {
		return "data de vencimento é obrigatória"
	}
	if req.Status != "pendente" && req.Status != "pago" && req.Status != "cancelado" {
		return "status inválido"
	}
	return ""
}

func parseDate(s string) (time.Time, error) {
	return time.Parse("2006-01-02", s)
}

func lastDayOfMonth(year int, month time.Month) int {
	return time.Date(year, month+1, 0, 0, 0, 0, 0, time.UTC).Day()
}
