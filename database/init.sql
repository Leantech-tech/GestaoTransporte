-- ============================================================
-- Script de inicialização do banco de dados
-- Projeto: Gestão de Transporte
-- SGBD: PostgreSQL
-- ============================================================

-- Habilita extensão para UUIDs (opcional, mas recomendado)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------
-- 1. Tabela de empresas
-- Cada usuário/aluno/escola está vinculado a uma empresa.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS empresas (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome          VARCHAR(255) NOT NULL,
    cnpj          VARCHAR(20) UNIQUE,
    telefone      VARCHAR(20),
    endereco      TEXT,
    ativa         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 2. Tabela de usuários
-- Responsável pelo login no app. Pode estar vinculado a uma
-- empresa ou ser do tipo "suporte" (sem empresa fixa).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id    UUID REFERENCES empresas(id) ON DELETE SET NULL,
    nome          VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    senha_hash    VARCHAR(255) NOT NULL,
    perfil        VARCHAR(30) NOT NULL DEFAULT 'operador'
                  CHECK (perfil IN ('admin', 'operador', 'suporte')),
    ativo         BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_acesso TIMESTAMP,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 3. Tabela de escolas
-- Vinculada obrigatoriamente a uma empresa.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS escolas (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id      UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nome            VARCHAR(255) NOT NULL,
    endereco_completo TEXT NOT NULL,
    ativa           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 4. Tabela de alunos
-- Vinculado a uma empresa e a uma escola.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alunos (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id              UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    escola_id               UUID NOT NULL REFERENCES escolas(id) ON DELETE RESTRICT,
    nome                    VARCHAR(255) NOT NULL,
    endereco                TEXT NOT NULL,
    mensalidade             NUMERIC(10, 2) NOT NULL DEFAULT 0,
    valor                   NUMERIC(10, 2) NOT NULL DEFAULT 0,
    dia_vencimento          INTEGER NOT NULL CHECK (dia_vencimento BETWEEN 1 AND 31),
    responsavel_financeiro  VARCHAR(255) NOT NULL,
    responsavel_telefone    VARCHAR(20) NOT NULL,
    ativo                   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Índices para performance e integridade
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_usuarios_email      ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_empresa    ON usuarios(empresa_id);
CREATE INDEX IF NOT EXISTS idx_escolas_empresa     ON escolas(empresa_id);
CREATE INDEX IF NOT EXISTS idx_alunos_empresa      ON alunos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_alunos_escola       ON alunos(escola_id);
CREATE INDEX IF NOT EXISTS idx_alunos_nome         ON alunos(nome);

-- ------------------------------------------------------------
-- Função para atualizar o updated_at automaticamente
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION atualiza_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER trg_empresas_updated_at
    BEFORE UPDATE ON empresas
    FOR EACH ROW EXECUTE FUNCTION atualiza_updated_at();

CREATE TRIGGER trg_usuarios_updated_at
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION atualiza_updated_at();

CREATE TRIGGER trg_escolas_updated_at
    BEFORE UPDATE ON escolas
    FOR EACH ROW EXECUTE FUNCTION atualiza_updated_at();

CREATE TRIGGER trg_alunos_updated_at
    BEFORE UPDATE ON alunos
    FOR EACH ROW EXECUTE FUNCTION atualiza_updated_at();

-- ------------------------------------------------------------
-- Dados iniciais de exemplo (opcional)
-- ------------------------------------------------------------
-- INSERT INTO empresas (nome, cnpj, telefone, endereco)
-- VALUES ('Transporte Escolar Exemplo', '00.000.000/0000-00', '(11) 99999-9999', 'Rua Exemplo, 123');

-- Usuário suporte: a senha é calculada no backend/frontend conforme regra:
-- dia da semana + ano + mês + dia do mês (ex: 3-2026-07-22).
-- O hash deve ser gerado pela aplicação antes do INSERT.
-- INSERT INTO usuarios (empresa_id, nome, email, senha_hash, perfil)
-- VALUES (NULL, 'Suporte', 'suporte@sistema.com', '<HASH>', 'suporte');
