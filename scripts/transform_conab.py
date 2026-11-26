"""Transforma a série histórica de safras da CONAB (XLS, formato largo) em CSV longo.

Uso:
    python scripts/transform_conab.py BrasilProdutoSerieHist.xls data/conab_safras_graos_longo.csv

Decisões (ver README):
  - cabeçalho da safra 2007/08 vem corrompido pelo Excel (250,875) -> corrigido, falha se surgir outro inesperado
  - linha BRASIL e rodapés saem da tabela; BRASIL é usada só para validação
  - 0 e vazio viram "sem dado" (a cultura não era acompanhada naquela safra)
  - subtotais (MILHO TOTAL etc.) ficam marcados em eh_agregado
  - 2026/27 é previsão -> is_previsao
"""
import re
import sys
import pandas as pd

METRICAS = {"Área": ("area", "mil_hectares"),
            "Produtividade": ("produtividade", "kg_por_hectare"),
            "Produção": ("producao", "mil_toneladas")}


def ler_aba(xls, aba, metrica, unidade):
    d = xls.parse(aba, header=None)
    cabecalho = list(d.iloc[5, 1:])
    safras = []
    for i, h in enumerate(cabecalho):
        h = str(h).strip()
        if re.fullmatch(r"\d{4}/\d{2}", h):
            safras.append(h)
        elif i == 31 and re.fullmatch(r"250[.,]875|250[.,]9", h):
            safras.append("2007/08")  # Excel converteu "2007/08" em número
        elif h.startswith("2026/27"):
            safras.append("2026/27")
        else:
            raise SystemExit(f"Cabeçalho inesperado na coluna {i} da aba {aba}: {h!r}")
    assert len(safras) == 51 and len(set(safras)) == 51

    linhas, brasil = [], None
    for _, r in d.iloc[6:, :].iterrows():
        produto = str(r[0]).strip()
        if produto.startswith(("Legenda", "Fonte")) or produto == "nan":
            continue
        valores = pd.to_numeric(r[1:52].values, errors="coerce")
        if produto == "BRASIL":
            brasil = pd.Series(valores, index=safras)
            continue
        for safra, v in zip(safras, valores):
            linhas.append((produto, metrica, unidade, safra, v))
    return linhas, brasil


def separar_produto(p):
    base = p.replace(" - CAROÇO", "")
    m = re.match(r"(.+?) (TOTAL|1ª SAFRA|2ª SAFRA|3ª SAFRA)$", base)
    return (m.group(1), m.group(2)) if m else (base, "ÚNICA")


def main(origem, destino):
    xls = pd.ExcelFile(origem)
    todas, brasil = [], {}
    for aba, (metrica, unidade) in METRICAS.items():
        l, b = ler_aba(xls, aba, metrica, unidade)
        todas += l
        brasil[metrica] = b
    df = pd.DataFrame(todas, columns=["produto_original", "metrica", "unidade", "safra", "valor"])
    df["valor"] = df["valor"].where(df["valor"] > 0)          # 0 / vazio -> sem dado
    df[["cultura", "tipo_safra"]] = df["produto_original"].apply(lambda p: pd.Series(separar_produto(p)))
    df["eh_agregado"] = df["tipo_safra"] == "TOTAL"
    df["ano_inicio"] = df["safra"].str[:4].astype(int)
    df["is_previsao"] = df["safra"] == "2026/27"
    df = df.dropna(subset=["valor"])
    cols = ["cultura", "tipo_safra", "produto_original", "safra", "ano_inicio", "metrica",
            "valor", "unidade", "eh_agregado", "is_previsao"]
    out = df[cols].sort_values(["metrica", "cultura", "tipo_safra", "ano_inicio"])
    out["valor"] = out["valor"].round(3)
    out.to_csv(destino, index=False, encoding="utf-8")

    print(f"{len(out)} linhas, {out.cultura.nunique()} culturas, {out.safra.nunique()} safras")
    base = df[df.tipo_safra.isin(["TOTAL", "ÚNICA"])]
    for m in ("area", "producao"):
        soma = base[base.metrica == m].groupby("safra").valor.sum()
        dif = (soma - brasil[m].reindex(soma.index)).abs()
        print(f"[validação] {m}: maior diferença para a linha BRASIL = {dif.max():.1f} (safra {dif.idxmax()})")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    main(sys.argv[1], sys.argv[2])
