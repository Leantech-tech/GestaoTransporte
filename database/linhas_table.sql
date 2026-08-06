-- ============================================================
-- Script de criação da tabela 'linhas'
-- Projeto: Gestão de Transporte
-- SGBD: PostgreSQL
-- ============================================================

CREATE TABLE IF NOT EXISTS linhas (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id     UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    colaborador_id UUID NOT NULL REFERENCES colaboradores(id) ON DELETE RESTRICT,
    veiculo_id     UUID NOT NULL REFERENCES veiculos(id) ON DELETE RESTRICT,
    nome           VARCHAR(255) NOT NULL,
    origem         VARCHAR(255) NOT NULL,
    destino        VARCHAR(255) NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_linhas_empresa     ON linhas(empresa_id);
CREATE INDEX IF NOT EXISTS idx_linhas_colaborador ON linhas(colaborador_id);
CREATE INDEX IF NOT EXISTS idx_linhas_veiculo     ON linhas(veiculo_id);
CREATE INDEX IF NOT EXISTS idx_linhas_nome        ON linhas(nome);

CREATE TRIGGER IF NOT EXISTS trg_linhas_updated_at
    BEFORE UPDATE ON linhas
    FOR EACH ROW EXECUTE FUNCTION atualiza_updated_at();
