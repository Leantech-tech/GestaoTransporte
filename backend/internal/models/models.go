package models

import "time"

type Perfil string

const (
	PerfilAdmin    Perfil = "admin"
	PerfilOperador Perfil = "operador"
	PerfilSuporte  Perfil = "suporte"
)

type Empresa struct {
	ID        string     `json:"id"`
	Nome      string     `json:"nome"`
	CNPJ      *string    `json:"cnpj,omitempty"`
	Telefone  *string    `json:"telefone,omitempty"`
	Endereco  *string    `json:"endereco,omitempty"`
	Ativa     bool       `json:"ativa"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
}

type Usuario struct {
	ID           string     `json:"id"`
	EmpresaID    *string    `json:"empresa_id,omitempty"`
	Nome         string     `json:"nome"`
	Email        string     `json:"email"`
	Perfil       Perfil     `json:"perfil"`
	Ativo        bool       `json:"ativo"`
	UltimoAcesso *time.Time `json:"ultimo_acesso,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

type Escola struct {
	ID              string    `json:"id"`
	EmpresaID       string    `json:"empresa_id"`
	Nome            string    `json:"nome"`
	EnderecoCompleto string   `json:"endereco_completo"`
	Ativa           bool      `json:"ativa"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type Aluno struct {
	ID                   string    `json:"id"`
	EmpresaID            string    `json:"empresa_id"`
	EscolaID             string    `json:"escola_id"`
	Nome                 string    `json:"nome"`
	Endereco             string    `json:"endereco"`
	Mensalidade          float64   `json:"mensalidade"`
	Valor                float64   `json:"valor"`
	DiaVencimento        int       `json:"dia_vencimento"`
	ResponsavelFinanceiro string   `json:"responsavel_financeiro"`
	ResponsavelTelefone  string    `json:"responsavel_telefone"`
	Ativo                bool      `json:"ativo"`
	CreatedAt            time.Time `json:"created_at"`
	UpdatedAt            time.Time `json:"updated_at"`
}
