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
