/* 
  Supabase Database Schema for PDA Control (v4.0 - Quantity Based)
  Focus: Total quantities per Area and per Leader, instead of SN.
*/

-- 1. Áreas (Locais de estoque e operação)
CREATE TABLE IF NOT EXISTS areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL UNIQUE,
    quantidade_total INT DEFAULT 0, -- Total de PDAs que a área "possui" (incluindo emprestados)
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Líderes
CREATE TABLE IF NOT EXISTS lideres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL UNIQUE,
    area_id UUID REFERENCES areas(id) ON DELETE SET NULL,
    turno TEXT, -- T1, T2, T3
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Inventário por Líder (Quantos PDAs cada líder tem agora)
CREATE TABLE IF NOT EXISTS lider_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lider_id UUID REFERENCES lideres(id) ON DELETE CASCADE UNIQUE,
    quantidade INT DEFAULT 0 CHECK (quantidade >= 0),
    last_updated TIMESTAMPTZ DEFAULT now()
);

-- 4. Movimentações (Histórico de Saídas, Retornos e Trocas)
CREATE TABLE IF NOT EXISTS movimentacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lider_id UUID REFERENCES lideres(id) ON DELETE SET NULL,
    tipo TEXT NOT NULL, -- 'Saída', 'Retorno', 'Transferência-Enviada', 'Transferência-Recebida'
    quantidade INT NOT NULL,
    data TIMESTAMPTZ DEFAULT now(),
    admin_id TEXT, -- Identificação de quem liberou/recebeu
    observacao TEXT,
    origem_destino_id UUID REFERENCES lideres(id) -- Para transferências entre líderes
);

-- 5. Trocas (Solicitações de transferência entre líderes pendentes de Admin)
CREATE TABLE IF NOT EXISTS trocas_pendentes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lider_origem_id UUID REFERENCES lideres(id) ON DELETE CASCADE,
    lider_destino_id UUID REFERENCES lideres(id) ON DELETE CASCADE,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    status TEXT DEFAULT 'PENDENTE', -- PENDENTE, APROVADO, REJEITADO
    data_solicitacao TIMESTAMPTZ DEFAULT now(),
    admin_id TEXT -- Quem aprovou/rejeitou
);

-- 6. Planejamento (Metas por Turno)
CREATE TABLE IF NOT EXISTS planejamento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data DATE NOT NULL,
    turno TEXT NOT NULL, -- T1, T2, T3
    area_id UUID REFERENCES areas(id) ON DELETE CASCADE,
    quantidade INT DEFAULT 0,
    UNIQUE(data, turno, area_id)
);

-- ==========================================
-- DADOS FICTÍCIOS PARA TESTE (SEED DATA)
-- ==========================================

-- Inserindo Áreas com quantidades totais de PDAs cada uma "possui"
INSERT INTO areas (nome, quantidade_total) VALUES 
('Recebimento', 20), 
('Expedição', 30), 
('Esteira', 15), 
('Retorno', 10),
('Inventário', 5)
ON CONFLICT (nome) DO UPDATE SET quantidade_total = EXCLUDED.quantidade_total;

-- Inserindo Líderes
DO $$
DECLARE 
    area_rec_id UUID := (SELECT id FROM areas WHERE nome = 'Recebimento');
    area_exp_id UUID := (SELECT id FROM areas WHERE nome = 'Expedição');
BEGIN
    INSERT INTO lideres (nome, area_id) VALUES 
    ('Líder João Silva', area_rec_id),
    ('Líder Maria Oliveira', area_exp_id),
    ('Líder Carlos Souza', area_rec_id)
    ON CONFLICT (nome) DO NOTHING;

    -- Inicializar inventário dos líderes (0 por padrão)
    INSERT INTO lider_inventory (lider_id, quantidade)
    SELECT id, 0 FROM lideres
    ON CONFLICT (lider_id) DO NOTHING;
END $$;

-- 7. Garantir que as tabelas estão acessíveis (Desativar RLS para este projeto)
ALTER TABLE areas DISABLE ROW LEVEL SECURITY;
ALTER TABLE lideres DISABLE ROW LEVEL SECURITY;
ALTER TABLE lider_inventory DISABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE trocas_pendentes DISABLE ROW LEVEL SECURITY;
ALTER TABLE planejamento DISABLE ROW LEVEL SECURITY;
