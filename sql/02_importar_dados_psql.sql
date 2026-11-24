-- EXECUTAR via terminal psql a partir da pasta-raiz do projeto (sem alterar o diretorio)
-- Exemplo: psql -U postgres -d nr_bi -v ON_ERROR_STOP=1 -f sql/02_importar_dados_psql.sql
-- Este script usa metacomando \copy, por isso nao funciona no editor SQL comum do pgAdmin.
\set ON_ERROR_STOP on
BEGIN;
TRUNCATE TABLE horas_uso, abastecimentos, manutencoes, locacoes, maquinas, clientes CASCADE;
\copy maquinas (id_maquina,codigo,descricao,modelo,categoria,ano_fabricacao,status_cadastro) FROM 'dados/maquinas.csv' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
\copy clientes (id_cliente,nome_ficticio) FROM 'dados/clientes.csv' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
\copy locacoes (id_locacao,id_maquina,id_cliente,data_inicio,data_fim,situacao) FROM 'dados/locacoes.csv' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
\copy horas_uso (id_hora,id_maquina,id_locacao,data_uso,horas_trabalhadas) FROM 'dados/horas_uso.csv' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
\copy abastecimentos (id_abastecimento,id_maquina,data_abastecimento,litros,preco_por_litro,valor_total) FROM 'dados/abastecimentos.csv' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
\copy manutencoes (id_manutencao,id_maquina,data_manutencao,tipo_manutencao,descricao_servico,custo) FROM 'dados/manutencoes.csv' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
COMMIT;
