--  RELATORIO DE SUGESTAO DE REABASTECIMENTO DE PRODUTOS


SELECT



    --Informacoes do cadastro de produto

    PRO.REFERENCIA AS "SKU",
    PRO.DESCRPROD AS "Descricao",
    GRU.DESCRGRUPOPROD AS "Familia",
    PRO.MARCA AS "Marca",
    PRO.AD_MACROGRUPO AS "Macro_Grupo",
    PRO.AD_ANOMODELO AS "Ano_de_lancamento",
    
    
    COALESCE(CEIL(SPPR.SALDO), 0) AS "Saldo_Principal",



-- curva

CASE
    WHEN PRO.PERMCOMPPROD = 'N' THEN 'Phase Out'
    WHEN BM.SKU IS NOT NULL THEN 'Big Mac'
    WHEN ABC.SKU IS NOT NULL THEN
        CASE
            WHEN ABC.Percentual_Acumulado <= 70 THEN 'A'
            WHEN ABC.Percentual_Acumulado <= 95 THEN 'B'
            ELSE 'C'
        END
    ELSE 'D'
END AS "Curva_Final",

-- dias de estoque

ROUND(
    CASE 
        WHEN (
            ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)), 2) 
        ) > 0
        THEN 
            (
                COALESCE(SP.SALDO, 0)
            ) / 
            (
                ROUND(
                    (
                        ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)), 2) 
                    ) / 90, 2
                )
            )
        ELSE 999
    END
, 0) AS "Dias_Estoque_Total",



-- minimo

CEIL(GREATEST(( 
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(PG1.QTD, 0) > CEIL((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(PG1.QTD, 0) < CEIL((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 10
            )
        , 0), 0
    )
), 0)) AS "minimo",

-- maximo

CEIL(GREATEST(( 
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(PG1.QTD, 0) > CEIL((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(PG1.QTD, 0) < CEIL((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 45
            )
        , 0), 0
    )
), 0)) AS "maximo",


-- fim da sugestao de compra total


-- Blocos de dados por canal de venda


    -- Bloco VENDAS PAGE

    CEIL(NVL(PG1.QTD, 0)) AS "Vendas_esse_mes_projetado",

    NVL(PG2.QTD, 0) AS "Vendas_mes_passado",
    
    NVL(PG3.QTD, 0) AS "Vendas_mes_retrasdado",

    ROUND((CEIL(NVL(PG1.QTD, 0)) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3, 2) AS "Media_90_dias",

    CASE
        WHEN NVL(PG1.QTD, 0) > ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 1.05, 2) THEN 'Aumento'
        WHEN NVL(PG1.QTD, 0) < ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 0.95, 2) THEN 'Queda'
        ELSE 'Permanencia'
    END AS "Tendencia",
    
    COALESCE(CEIL(SP.SALDO), 0) AS "Saldo",

CEIL(
    GREATEST(
        ROUND(
            (
                ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3, 2) *
                CASE
                    WHEN NVL(PG1.QTD, 0) > ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 1.05, 2) THEN 1.05
                    WHEN NVL(PG1.QTD, 0) < ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 0.95, 2) THEN 0.95
                    ELSE 1
                END
            ) / 30 * 20
        , 2) - COALESCE(CEIL(SP.SALDO), 0)
    , 0)
) AS "Sugestao"





--Fim dos blocos



-- FROM produtos

FROM TGFPRO PRO





-- JOINS

INNER JOIN TGFGRU GRU ON PRO.CODGRUPOPROD = GRU.CODGRUPOPROD

-- curva

-- JOIN da curva ABC por família
LEFT JOIN (
    SELECT 
        SKU,
        Familia,
        Soma_de_Quantidade,
        ROUND(
            SUM(Soma_de_Quantidade) OVER (
                PARTITION BY Familia 
                ORDER BY Soma_de_Quantidade DESC, SKU
            ) / NULLIF(SUM(Soma_de_Quantidade) OVER (PARTITION BY Familia), 0) * 100, 2
        ) AS Percentual_Acumulado
    FROM (
        SELECT 
            P.REFERENCIA AS SKU,
            G.DESCRGRUPOPROD AS Familia,
            FLOOR(SUM(I.QTDNEG)) AS Soma_de_Quantidade
        FROM TGFITE I
        JOIN TGFCAB C ON C.NUNOTA = I.NUNOTA
        JOIN TGFPRO P ON P.CODPROD = I.CODPROD
        JOIN TGFGRU G ON G.CODGRUPOPROD = P.CODGRUPOPROD
        WHERE
            C.TIPMOV = 'V'
            AND C.CODTIPOPER IN (3021, 3022, 4201, 4056, 4057, 4025, 4028, 4029, 4021, 1201)
            AND C.DTNEG BETWEEN TRUNC(SYSDATE - 366) AND TRUNC(SYSDATE - 1)
            AND C.STATUSNOTA = 'L'
        GROUP BY P.REFERENCIA, G.DESCRGRUPOPROD
    )
) ABC ON ABC.SKU = PRO.REFERENCIA

-- JOIN dos 17 maiores SKUs por média dos últimos 3 meses
LEFT JOIN (
    SELECT SKU FROM (
        SELECT 
            P.REFERENCIA AS SKU,
            CEIL((
                SUM(CASE WHEN C.DTNEG BETWEEN TRUNC(SYSDATE - 30) AND TRUNC(SYSDATE - 1) THEN I.QTDNEG ELSE 0 END) +
                SUM(CASE WHEN C.DTNEG BETWEEN TRUNC(SYSDATE - 60) AND TRUNC(SYSDATE - 31) THEN I.QTDNEG ELSE 0 END) +
                SUM(CASE WHEN C.DTNEG BETWEEN TRUNC(SYSDATE - 90) AND TRUNC(SYSDATE - 61) THEN I.QTDNEG ELSE 0 END)
            ) / 3) AS Media_3_Meses
        FROM TGFPRO P
        JOIN TGFITE I ON I.CODPROD = P.CODPROD
        JOIN TGFCAB C ON C.NUNOTA = I.NUNOTA
        WHERE
            P.REFERENCIA <> '0'
            AND SUBSTR(P.CODGRUPOPROD, 0, 2) NOT IN (11, 12, 13, 14)
            AND P.ATIVO = 'S'
            AND P.AD_MACROGRUPO LIKE '%FRONTAL%'
            AND C.TIPMOV = 'V'
            AND C.CODTIPOPER IN (3021, 3022, 4201, 4056, 4057, 4025, 4028, 4029, 4021, 1201)
            AND C.STATUSNOTA = 'L'
            AND C.DTNEG BETWEEN TO_DATE('01/07/2024', 'DD/MM/YYYY') AND TRUNC(SYSDATE - 1)
        GROUP BY P.REFERENCIA
        ORDER BY Media_3_Meses DESC
        FETCH FIRST 17 ROWS ONLY
    )
) BM ON BM.SKU = PRO.REFERENCIA


-- ESTOQUES

-- Saldo Principal (Empresa 8 - Local 101)
LEFT JOIN (
    SELECT CODPROD, SUM(ESTOQUE) AS SALDO
    FROM TGFEST
    WHERE CODEMP = 8 AND CODLOCAL = 101
    GROUP BY CODPROD
) SPPR ON SPPR.CODPROD = PRO.CODPROD

-- Saldo Page (Empresa 3 - Locais 201, 101)
LEFT JOIN (
    SELECT CODPROD, SUM(ESTOQUE) AS SALDO
    FROM TGFEST
    WHERE CODEMP = 9 AND CODLOCAL IN (901, 101)
    GROUP BY CODPROD
) SP ON SP.CODPROD = PRO.CODPROD




-- (JOINS PARA PG1, PG2, PG3, OR1, OR2, OR3, DG1, DG2, DG3, B2B1, B2B2, B2B3, FR1, FR2, FR3)

-- ----------- VENDAS PAGE
LEFT JOIN (
    SELECT 
        PRO.REFERENCIA, 
        ROUND(SUM(ITE.QTDNEG) / EXTRACT(DAY FROM SYSDATE - 1) * EXTRACT(DAY FROM LAST_DAY(SYSDATE)), 2) AS QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
      AND CAB.STATUSNOTA = 'L'
      AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201, 1951, 1954)
      AND CAB.CODPARC <> 16322
      AND CAB.DTNEG BETWEEN TRUNC(SYSDATE, 'MM') AND TRUNC(SYSDATE - 1)
      AND CUS.DESCRCENCUS = 'VENDAS ARARANGUÁ'
    GROUP BY PRO.REFERENCIA
) PG1 ON PG1.REFERENCIA = PRO.REFERENCIA


LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) AS QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
      AND CAB.STATUSNOTA = 'L'
      AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201, 1951, 1954)
      AND CAB.CODPARC <> 16322
      AND CAB.DTNEG BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1) AND LAST_DAY(ADD_MONTHS(SYSDATE, -1))
      AND CUS.DESCRCENCUS = 'VENDAS ARARANGUÁ'
    GROUP BY PRO.REFERENCIA
) PG2 ON PG2.REFERENCIA = PRO.REFERENCIA


LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) AS QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
      AND CAB.STATUSNOTA = 'L'
      AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201, 1951, 1954)
      AND CAB.CODPARC <> 16322
      AND CAB.DTNEG BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2) AND LAST_DAY(ADD_MONTHS(SYSDATE, -2))
      AND CUS.DESCRCENCUS = 'VENDAS ARARANGUÁ'
    GROUP BY PRO.REFERENCIA
) PG3 ON PG3.REFERENCIA = PRO.REFERENCIA


-- FILTROS 

WHERE
    PRO.REFERENCIA <> '0'
    AND SUBSTR(PRO.CODGRUPOPROD, 0, 2) NOT IN (11, 12, 13, 14)
    AND PRO.ATIVO = 'S'





-- ORDER BY 

ORDER BY PRO.CODPROD