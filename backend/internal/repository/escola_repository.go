package repository

import (
	"database/sql"

	"github.com/gestao-transporte/backend/internal/models"
)

type EscolaRepository struct {
	db *sql.DB
}

func NewEscolaRepository(db *sql.DB) *EscolaRepository {
	return &EscolaRepository{db: db}
}

func (r *EscolaRepository) List(empresaID string) ([]models.Escola, error) {
	var rows *sql.Rows
	var err error
	if empresaID == "" {
		rows, err = r.db.Query(`
			SELECT id, empresa_id, nome, endereco_completo, cep, numero, telefone, ativa, created_at, updated_at
			FROM escolas ORDER BY nome
		`)
	} else {
		rows, err = r.db.Query(`
			SELECT id, empresa_id, nome, endereco_completo, cep, numero, telefone, ativa, created_at, updated_at
			FROM escolas WHERE empresa_id = $1 ORDER BY nome
		`, empresaID)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	escolas := make([]models.Escola, 0)
	for rows.Next() {
		var e models.Escola
		if err := rows.Scan(&e.ID, &e.EmpresaID, &e.Nome, &e.EnderecoCompleto, &e.CEP, &e.Numero, &e.Telefone, &e.Ativa, &e.CreatedAt, &e.UpdatedAt); err != nil {
			return nil, err
		}
		escolas = append(escolas, e)
	}
	return escolas, rows.Err()
}

func (r *EscolaRepository) FindByID(id string) (*models.Escola, error) {
	row := r.db.QueryRow(`
		SELECT id, empresa_id, nome, endereco_completo, cep, numero, telefone, ativa, created_at, updated_at
		FROM escolas WHERE id = $1
	`, id)
	var e models.Escola
	err := row.Scan(&e.ID, &e.EmpresaID, &e.Nome, &e.EnderecoCompleto, &e.CEP, &e.Numero, &e.Telefone, &e.Ativa, &e.CreatedAt, &e.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &e, err
}

func (r *EscolaRepository) Create(e *models.Escola) error {
	return r.db.QueryRow(`
		INSERT INTO escolas (empresa_id, nome, endereco_completo, cep, numero, telefone, ativa)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`, e.EmpresaID, e.Nome, e.EnderecoCompleto, e.CEP, e.Numero, e.Telefone, e.Ativa).Scan(&e.ID, &e.CreatedAt, &e.UpdatedAt)
}

func (r *EscolaRepository) Update(e *models.Escola) error {
	_, err := r.db.Exec(`
		UPDATE escolas SET nome = $1, endereco_completo = $2, cep = $3, numero = $4, telefone = $5, ativa = $6
		WHERE id = $7
	`, e.Nome, e.EnderecoCompleto, e.CEP, e.Numero, e.Telefone, e.Ativa, e.ID)
	return err
}

func (r *EscolaRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM escolas WHERE id = $1`, id)
	return err
}
