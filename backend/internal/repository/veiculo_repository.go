package repository

import (
	"database/sql"

	"github.com/gestao-transporte/backend/internal/models"
)

type VeiculoRepository struct {
	db *sql.DB
}

func NewVeiculoRepository(db *sql.DB) *VeiculoRepository {
	return &VeiculoRepository{db: db}
}

func (r *VeiculoRepository) List(empresaID string) ([]models.Veiculo, error) {
	var rows *sql.Rows
	var err error
	if empresaID == "" {
		rows, err = r.db.Query(`
            SELECT id, empresa_id, nome, placa, ativo, created_at, updated_at
            FROM veiculos ORDER BY nome
        `)
	} else {
		rows, err = r.db.Query(`
            SELECT id, empresa_id, nome, placa, ativo, created_at, updated_at
            FROM veiculos WHERE empresa_id = $1 ORDER BY nome
        `, empresaID)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	veiculos := make([]models.Veiculo, 0)
	for rows.Next() {
		var v models.Veiculo
		if err := rows.Scan(&v.ID, &v.EmpresaID, &v.Nome, &v.Placa, &v.Ativo, &v.CreatedAt, &v.UpdatedAt); err != nil {
			return nil, err
		}
		veiculos = append(veiculos, v)
	}
	return veiculos, rows.Err()
}

func (r *VeiculoRepository) FindByID(id string) (*models.Veiculo, error) {
	row := r.db.QueryRow(`
        SELECT id, empresa_id, nome, placa, ativo, created_at, updated_at
        FROM veiculos WHERE id = $1
    `, id)
	var v models.Veiculo
	err := row.Scan(&v.ID, &v.EmpresaID, &v.Nome, &v.Placa, &v.Ativo, &v.CreatedAt, &v.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &v, err
}

func (r *VeiculoRepository) Create(v *models.Veiculo) error {
	return r.db.QueryRow(`
        INSERT INTO veiculos (empresa_id, nome, placa, ativo)
        VALUES ($1, $2, $3, $4)
        RETURNING id, created_at, updated_at
    `, v.EmpresaID, v.Nome, v.Placa, v.Ativo).
		Scan(&v.ID, &v.CreatedAt, &v.UpdatedAt)
}

func (r *VeiculoRepository) Update(v *models.Veiculo) error {
	_, err := r.db.Exec(`
        UPDATE veiculos SET nome = $1, placa = $2, ativo = $3
        WHERE id = $4
    `, v.Nome, v.Placa, v.Ativo, v.ID)
	return err
}

func (r *VeiculoRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM veiculos WHERE id = $1`, id)
	return err
}
