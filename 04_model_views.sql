-- Modelo dimensional em views. O Athena executa UMA instrução por vez: rode cada bloco separadamente.

-- dim_cultura (grupo_cultura é uma regra de negócio minha, não vem da CONAB)
CREATE OR REPLACE VIEW agro_curated.dim_cultura AS
SELECT DISTINCT
  cultura,
  CASE
    WHEN cultura IN ('SOJA','GIRASSOL','CANOLA','MAMONA','GERGELIM','AMENDOIM') THEN 'Oleaginosas'
    WHEN cultura IN ('ARROZ','MILHO','SORGO','TRIGO','AVEIA','CEVADA','CENTEIO','TRITICALE') THEN 'Cereais'
    WHEN cultura = 'FEIJÃO' THEN 'Leguminosas'
    WHEN cultura = 'ALGODÃO' THEN 'Fibras'
    ELSE 'Outros'
  END AS grupo_cultura
FROM agro_curated.conab_safras;

-- dim_safra
CREATE OR REPLACE VIEW agro_curated.dim_safra AS
SELECT DISTINCT
  ano_inicio,
  safra,
  ano_inicio + 1 AS ano_fim,
  (ano_inicio / 10) * 10 AS decada,
  is_previsao
FROM agro_curated.conab_safras;

-- fato_safra: granularidade = cultura + tipo de safra + safra. Sem subtotais (evita dupla contagem).
CREATE OR REPLACE VIEW agro_curated.fato_safra AS
SELECT
  cultura,
  tipo_safra,
  ano_inicio,
  CAST(MAX(CASE WHEN metrica = 'area'          THEN valor END) AS DECIMAL(18,3)) AS area_mil_ha,
  CAST(MAX(CASE WHEN metrica = 'produtividade' THEN valor END) AS DECIMAL(18,3)) AS produtividade_kg_ha,
  CAST(MAX(CASE WHEN metrica = 'producao'      THEN valor END) AS DECIMAL(18,3)) AS producao_mil_t
FROM agro_curated.conab_safras
WHERE NOT eh_agregado
GROUP BY cultura, tipo_safra, ano_inicio;
