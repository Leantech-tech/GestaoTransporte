package repository

import (
	"database/sql"
	"time"

	"github.com/gestao-transporte/backend/internal/models"
)

type MensalidadeRepository struct {
	db *sql.DB
}

func NewMensalidadeRepository(db *sql.DB) *MensalidadeRepository {
	return &MensalidadeRepository{db: db}
}

func (r *MensalidadeRepository) List(empresaID string) ([]models.Mensalidade, error) {
	var rows *sql.Rows
	var err error

	baseQuery := `
		SELECT m.id, m.empresa_id, m.aluno_id, a.nome AS aluno_nome, m.valor,
		       m.data_vencimento, m.data_pagamento, m.status, m.observacao,
		       m.created_at, m.updated_at
		FROM mensalidades m
		JOIN alunos a ON a.id = m.aluno_id
	`
	if empresaID == "" {
		rows, err = r.db.Query(baseQuery + `ORDER BY m.data_vencimento, a.nome`)
	} else {
		rows, err = r.db.Query(baseQuery+`WHERE m.empresa_id = $1 ORDER BY m.data_vencimento, a.nome`, empresaID)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mensalidades []models.Mensalidade
	for rows.Next() {
		var m models.Mensalidade
		var dataPagamento sql.NullTime
		if err := rows.Scan(&m.ID, &m.EmpresaID, &m.AlunoID, &m.AlunoNome, &m.Valor,
			&m.DataVencimento, &dataPagamento, &m.Status, &m.Observacao,
			&m.CreatedAt, &m.UpdatedAt); err != nil {
			return nil, err
		}
		if dataPagamento.Valid {
			m.DataPagamento = &dataPagamento.Time
		}
		mensalidades = append(mensalidades, m)
	}
	return mensalidades, rows.Err()
}

func (r *MensalidadeRepository) FindByID(id string) (*models.Mensalidade, error) {
	row := r.db.QueryRow(`
		SELECT m.id, m.empresa_id, m.aluno_id, a.nome AS aluno_nome, m.valor,
		       m.data_vencimento, m.data_pagamento, m.status, m.observacao,
		       m.created_at, m.updated_at
		FROM mensalidades m
		JOIN alunos a ON a.id = m.aluno_id
		WHERE m.id = $1
	`, id)

	var m models.Mensalidade
	var dataPagamento sql.NullTime
	err := row.Scan(&m.ID, &m.EmpresaID, &m.AlunoID, &m.AlunoNome, &m.Valor,
		&m.DataVencimento, &dataPagamento, &m.Status, &m.Observacao,
		&m.CreatedAt, &m.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if dataPagamento.Valid {
		m.DataPagamento = &dataPagamento.Time
	}
	return &m, nil
}

func (r *MensalidadeRepository) FindByAlunoMes(alunoID string, dataVencimento time.Time) (*models.Mensalidade, error) {
	row := r.db.QueryRow(`
		SELECT id, empresa_id, aluno_id, valor, data_vencimento, data_pagamento,
		       status, observacao, created_at, updated_at
		FROM mensalidades
		WHERE aluno_id = $1 AND data_vencimento = $2
	`, alunoID, dataVencimento)

	var m models.Mensalidade
	var dataPagamento sql.NullTime
	err := row.Scan(&m.ID, &m.EmpresaID, &m.AlunoID, &m.Valor,
		&m.DataVencimento, &dataPagamento, &m.Status, &m.Observacao,
		&m.CreatedAt, &m.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if dataPagamento.Valid {
		m.DataPagamento = &dataPagamento.Time
	}
	return &m, nil
}

func (r *MensalidadeRepository) Create(m *models.Mensalidade) error {
	return r.db.QueryRow(`
		INSERT INTO mensalidades (empresa_id, aluno_id, valor, data_vencimento,
		                         data_pagamento, status, observacao)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`, m.EmpresaID, m.AlunoID, m.Valor, m.DataVencimento,
		m.DataPagamento, m.Status, m.Observacao).Scan(&m.ID, &m.CreatedAt, &m.UpdatedAt)
}

func (r *MensalidadeRepository) Update(m *models.Mensalidade) error {
	_, err := r.db.Exec(`
		UPDATE mensalidades
		SET aluno_id = $1, valor = $2, data_vencimento = $3,
		    data_pagamento = $4, status = $5, observacao = $6
		WHERE id = $7
	`, m.AlunoID, m.Valor, m.DataVencimento, m.DataPagamento, m.Status, m.Observacao, m.ID)
	return err
}

func (r *MensalidadeRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM mensalidades WHERE id = $1`, id)
	return err
}
