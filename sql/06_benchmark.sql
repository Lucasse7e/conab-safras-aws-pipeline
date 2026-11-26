-- Mesma pergunta nas duas camadas; compare "Dados verificados" no Athena. Uma por vez.
-- A) raw (CSV):            252,58 KB
SELECT cultura, SUM(valor) AS producao_mil_t
FROM agro_raw.conab_safras
WHERE metrica = 'producao' AND ano_inicio = 2024 AND eh_agregado = 'False'
GROUP BY cultura ORDER BY producao_mil_t DESC;

-- B) curated (Parquet):      6,16 KB
SELECT cultura, SUM(valor) AS producao_mil_t
FROM agro_curated.conab_safras
WHERE metrica = 'producao' AND ano_inicio = 2024 AND NOT eh_agregado
GROUP BY cultura ORDER BY producao_mil_t DESC;
