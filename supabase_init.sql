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
    turno TEXT, -- T1, T2, T3
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Inventário por Líder (Posse Atual)
-- Agora associamos a quantidade à área em que o líder está atuando
CREATE TABLE IF NOT EXISTS lider_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lider_id UUID REFERENCES lideres(id) ON DELETE CASCADE,
    area_id UUID REFERENCES areas(id) ON DELETE CASCADE,
    quantidade INT DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT now(),
    UNIQUE(lider_id, area_id) -- Permite que o líder tenha PDAs em áreas diferentes simultaneamente
);

-- 4. Movimentações (Histórico de Saídas, Retornos e Trocas)
CREATE TABLE IF NOT EXISTS movimentacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lider_id UUID REFERENCES lideres(id) ON DELETE SET NULL,
    area_id UUID REFERENCES areas(id) ON DELETE SET NULL, -- Área onde a movimentação ocorreu
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
    area_origem_id UUID REFERENCES areas(id) ON DELETE SET NULL, -- Área de onde os PDAs estão saindo
    lider_destino_id UUID REFERENCES lideres(id) ON DELETE CASCADE,
    area_id UUID REFERENCES areas(id) ON DELETE SET NULL, -- Área onde o destino irá usar
    quantidade INT NOT NULL CHECK (quantidade > 0),
    status TEXT DEFAULT 'PENDENTE', -- 'PENDENTE', 'APROVADO', 'REJEITADO'
    created_at TIMESTAMPTZ DEFAULT now(),
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

-- Inserindo Áreas com quantidades totais
INSERT INTO areas (nome, quantidade_total) VALUES
('Recebimento FM', 50),
('Recebimento LH', 50),
('Esteira HUB 1', 30),
('Esteira HUB 2', 30),
('Esteira HUB 3', 30),
('Esteira SOC 1', 30),
('Esteira SOC 2', 30),
('Sorter', 40),
('Esteira Volumoso 1', 25),
('Esteira Volumoso 2', 25),
('Esteira Termoplastica', 20),
('Transição', 15),
('Expedição', 100)
ON CONFLICT (nome) DO UPDATE SET quantidade_total = EXCLUDED.quantidade_total;

-- Inserindo Líderes
    INSERT INTO lideres (nome, turno) VALUES
    ('Líder João Silva', 'T1'),
    ('Líder Maria Oliveira', 'T2'),
    ('Líder Carlos Souza', 'T1')
    ON CONFLICT (nome) DO NOTHING;
END $$;

-- 7. Garantir que as tabelas estão acessíveis (Desativar RLS para este projeto)
ALTER TABLE areas DISABLE ROW LEVEL SECURITY;
ALTER TABLE lideres DISABLE ROW LEVEL SECURITY;
ALTER TABLE lider_inventory DISABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE trocas_pendentes DISABLE ROW LEVEL SECURITY;
ALTER TABLE planejamento DISABLE ROW LEVEL SECURITY;
