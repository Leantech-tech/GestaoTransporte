package models

import "time"

type Colaborador struct {
	ID        string    `json:"id"`
	EmpresaID string    `json:"empresa_id"`
	Nome      string    `json:"nome"`
	Tipo      string    `json:"tipo"`
	Telefone  string    `json:"telefone"`
	CPF       string    `json:"cpf"`
	Ativa     bool      `json:"ativa"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
