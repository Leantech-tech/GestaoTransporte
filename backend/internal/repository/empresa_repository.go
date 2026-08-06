package repository

import (
	"database/sql"

	"github.com/gestao-transporte/backend/internal/models"
)

type EmpresaRepository struct {
	db *sql.DB
}

func NewEmpresaRepository(db *sql.DB) *EmpresaRepository {
	return &EmpresaRepository{db: db}
}

func (r *EmpresaRepository) ListAll() ([]models.Empresa, error) {
	rows, err := r.db.Query(`
		SELECT id, nome, cnpj, telefone, cep, endereco, numero, ativa, created_at, updated_at
		FROM empresas ORDER BY nome
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	empresas := make([]models.Empresa, 0)
	for rows.Next() {
		var e models.Empresa
		if err := rows.Scan(&e.ID, &e.Nome, &e.CNPJ, &e.Telefone, &e.CEP, &e.Endereco, &e.Numero, &e.Ativa, &e.CreatedAt, &e.UpdatedAt); err != nil {
			return nil, err
		}
		empresas = append(empresas, e)
	}
	return empresas, rows.Err()
}

func (r *EmpresaRepository) FindByID(id string) (*models.Empresa, error) {
	row := r.db.QueryRow(`
		SELECT id, nome, cnpj, telefone, cep, endereco, numero, ativa, created_at, updated_at
		FROM empresas WHERE id = $1
	`, id)
	var e models.Empresa
	err := row.Scan(&e.ID, &e.Nome, &e.CNPJ, &e.Telefone, &e.CEP, &e.Endereco, &e.Numero, &e.Ativa, &e.CreatedAt, &e.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &e, err
}

func (r *EmpresaRepository) Create(e *models.Empresa) error {
	return r.db.QueryRow(`
		INSERT INTO empresas (nome, cnpj, telefone, cep, endereco, numero, ativa)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`, e.Nome, e.CNPJ, e.Telefone, e.CEP, e.Endereco, e.Numero, e.Ativa).Scan(&e.ID, &e.CreatedAt, &e.UpdatedAt)
}

func (r *EmpresaRepository) Update(e *models.Empresa) error {
	_, err := r.db.Exec(`
		UPDATE empresas SET nome = $1, cnpj = $2, telefone = $3, cep = $4, endereco = $5, numero = $6, ativa = $7
		WHERE id = $8
	`, e.Nome, e.CNPJ, e.Telefone, e.CEP, e.Endereco, e.Numero, e.Ativa, e.ID)
	return err
}

func (r *EmpresaRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM empresas WHERE id = $1`, id)
	return err
}
