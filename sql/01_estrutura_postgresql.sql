-- Projeto BI NR Locacoes - estrutura normalizada em PostgreSQL
-- TODOS os dados deste projeto sao ficticios.
-- Use um banco de dados DEDICADO; nao execute em producao.
BEGIN;

CREATE TABLE IF NOT EXISTS maquinas (
    id_maquina INTEGER PRIMARY KEY,
    codigo VARCHAR(15) NOT NULL UNIQUE,
    descricao VARCHAR(100) NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    categoria VARCHAR(70) NOT NULL,
    ano_fabricacao INTEGER CHECK (ano_fabricacao BETWEEN 1980 AND 2100),
    status_cadastro VARCHAR(15) NOT NULL CHECK (status_cadastro IN ('Ativa','Inativa'))
);
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INTEGER PRIMARY KEY,
    nome_ficticio VARCHAR(100) NOT NULL
);
CREATE TABLE IF NOT EXISTS locacoes (
    id_locacao INTEGER PRIMARY KEY,
    id_maquina INTEGER NOT NULL REFERENCES maquinas(id_maquina),
    id_cliente INTEGER NOT NULL REFERENCES clientes(id_cliente),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    situacao VARCHAR(20) NOT NULL CHECK (situacao IN ('Ativa', 'Encerrada', 'Cancelada')),
    CONSTRAINT ck_periodo_locacao CHECK (data_fim >= data_inicio),
    CONSTRAINT uq_locacao_maquina UNIQUE (id_locacao, id_maquina)
);
CREATE TABLE IF NOT EXISTS horas_uso (
    id_hora INTEGER PRIMARY KEY,
    id_maquina INTEGER NOT NULL REFERENCES maquinas(id_maquina),
    id_locacao INTEGER NOT NULL,
    data_uso DATE NOT NULL,
    horas_trabalhadas NUMERIC(8,2) NOT NULL CHECK (horas_trabalhadas > 0 AND horas_trabalhadas <= 24),
    CONSTRAINT uq_horas_maquina_dia UNIQUE (id_maquina, data_uso),
    CONSTRAINT fk_horas_locacao_maquina FOREIGN KEY (id_locacao, id_maquina) REFERENCES locacoes(id_locacao, id_maquina)
);
CREATE TABLE IF NOT EXISTS abastecimentos (
    id_abastecimento INTEGER PRIMARY KEY,
    id_maquina INTEGER NOT NULL REFERENCES maquinas(id_maquina),
    data_abastecimento DATE NOT NULL,
    litros NUMERIC(12,2) NOT NULL CHECK (litros > 0),
    preco_por_litro NUMERIC(8,3) NOT NULL CHECK (preco_por_litro > 0),
    valor_total NUMERIC(14,2) NOT NULL CHECK (valor_total >= 0),
    CONSTRAINT ck_valor_abastecimento CHECK (ABS(valor_total - ROUND(litros * preco_por_litro, 2)) <= 0.01)
);
CREATE TABLE IF NOT EXISTS manutencoes (
    id_manutencao INTEGER PRIMARY KEY,
    id_maquina INTEGER NOT NULL REFERENCES maquinas(id_maquina),
    data_manutencao DATE NOT NULL,
    tipo_manutencao VARCHAR(12) NOT NULL CHECK (tipo_manutencao IN ('Preventiva', 'Corretiva')),
    descricao_servico VARCHAR(150) NOT NULL,
    custo NUMERIC(14,2) NOT NULL CHECK (custo >= 0)
);

-- A FK composta confirma que hora e locacao pertencem a mesma maquina.
-- Este trigger completa a regra de negocio: data de uso dentro do contrato.
CREATE OR REPLACE FUNCTION fn_validar_data_hora_locacao()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE data_inicial DATE;
DECLARE data_final DATE;
BEGIN
    SELECT l.data_inicio, l.data_fim INTO data_inicial, data_final
      FROM locacoes l
     WHERE l.id_locacao = NEW.id_locacao AND l.id_maquina = NEW.id_maquina;
    IF NOT FOUND THEN
       RAISE EXCEPTION 'Locacao % nao pertence a maquina %', NEW.id_locacao, NEW.id_maquina;
    END IF;
    IF NEW.data_uso < data_inicial OR NEW.data_uso > data_final THEN
       RAISE EXCEPTION 'Data % fora do periodo da locacao % (% a %)',
           NEW.data_uso, NEW.id_locacao, data_inicial, data_final;
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_validar_data_hora_locacao ON horas_uso;
CREATE TRIGGER trg_validar_data_hora_locacao
  BEFORE INSERT OR UPDATE OF id_locacao, id_maquina, data_uso
  ON horas_uso FOR EACH ROW EXECUTE FUNCTION fn_validar_data_hora_locacao();


-- Impede que alteracoes posteriores no contrato deixem horas antigas fora do intervalo.
CREATE OR REPLACE FUNCTION fn_validar_alteracao_periodo_locacao()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
       SELECT 1 FROM horas_uso h
       WHERE h.id_locacao = NEW.id_locacao
         AND (h.data_uso < NEW.data_inicio OR h.data_uso > NEW.data_fim)
    ) THEN
       RAISE EXCEPTION 'Alteracao do periodo da locacao % invalidaria registros de horas', NEW.id_locacao;
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_validar_alteracao_periodo_locacao ON locacoes;
CREATE TRIGGER trg_validar_alteracao_periodo_locacao
  BEFORE UPDATE OF data_inicio, data_fim ON locacoes
  FOR EACH ROW EXECUTE FUNCTION fn_validar_alteracao_periodo_locacao();

CREATE INDEX IF NOT EXISTS idx_horas_locacao ON horas_uso(id_locacao, id_maquina);
CREATE INDEX IF NOT EXISTS idx_horas_maquina_data ON horas_uso(id_maquina, data_uso);
CREATE INDEX IF NOT EXISTS idx_abastecimento_maquina_data ON abastecimentos(id_maquina, data_abastecimento);
CREATE INDEX IF NOT EXISTS idx_manutencao_maquina_data ON manutencoes(id_maquina, data_manutencao);
CREATE INDEX IF NOT EXISTS idx_locacao_data ON locacoes(id_maquina, data_inicio, data_fim);
CREATE INDEX IF NOT EXISTS idx_locacao_maquina ON locacoes(id_maquina);
COMMIT;
