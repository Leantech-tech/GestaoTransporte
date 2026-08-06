-- ============================================================
-- Script para adicionar a coluna 'numero' nas tabelas de
-- endereço do sistema de Gestão de Transporte
-- SGBD: PostgreSQL
-- ============================================================

ALTER TABLE empresas
    ADD COLUMN IF NOT EXISTS numero VARCHAR(20);

ALTER TABLE escolas
    ADD COLUMN IF NOT EXISTS numero VARCHAR(20);

ALTER TABLE alunos
    ADD COLUMN IF NOT EXISTS numero VARCHAR(20);
