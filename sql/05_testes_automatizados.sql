
-- Validacao do cenario ficticio (2026-01 a 2026-10).
-- Execucao: psql -U postgres -d nr_bi -v ON_ERROR_STOP=1 -f sql/05_testes_automatizados.sql
-- Nao insere, altera ou apaga dados.
DO $$
DECLARE
    n_maquinas INT; n_horas INT; n_abast INT; n_manut INT; n_meses INT;
    vl_oper NUMERIC(14,2); vl_comb NUMERIC(14,2); vl_manut NUMERIC(14,2);
    vl_prev NUMERIC(14,2); vl_corr NUMERIC(14,2);
    vl_horas NUMERIC(14,2); vl_litros NUMERIC(14,2);
BEGIN
    IF EXISTS (SELECT 1 FROM maquinas WHERE TRIM(modelo) = '' OR modelo IS NULL) THEN
       RAISE EXCEPTION 'Cadastro de maquina sem modelo';
    END IF;
    IF EXISTS (SELECT 1 FROM horas_uso GROUP BY id_maquina, data_uso HAVING COUNT(*) > 1) THEN
       RAISE EXCEPTION 'Mais de um registro diario por maquina';
    END IF;
    SELECT COUNT(*) INTO n_maquinas FROM maquinas;
    SELECT COUNT(*) INTO n_horas FROM horas_uso;
    SELECT COUNT(*) INTO n_abast FROM abastecimentos;
    SELECT COUNT(*) INTO n_manut FROM manutencoes;
    SELECT COUNT(*) INTO n_meses FROM v_painel_mensal;
    IF ROW(n_maquinas,n_horas,n_abast,n_manut,n_meses) IS DISTINCT FROM ROW(12,1997,546,96,120) THEN
       RAISE EXCEPTION 'Quantidade de registros divergente: %,%,%,%,%',n_maquinas,n_horas,n_abast,n_manut,n_meses;
    END IF;
    SELECT SUM(custo_operacional_total), SUM(custo_combustivel), SUM(custo_manutencao),
           SUM(custo_preventiva), SUM(custo_corretiva), SUM(horas_trabalhadas), SUM(litros_abastecidos)
      INTO vl_oper,vl_comb,vl_manut,vl_prev,vl_corr,vl_horas,vl_litros
      FROM v_painel_mensal;
    IF ROW(vl_oper,vl_comb,vl_manut,vl_prev,vl_corr,vl_horas,vl_litros)
      IS DISTINCT FROM ROW(1159527.93::numeric,947366.31::numeric,212161.62::numeric,
                           67823.51::numeric,144338.11::numeric,14670.76::numeric,150780.58::numeric) THEN
       RAISE EXCEPTION 'Valores agregados divergentes. Verificar CSV, view e filtros.';
    END IF;
    IF EXISTS (SELECT 1 FROM horas_uso h JOIN locacoes l USING (id_locacao)
               WHERE h.id_maquina<>l.id_maquina OR h.data_uso NOT BETWEEN l.data_inicio AND l.data_fim) THEN
       RAISE EXCEPTION 'Horas invalidas para a locacao.';
    END IF;
    IF EXISTS (SELECT 1 FROM abastecimentos
               WHERE ABS(valor_total-ROUND(litros*preco_por_litro,2))>0.01) THEN
       RAISE EXCEPTION 'Custo de abastecimento divergente.';
    END IF;
    RAISE NOTICE 'PASSOU: contagens, totais, horas/locacoes e custo abastecimento.';
END $$;
