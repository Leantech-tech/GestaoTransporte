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
		SELECT id, nome, cnpj, telefone, endereco, ativa, created_at, updated_at
		FROM empresas ORDER BY nome
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var empresas []models.Empresa
	for rows.Next() {
		var e models.Empresa
		if err := rows.Scan(&e.ID, &e.Nome, &e.CNPJ, &e.Telefone, &e.Endereco, &e.Ativa, &e.CreatedAt, &e.UpdatedAt); err != nil {
			return nil, err
		}
		empresas = append(empresas, e)
	}
	return empresas, rows.Err()
}

func (r *EmpresaRepository) FindByID(id string) (*models.Empresa, error) {
	row := r.db.QueryRow(`
		SELECT id, nome, cnpj, telefone, endereco, ativa, created_at, updated_at
		FROM empresas WHERE id = $1
	`, id)
	var e models.Empresa
	err := row.Scan(&e.ID, &e.Nome, &e.CNPJ, &e.Telefone, &e.Endereco, &e.Ativa, &e.CreatedAt, &e.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &e, err
}
