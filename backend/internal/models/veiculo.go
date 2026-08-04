package models

import "time"

type Veiculo struct {
	ID        string    `json:"id"`
	EmpresaID string    `json:"empresa_id"`
	Nome      string    `json:"nome"`
	Placa     string    `json:"placa"`
	Ativo     bool      `json:"ativo"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
