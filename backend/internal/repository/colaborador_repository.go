package repository

import (
	"database/sql"

	"github.com/gestao-transporte/backend/internal/models"
)

type ColaboradorRepository struct {
	db *sql.DB
}

func NewColaboradorRepository(db *sql.DB) *ColaboradorRepository {
	return &ColaboradorRepository{db: db}
}

func (r *ColaboradorRepository) List(empresaID string) ([]models.Colaborador, error) {
	var rows *sql.Rows
	var err error
	if empresaID == "" {
		rows, err = r.db.Query(`
			SELECT id, empresa_id, nome, tipo, telefone, cpf, ativa, created_at, updated_at
			FROM colaboradores ORDER BY nome
		`)
	} else {
		rows, err = r.db.Query(`
			SELECT id, empresa_id, nome, tipo, telefone, cpf, ativa, created_at, updated_at
			FROM colaboradores WHERE empresa_id = $1 ORDER BY nome
		`, empresaID)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	colaboradores := make([]models.Colaborador, 0)
	for rows.Next() {
		var c models.Colaborador
		if err := rows.Scan(&c.ID, &c.EmpresaID, &c.Nome, &c.Tipo, &c.Telefone, &c.CPF, &c.Ativa, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, err
		}
		colaboradores = append(colaboradores, c)
	}
	return colaboradores, rows.Err()
}

func (r *ColaboradorRepository) FindByID(id string) (*models.Colaborador, error) {
	row := r.db.QueryRow(`
		SELECT id, empresa_id, nome, tipo, telefone, cpf, ativa, created_at, updated_at
		FROM colaboradores WHERE id = $1
	`, id)
	var c models.Colaborador
	err := row.Scan(&c.ID, &c.EmpresaID, &c.Nome, &c.Tipo, &c.Telefone, &c.CPF, &c.Ativa, &c.CreatedAt, &c.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &c, err
}

func (r *ColaboradorRepository) Create(c *models.Colaborador) error {
	return r.db.QueryRow(`
		INSERT INTO colaboradores (empresa_id, nome, tipo, telefone, cpf, ativa)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`, c.EmpresaID, c.Nome, c.Tipo, c.Telefone, c.CPF, c.Ativa).
		Scan(&c.ID, &c.CreatedAt, &c.UpdatedAt)
}

func (r *ColaboradorRepository) Update(c *models.Colaborador) error {
	_, err := r.db.Exec(`
		UPDATE colaboradores SET nome = $1, tipo = $2, telefone = $3, cpf = $4, ativa = $5
		WHERE id = $6
	`, c.Nome, c.Tipo, c.Telefone, c.CPF, c.Ativa, c.ID)
	return err
}

func (r *ColaboradorRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM colaboradores WHERE id = $1`, id)
	return err
}
