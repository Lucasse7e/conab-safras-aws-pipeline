-- Uma consulta por vez. Valores esperados nos comentários.
SELECT COUNT(*) FROM agro_raw.conab_safras;                          -- 3147
SELECT metrica, COUNT(*) FROM agro_raw.conab_safras GROUP BY metrica; -- 1049 cada
SELECT COUNT(*) FROM agro_curated.fato_safra;                        -- 896
SELECT SUM(producao_mil_t) FROM agro_curated.fato_safra WHERE ano_inicio = 2024;  -- 352266.320 (linha BRASIL da CONAB: 352266.0)
