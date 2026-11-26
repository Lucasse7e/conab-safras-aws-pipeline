-- Camada raw: tabela externa sobre o CSV. Substitua <SEU-BUCKET> pelo nome do seu bucket.
-- eh_agregado e is_previsao ficam como string: o CSV tem "True"/"False" e o parser de
-- boolean do LazySimpleSerDe espera minúsculas (viraria NULL em silêncio).
CREATE EXTERNAL TABLE IF NOT EXISTS agro_raw.conab_safras (
  cultura          string,
  tipo_safra       string,
  produto_original string,
  safra            string,
  ano_inicio       int,
  metrica          string,
  valor            double,
  unidade          string,
  eh_agregado      string,
  is_previsao      string
)
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://<SEU-BUCKET>/raw/conab_safras/'
TBLPROPERTIES ('skip.header.line.count'='1');
