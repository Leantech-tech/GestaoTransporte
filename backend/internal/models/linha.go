package models

import "time"

type Linha struct {
	ID            string    `json:"id"`
	EmpresaID     string    `json:"empresa_id"`
	ColaboradorID string    `json:"colaborador_id"`
	VeiculoID     string    `json:"veiculo_id"`
	Nome          string    `json:"nome"`
	Origem        string    `json:"origem"`
	Destino       string    `json:"destino"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}
