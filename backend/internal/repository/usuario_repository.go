package repository

import (
	"database/sql"

	"github.com/gestao-transporte/backend/internal/models"
)

type UsuarioRepository struct {
	db *sql.DB
}

func NewUsuarioRepository(db *sql.DB) *UsuarioRepository {
	return &UsuarioRepository{db: db}
}

func (r *UsuarioRepository) FindByEmail(email string) (*models.Usuario, error) {
	row := r.db.QueryRow(`
		SELECT id, empresa_id, nome, email, perfil, ativo, ultimo_acesso, created_at, updated_at
		FROM usuarios WHERE email = $1 AND ativo = true
	`, email)
	var u models.Usuario
	err := row.Scan(&u.ID, &u.EmpresaID, &u.Nome, &u.Email, &u.Perfil, &u.Ativo, &u.UltimoAcesso, &u.CreatedAt, &u.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &u, err
}

func (r *UsuarioRepository) FindByEmailWithPassword(email string) (*models.Usuario, string, error) {
	row := r.db.QueryRow(`
		SELECT id, empresa_id, nome, email, senha_hash, perfil, ativo, ultimo_acesso, created_at, updated_at
		FROM usuarios WHERE email = $1 AND ativo = true
	`, email)
	var u models.Usuario
	var senhaHash string
	err := row.Scan(&u.ID, &u.EmpresaID, &u.Nome, &u.Email, &senhaHash, &u.Perfil, &u.Ativo, &u.UltimoAcesso, &u.CreatedAt, &u.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, "", nil
	}
	return &u, senhaHash, err
}

func (r *UsuarioRepository) FindByID(id string) (*models.Usuario, error) {
	row := r.db.QueryRow(`
		SELECT id, empresa_id, nome, email, perfil, ativo, ultimo_acesso, created_at, updated_at
		FROM usuarios WHERE id = $1
	`, id)
	var u models.Usuario
	err := row.Scan(&u.ID, &u.EmpresaID, &u.Nome, &u.Email, &u.Perfil, &u.Ativo, &u.UltimoAcesso, &u.CreatedAt, &u.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &u, err
}

func (r *UsuarioRepository) List(empresaID string) ([]models.Usuario, error) {
	var rows *sql.Rows
	var err error
	if empresaID == "" {
		rows, err = r.db.Query(`
			SELECT id, empresa_id, nome, email, perfil, ativo, ultimo_acesso, created_at, updated_at
			FROM usuarios ORDER BY nome
		`)
	} else {
		rows, err = r.db.Query(`
			SELECT id, empresa_id, nome, email, perfil, ativo, ultimo_acesso, created_at, updated_at
			FROM usuarios WHERE empresa_id = $1 ORDER BY nome
		`, empresaID)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	usuarios := make([]models.Usuario, 0)
	for rows.Next() {
		var u models.Usuario
		if err := rows.Scan(&u.ID, &u.EmpresaID, &u.Nome, &u.Email, &u.Perfil, &u.Ativo, &u.UltimoAcesso, &u.CreatedAt, &u.UpdatedAt); err != nil {
			return nil, err
		}
		usuarios = append(usuarios, u)
	}
	return usuarios, rows.Err()
}

func (r *UsuarioRepository) Update(u *models.Usuario) error {
	_, err := r.db.Exec(`
		UPDATE usuarios SET empresa_id = $1, nome = $2, email = $3, perfil = $4, ativo = $5
		WHERE id = $6
	`, u.EmpresaID, u.Nome, u.Email, u.Perfil, u.Ativo, u.ID)
	return err
}

func (r *UsuarioRepository) UpdatePassword(id string, senhaHash string) error {
	_, err := r.db.Exec(`UPDATE usuarios SET senha_hash = $1 WHERE id = $2`, senhaHash, id)
	return err
}

func (r *UsuarioRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM usuarios WHERE id = $1`, id)
	return err
}

func (r *UsuarioRepository) UpdateUltimoAcesso(id string) error {
	_, err := r.db.Exec(`UPDATE usuarios SET ultimo_acesso = NOW() WHERE id = $1`, id)
	return err
}

func (r *UsuarioRepository) Create(u *models.Usuario, senhaHash string) error {
	return r.db.QueryRow(`
		INSERT INTO usuarios (empresa_id, nome, email, senha_hash, perfil, ativo)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`, u.EmpresaID, u.Nome, u.Email, senhaHash, u.Perfil, u.Ativo).Scan(&u.ID, &u.CreatedAt, &u.UpdatedAt)
}
