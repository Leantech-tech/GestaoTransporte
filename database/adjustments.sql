-- ============================================================
-- Ajustes e novas tabelas para o sistema de Gestão de Transporte
-- ============================================================

-- 1. Novas colunas para cadastro de endereço e CEP
ALTER TABLE empresas
    ADD COLUMN IF NOT EXISTS cep VARCHAR(9);

ALTER TABLE escolas
    ADD COLUMN IF NOT EXISTS telefone VARCHAR(20);
ALTER TABLE escolas
    ADD COLUMN IF NOT EXISTS cep VARCHAR(9);

ALTER TABLE alunos
    ADD COLUMN IF NOT EXISTS cep VARCHAR(9);
ALTER TABLE alunos
    ADD COLUMN IF NOT EXISTS data_inicio_contrato DATE;
ALTER TABLE alunos
    ADD COLUMN IF NOT EXISTS data_fim_contrato DATE;

-- 2. Tabela de colaboradores
CREATE TABLE IF NOT EXISTS colaboradores (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id    UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nome          VARCHAR(255) NOT NULL,
    tipo          VARCHAR(20) NOT NULL CHECK (tipo IN ('motorista', 'professor', 'monitor')),
    telefone      VARCHAR(20) NOT NULL,
    cpf           VARCHAR(20) NOT NULL,
    ativa         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabela de veículos
CREATE TABLE IF NOT EXISTS veiculos (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id    UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nome          VARCHAR(255) NOT NULL,
    placa         VARCHAR(20) NOT NULL,
    ativo         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabela de linhas
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

-- Índices adicionais
CREATE INDEX IF NOT EXISTS idx_colaboradores_empresa ON colaboradores(empresa_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_empresa ON veiculos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_linhas_empresa ON linhas(empresa_id);
CREATE INDEX IF NOT EXISTS idx_linhas_colaborador ON linhas(colaborador_id);
CREATE INDEX IF NOT EXISTS idx_linhas_veiculo ON linhas(veiculo_id);

-- Triggers de atualização automática
CREATE TRIGGER IF NOT EXISTS trg_colaboradores_updated_at
    BEFORE UPDATE ON colaboradores
    FOR EACH ROW EXECUTE FUNCTION atualiza_updated_at();

CREATE TRIGGER IF NOT EXISTS trg_veiculos_updated_at
    BEFORE UPDATE ON veiculos
    FOR EACH ROW EXECUTE FUNCTION atualiza_updated_at();

CREATE TRIGGER IF NOT EXISTS trg_linhas_updated_at
    BEFORE UPDATE ON linhas
    FOR EACH ROW EXECUTE FUNCTION atualiza_updated_at();
