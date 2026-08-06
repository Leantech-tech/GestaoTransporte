package repository

import (
	"database/sql"

	"github.com/gestao-transporte/backend/internal/models"
)

type AlunoRepository struct {
	db *sql.DB
}

func NewAlunoRepository(db *sql.DB) *AlunoRepository {
	return &AlunoRepository{db: db}
}

func (r *AlunoRepository) List(empresaID string) ([]models.Aluno, error) {
	var rows *sql.Rows
	var err error
	if empresaID == "" {
		rows, err = r.db.Query(`
			SELECT id, empresa_id, escola_id, nome, endereco, cep, numero, mensalidade, valor,
			       dia_vencimento, responsavel_financeiro, responsavel_telefone,
			       data_inicio_contrato, data_fim_contrato, ativo, created_at, updated_at
			FROM alunos ORDER BY nome
		`)
	} else {
		rows, err = r.db.Query(`
			SELECT id, empresa_id, escola_id, nome, endereco, cep, numero, mensalidade, valor,
			       dia_vencimento, responsavel_financeiro, responsavel_telefone,
			       data_inicio_contrato, data_fim_contrato, ativo, created_at, updated_at
			FROM alunos WHERE empresa_id = $1 ORDER BY nome
		`, empresaID)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	alunos := make([]models.Aluno, 0)
	for rows.Next() {
		var a models.Aluno
		if err := rows.Scan(&a.ID, &a.EmpresaID, &a.EscolaID, &a.Nome, &a.Endereco, &a.CEP, &a.Numero,
			&a.Mensalidade, &a.Valor, &a.DiaVencimento, &a.ResponsavelFinanceiro,
			&a.ResponsavelTelefone, &a.DataInicioContrato, &a.DataFimContrato, &a.Ativo, &a.CreatedAt, &a.UpdatedAt); err != nil {
			return nil, err
		}
		alunos = append(alunos, a)
	}
	return alunos, rows.Err()
}

func (r *AlunoRepository) FindByID(id string) (*models.Aluno, error) {
	row := r.db.QueryRow(`
		SELECT id, empresa_id, escola_id, nome, endereco, cep, numero, mensalidade, valor,
		       dia_vencimento, responsavel_financeiro, responsavel_telefone,
		       data_inicio_contrato, data_fim_contrato, ativo, created_at, updated_at
		FROM alunos WHERE id = $1
	`, id)
	var a models.Aluno
	err := row.Scan(&a.ID, &a.EmpresaID, &a.EscolaID, &a.Nome, &a.Endereco, &a.CEP, &a.Numero,
		&a.Mensalidade, &a.Valor, &a.DiaVencimento, &a.ResponsavelFinanceiro,
		&a.ResponsavelTelefone, &a.DataInicioContrato, &a.DataFimContrato, &a.Ativo, &a.CreatedAt, &a.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &a, err
}

func (r *AlunoRepository) Create(a *models.Aluno) error {
	return r.db.QueryRow(`
		INSERT INTO alunos (empresa_id, escola_id, nome, endereco, cep, numero, mensalidade, valor,
		                    dia_vencimento, responsavel_financeiro, responsavel_telefone,
		                    data_inicio_contrato, data_fim_contrato, ativo)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		RETURNING id, created_at, updated_at
	`, a.EmpresaID, a.EscolaID, a.Nome, a.Endereco, a.CEP, a.Numero, a.Mensalidade, a.Valor,
		a.DiaVencimento, a.ResponsavelFinanceiro, a.ResponsavelTelefone,
		a.DataInicioContrato, a.DataFimContrato, a.Ativo).Scan(&a.ID, &a.CreatedAt, &a.UpdatedAt)
}

func (r *AlunoRepository) Update(a *models.Aluno) error {
	_, err := r.db.Exec(`
		UPDATE alunos SET escola_id = $1, nome = $2, endereco = $3, cep = $4, numero = $5,
		                  mensalidade = $6, valor = $7, dia_vencimento = $8, responsavel_financeiro = $9,
		                  responsavel_telefone = $10, data_inicio_contrato = $11,
		                  data_fim_contrato = $12, ativo = $13
		WHERE id = $14
	`, a.EscolaID, a.Nome, a.Endereco, a.CEP, a.Numero, a.Mensalidade, a.Valor, a.DiaVencimento,
		a.ResponsavelFinanceiro, a.ResponsavelTelefone, a.DataInicioContrato,
		a.DataFimContrato, a.Ativo, a.ID)
	return err
}

func (r *AlunoRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM alunos WHERE id = $1`, id)
	return err
}
