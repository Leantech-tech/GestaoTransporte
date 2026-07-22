package main

import (
	"database/sql"
	"fmt"
	"log"

	"github.com/gestao-transporte/backend/internal/auth"
	"github.com/gestao-transporte/backend/internal/models"
	"github.com/gestao-transporte/backend/internal/repository"
)

func seed(db *sql.DB, empresaRepo *repository.EmpresaRepository, usuarioRepo *repository.UsuarioRepository, escolaRepo *repository.EscolaRepository, alunoRepo *repository.AlunoRepository) error {
	var count int
	if err := db.QueryRow("SELECT COUNT(*) FROM empresas").Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		log.Println("Seed ignorado: dados já existem")
		return nil
	}

	log.Println("Executando seed...")

	// Empresas
	empresas := []models.Empresa{
		{Nome: "Transporte Escolar Alfa", CNPJ: strPtr("11.111.111/0001-11"), Telefone: strPtr("(11) 11111-1111"), Endereco: strPtr("Rua Alfa, 100")},
		{Nome: "Transporte Escolar Beta", CNPJ: strPtr("22.222.222/0002-22"), Telefone: strPtr("(22) 22222-2222"), Endereco: strPtr("Rua Beta, 200")},
	}
	empresaIDs := make([]string, len(empresas))
	for i, e := range empresas {
		if err := db.QueryRow(`
			INSERT INTO empresas (nome, cnpj, telefone, endereco)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`, e.Nome, e.CNPJ, e.Telefone, e.Endereco).Scan(&empresaIDs[i]); err != nil {
			return fmt.Errorf("empresa %s: %w", e.Nome, err)
		}
	}

	// Usuários
	usuarios := []struct {
		empresaID string
		nome      string
		email     string
		senha     string
		perfil    models.Perfil
	}{
		{empresaID: empresaIDs[0], nome: "João Silva", email: "joao@alfa.com", senha: "123456", perfil: models.PerfilAdmin},
		{empresaID: empresaIDs[1], nome: "Maria Souza", email: "maria@beta.com", senha: "123456", perfil: models.PerfilAdmin},
		{empresaID: empresaIDs[0], nome: "Operador Alfa", email: "operador@alfa.com", senha: "123456", perfil: models.PerfilOperador},
	}
	for _, u := range usuarios {
		hash, err := auth.HashPassword(u.senha)
		if err != nil {
			return err
		}
		_, err = db.Exec(`
			INSERT INTO usuarios (empresa_id, nome, email, senha_hash, perfil)
			VALUES ($1, $2, $3, $4, $5)
		`, u.empresaID, u.nome, u.email, hash, u.perfil)
		if err != nil {
			return fmt.Errorf("usuario %s: %w", u.email, err)
		}
	}

	// Escolas
	escolas := []struct {
		empresaID        string
		nome             string
		enderecoCompleto string
	}{
		{empresaID: empresaIDs[0], nome: "Escola Municipal Alfa", enderecoCompleto: "Rua das Flores, 500 - Centro"},
		{empresaID: empresaIDs[0], nome: "Colégio Particular Beta", enderecoCompleto: "Av. Brasil, 1200 - Jardim"},
		{empresaID: empresaIDs[1], nome: "Escola Estadual Gamma", enderecoCompleto: "Rua do Sol, 300 - Bairro Novo"},
	}
	escolaIDs := make([]string, len(escolas))
	for i, e := range escolas {
		if err := db.QueryRow(`
			INSERT INTO escolas (empresa_id, nome, endereco_completo)
			VALUES ($1, $2, $3)
			RETURNING id
		`, e.empresaID, e.nome, e.enderecoCompleto).Scan(&escolaIDs[i]); err != nil {
			return fmt.Errorf("escola %s: %w", e.nome, err)
		}
	}

	// Alunos
	alunos := []struct {
		empresaID             string
		escolaID              string
		nome                  string
		endereco              string
		mensalidade           float64
		valor                 float64
		diaVencimento         int
		responsavelFinanceiro string
		responsavelTelefone   string
	}{
		{empresaID: empresaIDs[0], escolaID: escolaIDs[0], nome: "Pedro Henrique", endereco: "Rua A, 45 - Centro", mensalidade: 450, valor: 450, diaVencimento: 10, responsavelFinanceiro: "Ana Paula", responsavelTelefone: "(11) 99999-0001"},
		{empresaID: empresaIDs[0], escolaID: escolaIDs[1], nome: "Laura Beatriz", endereco: "Rua B, 88 - Jardim", mensalidade: 520, valor: 520, diaVencimento: 15, responsavelFinanceiro: "Carlos Eduardo", responsavelTelefone: "(11) 99999-0002"},
		{empresaID: empresaIDs[1], escolaID: escolaIDs[2], nome: "Gabriel Santos", endereco: "Rua C, 12 - Bairro Novo", mensalidade: 380, valor: 380, diaVencimento: 5, responsavelFinanceiro: "Fernanda Lima", responsavelTelefone: "(22) 99999-0003"},
	}
	for _, a := range alunos {
		_, err := db.Exec(`
			INSERT INTO alunos (empresa_id, escola_id, nome, endereco, mensalidade, valor, dia_vencimento, responsavel_financeiro, responsavel_telefone)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		`, a.empresaID, a.escolaID, a.nome, a.endereco, a.mensalidade, a.valor, a.diaVencimento, a.responsavelFinanceiro, a.responsavelTelefone)
		if err != nil {
			return fmt.Errorf("aluno %s: %w", a.nome, err)
		}
	}

	log.Println("Seed concluído")
	return nil
}

func strPtr(s string) *string {
	return &s
}
