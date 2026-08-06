package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/gestao-transporte/backend/internal/models"
)

type LinhaFilter struct {
	EmpresaID        string
	NomeLinha        string
	NomeColaborador  string
	NomeVeiculo      string
}

type LinhaRepository struct {
	db *sql.DB
}

func NewLinhaRepository(db *sql.DB) *LinhaRepository {
	return &LinhaRepository{db: db}
}

func (r *LinhaRepository) List(filter LinhaFilter) ([]models.Linha, error) {
	where := []string{}
	args := []interface{}{}
	argIndex := 1

	if filter.EmpresaID != "" {
		where = append(where, fmt.Sprintf("l.empresa_id = $%d", argIndex))
		args = append(args, filter.EmpresaID)
		argIndex++
	}
	if strings.TrimSpace(filter.NomeLinha) != "" {
		where = append(where, fmt.Sprintf("l.nome ILIKE $%d", argIndex))
		args = append(args, "%"+filter.NomeLinha+"%")
		argIndex++
	}
	if strings.TrimSpace(filter.NomeColaborador) != "" {
		where = append(where, fmt.Sprintf("c.nome ILIKE $%d", argIndex))
		args = append(args, "%"+filter.NomeColaborador+"%")
		argIndex++
	}
	if strings.TrimSpace(filter.NomeVeiculo) != "" {
		where = append(where, fmt.Sprintf("v.nome ILIKE $%d", argIndex))
		args = append(args, "%"+filter.NomeVeiculo+"%")
		argIndex++
	}

	query := `
		SELECT l.id, l.empresa_id, l.colaborador_id, l.veiculo_id, l.nome, l.origem, l.destino, l.created_at, l.updated_at
		FROM linhas l
		JOIN colaboradores c ON c.id = l.colaborador_id
		JOIN veiculos v ON v.id = l.veiculo_id
	`
	if len(where) > 0 {
		query += " WHERE " + strings.Join(where, " AND ")
	}
	query += " ORDER BY l.nome"

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	linhas := make([]models.Linha, 0)
	for rows.Next() {
		var l models.Linha
		if err := rows.Scan(&l.ID, &l.EmpresaID, &l.ColaboradorID, &l.VeiculoID, &l.Nome, &l.Origem, &l.Destino, &l.CreatedAt, &l.UpdatedAt); err != nil {
			return nil, err
		}
		linhas = append(linhas, l)
	}
	return linhas, rows.Err()
}

func (r *LinhaRepository) FindByID(id string) (*models.Linha, error) {
	row := r.db.QueryRow(`
		SELECT id, empresa_id, colaborador_id, veiculo_id, nome, origem, destino, created_at, updated_at
		FROM linhas WHERE id = $1
	`, id)
	var l models.Linha
	err := row.Scan(&l.ID, &l.EmpresaID, &l.ColaboradorID, &l.VeiculoID, &l.Nome, &l.Origem, &l.Destino, &l.CreatedAt, &l.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &l, err
}

func (r *LinhaRepository) Create(l *models.Linha) error {
	return r.db.QueryRow(`
		INSERT INTO linhas (empresa_id, colaborador_id, veiculo_id, nome, origem, destino)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`, l.EmpresaID, l.ColaboradorID, l.VeiculoID, l.Nome, l.Origem, l.Destino).
		Scan(&l.ID, &l.CreatedAt, &l.UpdatedAt)
}

func (r *LinhaRepository) Update(l *models.Linha) error {
	_, err := r.db.Exec(`
		UPDATE linhas SET colaborador_id = $1, veiculo_id = $2, nome = $3, origem = $4, destino = $5
		WHERE id = $6
	`, l.ColaboradorID, l.VeiculoID, l.Nome, l.Origem, l.Destino, l.ID)
	return err
}

func (r *LinhaRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM linhas WHERE id = $1`, id)
	return err
}
