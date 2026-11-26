-- Camada curated: Parquet + Snappy, particionado por métrica, com booleans de verdade.
-- A coluna de partição precisa ser a última do SELECT.
-- external_location deve estar vazio/inexistente; se um CTAS falhar, apague a pasta antes de repetir.
CREATE TABLE agro_curated.conab_safras
WITH (
  format = 'PARQUET',
  parquet_compression = 'SNAPPY',
  external_location = 's3://<SEU-BUCKET>/curated/conab_safras/',
  partitioned_by = ARRAY['metrica']
) AS
SELECT
  cultura,
  tipo_safra,
  produto_original,
  safra,
  ano_inicio,
  valor,
  unidade,
  (lower(eh_agregado) = 'true') AS eh_agregado,
  (lower(is_previsao) = 'true') AS is_previsao,
  metrica
FROM agro_raw.conab_safras;
