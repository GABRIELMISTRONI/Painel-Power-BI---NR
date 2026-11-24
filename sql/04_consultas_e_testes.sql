-- INDICADORES GERAIS - qualquer periodo pode ser filtrado por WHERE ano_mes BETWEEN '2026-03' AND '2026-06'
SELECT ROUND(SUM(custo_operacional_total), 2) AS custo_operacional_total,
       ROUND(SUM(custo_operacional_total)/NULLIF(SUM(horas_trabalhadas),0),2) AS custo_por_hora,
       ROUND(SUM(litros_abastecidos)/NULLIF(SUM(horas_trabalhadas),0),2) AS litros_por_hora,
       ROUND(SUM(custo_manutencao),2) AS custo_manutencao
FROM v_painel_mensal;

-- CUSTO DE MANUTENCAO POR MAQUINA
SELECT codigo, maquina, SUM(custo_manutencao) AS custo_manutencao
FROM v_painel_mensal
GROUP BY codigo, maquina ORDER BY custo_manutencao DESC;

-- EVOLUCAO MENSAL DOS CUSTOS
SELECT ano_mes, SUM(custo_combustivel) AS combustivel,
       SUM(custo_manutencao) AS manutencao,
       SUM(custo_operacional_total) AS custo_total
FROM v_painel_mensal GROUP BY ano_mes ORDER BY ano_mes;

-- TESTES DE INTEGRIDADE
SELECT 'horas_sem_locacao' AS teste, COUNT(*) AS ocorrencias
FROM horas_uso h LEFT JOIN locacoes l ON l.id_locacao=h.id_locacao
WHERE l.id_locacao IS NULL
UNION ALL
SELECT 'horas_fora_periodo_locacao', COUNT(*)
FROM horas_uso h JOIN locacoes l ON l.id_locacao=h.id_locacao
WHERE h.data_uso NOT BETWEEN l.data_inicio AND l.data_fim OR h.id_maquina<>l.id_maquina
UNION ALL
SELECT 'combustivel_valor_inconsistente', COUNT(*)
FROM abastecimentos WHERE ABS(valor_total-ROUND(litros*preco_por_litro,2))>0.01;

-- Comparar com dados/metadados_validacao.json
