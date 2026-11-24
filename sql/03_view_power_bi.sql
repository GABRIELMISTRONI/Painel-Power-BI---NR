-- Visao mensal de acompanhamento; agrega fatos ANTES de uni-los para impedir duplicacao de custos.
CREATE OR REPLACE VIEW v_painel_mensal AS

WITH datas AS (
    SELECT data_uso AS dia FROM horas_uso
    UNION ALL SELECT data_abastecimento FROM abastecimentos
    UNION ALL SELECT data_manutencao FROM manutencoes
), limites AS (
    SELECT date_trunc('month', MIN(dia))::date AS inicio,
           date_trunc('month', MAX(dia))::date AS fim
      FROM datas
), meses AS (
    SELECT generate_series(l.inicio, l.fim, interval '1 month')::date AS mes
      FROM limites l
     WHERE l.inicio IS NOT NULL
),
uso AS (
  SELECT id_maquina, date_trunc('month', data_uso)::date AS mes,
         SUM(horas_trabalhadas) AS horas
  FROM horas_uso GROUP BY 1,2
),
combustivel AS (
  SELECT id_maquina, date_trunc('month', data_abastecimento)::date AS mes,
         SUM(litros) AS litros, SUM(valor_total) AS custo_combustivel
  FROM abastecimentos GROUP BY 1,2
),
manutencao AS (
  SELECT id_maquina, date_trunc('month', data_manutencao)::date AS mes,
         SUM(custo) AS custo_manutencao, COUNT(*)::integer AS quantidade_manutencoes,
         SUM(custo) FILTER (WHERE tipo_manutencao = 'Preventiva') AS custo_preventiva,
         SUM(custo) FILTER (WHERE tipo_manutencao = 'Corretiva') AS custo_corretiva,
         COUNT(*) FILTER (WHERE tipo_manutencao = 'Preventiva')::integer AS quantidade_preventivas,
         COUNT(*) FILTER (WHERE tipo_manutencao = 'Corretiva')::integer AS quantidade_corretivas
  FROM manutencoes GROUP BY 1,2
)
SELECT to_char(mes.mes,'YYYY-MM') AS ano_mes, m.id_maquina, m.codigo,
       m.descricao AS maquina, m.categoria,
       COALESCE(u.horas,0)::numeric(14,2) AS horas_trabalhadas,
       COALESCE(c.litros,0)::numeric(14,2) AS litros_abastecidos,
       COALESCE(c.custo_combustivel,0)::numeric(14,2) AS custo_combustivel,
       COALESCE(mt.custo_manutencao,0)::numeric(14,2) AS custo_manutencao,
       (COALESCE(c.custo_combustivel,0)+COALESCE(mt.custo_manutencao,0))::numeric(14,2) AS custo_operacional_total,
       COALESCE(mt.quantidade_manutencoes,0) AS quantidade_manutencoes,
       COALESCE(mt.custo_preventiva,0)::numeric(14,2) AS custo_preventiva,
       COALESCE(mt.custo_corretiva,0)::numeric(14,2) AS custo_corretiva,
       COALESCE(mt.quantidade_preventivas,0) AS quantidade_preventivas,
       COALESCE(mt.quantidade_corretivas,0) AS quantidade_corretivas
FROM maquinas m
CROSS JOIN meses mes
LEFT JOIN uso u ON u.id_maquina=m.id_maquina AND u.mes=mes.mes
LEFT JOIN combustivel c ON c.id_maquina=m.id_maquina AND c.mes=mes.mes
LEFT JOIN manutencao mt ON mt.id_maquina=m.id_maquina AND mt.mes=mes.mes;
