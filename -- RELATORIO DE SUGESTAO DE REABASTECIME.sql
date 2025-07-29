--  RELATORIO DE SUGESTAO DE REABASTECIMENTO DE PRODUTOS

-- trocar 28122004 por :P_DIAS

SELECT



    --Informacoes do cadastro de produto

    PRO.REFERENCIA AS "SKU",
    PRO.AD_DESCRFORN AS "Descricao_Fornecedor",
    GRU.DESCRGRUPOPROD AS "Familia",
    PRO.MARCA AS "Marca",
    PRO.AD_MACROGRUPO AS "Macro_Grupo",
    PRO.AD_ANOMODELO AS "Ano_de_lancamento",

    
    ULTIMA.QTD_COMPRA AS "Quantidade_Ultima_Compra",
    TRUNC(ULTIMA.DATA_COMPRA) - TO_DATE('30/12/1899','DD/MM/YYYY') AS "Data_Ultima_Compra",


    TRUNC(PRO.AD_DTCRIACAO) - TO_DATE('30/12/1899','DD/MM/YYYY') AS "Data_de_Criacao",
    PRO.AD_QUALIFORN AS "Qualidade_Fornecedor",

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
            ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)), 2) +
            ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)), 2) +
            ROUND((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)), 2) +
            ROUND((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)), 2) +
            ROUND((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)), 2)
        ) > 0
        THEN 
            (
                COALESCE(SPPR.SALDO, 0) + COALESCE(SP.SALDO, 0) + COALESCE(SO.SALDO, 0)
            ) / 
            (
                ROUND(
                    (
                        ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)), 2) +
                        ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)), 2) +
                        ROUND((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)), 2) +
                        ROUND((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)), 2) +
                        ROUND((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)), 2)
                    ) / 90, 2
                )
            )
        ELSE 999
    END
, 0) AS "Dias_Estoque_Total",






-- Classificação do Estoque baseada nos dias
CASE 
    WHEN ROUND(
        CASE 
            WHEN (
                ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
            ) > 0 THEN 
                (COALESCE(SPPR.SALDO, 0) + COALESCE(SP.SALDO, 0) + COALESCE(SO.SALDO, 0)) /
                ROUND((
                    ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                    ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                    ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                    ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                    ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
                ) / 90, 2)
            ELSE 999
        END, 0
    ) = 0 THEN '0 - OOS'

    WHEN ROUND(
        CASE 
            WHEN (
                ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
            ) > 0 THEN 
                (COALESCE(SPPR.SALDO, 0) + COALESCE(SP.SALDO, 0) + COALESCE(SO.SALDO, 0)) /
                ROUND((
                    ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                    ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                    ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                    ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                    ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
                ) / 90, 2)
            ELSE 999
        END, 0
    ) > 60 THEN '5 - Excesso'

    WHEN ROUND(
        CASE 
            WHEN (
                ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
            ) > 0 THEN 
                (COALESCE(SPPR.SALDO, 0) + COALESCE(SP.SALDO, 0) + COALESCE(SO.SALDO, 0)) /
                ROUND((
                    ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                    ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                    ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                    ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                    ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
                ) / 90, 2)
            ELSE 999
        END, 0
    ) > 28122004 THEN '4 - Over'

    WHEN ROUND(
        CASE 
            WHEN (
                ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
            ) > 0 THEN 
                (COALESCE(SPPR.SALDO, 0) + COALESCE(SP.SALDO, 0) + COALESCE(SO.SALDO, 0)) /
                ROUND((
                    ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                    ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                    ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                    ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                    ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
                ) / 90, 2)
            ELSE 999
        END, 0
    ) > 15 THEN '3 - Ponto de equilíbrio'

    WHEN ROUND(
        CASE 
            WHEN (
                ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
            ) > 0 THEN 
                (COALESCE(SPPR.SALDO, 0) + COALESCE(SP.SALDO, 0) + COALESCE(SO.SALDO, 0)) /
                ROUND((
                    ROUND(NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0), 2) +
                    ROUND(NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0), 2) +
                    ROUND(NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0), 2) +
                    ROUND(NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0), 2) +
                    ROUND(NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0), 2)
                ) / 90, 2)
            ELSE 999
        END, 0
    ) > 7 THEN '2 - Short'

    ELSE '1 - Crítico'
END AS "Classificacao_Estoque",



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
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(OR1.QTD, 0) > CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(OR1.QTD, 0) < CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 10
            )
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(DG1.QTD, 0) > CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(DG1.QTD, 0) < CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 10
            )
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(B2B1.QTD, 0) > CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(B2B1.QTD, 0) < CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 10
            )
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(FR1.QTD, 0) > CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(FR1.QTD, 0) < CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 0.95) THEN 0.95
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
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(OR1.QTD, 0) > CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(OR1.QTD, 0) < CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 45
            )
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(DG1.QTD, 0) > CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(DG1.QTD, 0) < CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 45
            )
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(B2B1.QTD, 0) > CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(B2B1.QTD, 0) < CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 45
            )
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(FR1.QTD, 0) > CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(FR1.QTD, 0) < CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 45
            )
        , 0), 0
    )
), 0)) AS "maximo",





-- Calculos por canal de venda

    -- Calculo da sugestao de compra total

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
                ) / 30 * 28122004
            ) - COALESCE(CEIL(SP.SALDO), 0)
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(OR1.QTD, 0) > CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(OR1.QTD, 0) < CEIL((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 28122004
            ) - COALESCE(CEIL(SO.SALDO), 0)
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(DG1.QTD, 0) > CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(DG1.QTD, 0) < CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 28122004
            ) - COALESCE(CEIL(SPPR.SALDO), 0)
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(B2B1.QTD, 0) > CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(B2B1.QTD, 0) < CEIL((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 28122004
            )
        , 0), 0
    )
    +
    COALESCE(
        GREATEST(
            CEIL(
                (
                    CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3) *
                    CASE
                        WHEN NVL(FR1.QTD, 0) > CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 1.05) THEN 1.05
                        WHEN NVL(FR1.QTD, 0) < CEIL((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 0.95) THEN 0.95
                        ELSE 1
                    END
                ) / 30 * 28122004
            )
        , 0), 0
    )
    - COALESCE(PEND.QTD_PENDENTE, 0)
    - GREATEST(
        COALESCE(CEIL(SPPR.SALDO), 0)
        - CEIL(
            (
                CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3) *
                CASE
                    WHEN NVL(DG1.QTD, 0) > CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 1.05) THEN 1.05
                    WHEN NVL(DG1.QTD, 0) < CEIL((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 0.95) THEN 0.95
                    ELSE 1
                END
            ) / 30 * 28122004
        )
    , 0)
), 0)) AS "Sugestao_Compra_Total",


-- fim da sugestao de compra total

    COALESCE(PEND.QTD_PENDENTE, 0) AS "Comprado",

-- Blocos de dados por canal de venda


-- Bloco VENDAS Principal

    NVL(DG1.QTD, 0) AS "Vendas_Principal_0_30",

    NVL(DG2.QTD, 0) AS "Vendas_Principal_31_60",

    NVL(DG3.QTD, 0) AS "Vendas_Principal_61_90",

    ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3, 2) AS "Media_Principal_90_dias",

    CASE
        WHEN NVL(DG1.QTD, 0) > ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 1.05, 2) THEN 'Aumento'
        WHEN NVL(DG1.QTD, 0) < ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 0.95, 2) THEN 'Queda'
        ELSE 'Permanencia'
    END AS "Tendencia_Principal",
    
    COALESCE(CEIL(SPPR.SALDO), 0) AS "Saldo_Principal",

    GREATEST(
        COALESCE(CEIL(SPPR.SALDO), 0)
        - ROUND(
            (
                ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3, 2) *
                CASE
                    WHEN NVL(DG1.QTD, 0) > ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 1.05, 2) THEN 1.05
                    WHEN NVL(DG1.QTD, 0) < ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 0.95, 2) THEN 0.95
                    ELSE 1
                END
            ) / 30 * 28122004
        , 2)
    , 0) AS "Excesso",

GREATEST(
    ROUND(
        (
            ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3, 2) *
            CASE
                WHEN NVL(DG1.QTD, 0) > ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 1.05, 2) THEN 1.05
                WHEN NVL(DG1.QTD, 0) < ROUND((NVL(DG1.QTD, 0) + NVL(DG2.QTD, 0) + NVL(DG3.QTD, 0)) / 3 * 0.95, 2) THEN 0.95
                ELSE 1
            END
        ) / 30 * 28122004
    , 2) - COALESCE(CEIL(SPPR.SALDO), 0)
, 0) AS "Sugestao_Principal",





    -- Bloco VENDAS PAGE

    NVL(PG1.QTD, 0) AS "Vendas_Page_0_30",

    NVL(PG2.QTD, 0) AS "Vendas_Page_31_60",
    
    NVL(PG3.QTD, 0) AS "Vendas_Page_61_90",

    ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3, 2) AS "Media_Page_90_dias",

    CASE
        WHEN NVL(PG1.QTD, 0) > ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 1.05, 2) THEN 'Aumento'
        WHEN NVL(PG1.QTD, 0) < ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 0.95, 2) THEN 'Queda'
        ELSE 'Permanencia'
    END AS "Tendencia_Page",
    
    COALESCE(CEIL(SP.SALDO), 0) AS "Saldo_Page",

GREATEST(
    ROUND(
        (
            ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3, 2) *
            CASE
                WHEN NVL(PG1.QTD, 0) > ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 1.05, 2) THEN 1.05
                WHEN NVL(PG1.QTD, 0) < ROUND((NVL(PG1.QTD, 0) + NVL(PG2.QTD, 0) + NVL(PG3.QTD, 0)) / 3 * 0.95, 2) THEN 0.95
                ELSE 1
            END
        ) / 30 * 28122004
    , 2) - COALESCE(CEIL(SP.SALDO), 0)
, 0) AS "Sugestao_Page",





    --Bloco VENDAS ORIENTAL

    NVL(OR1.QTD, 0) AS "Vendas_Oriental_0_30",

    NVL(OR2.QTD, 0) AS "Vendas_Oriental_31_60",

    NVL(OR3.QTD, 0) AS "Vendas_Oriental_61_90",

    ROUND((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3, 2) AS "Media_Oriente_90_dias",

    CASE
        WHEN NVL(OR1.QTD, 0) > ROUND((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 1.05, 2) THEN 'Aumento'
        WHEN NVL(OR1.QTD, 0) < ROUND((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 0.95, 2) THEN 'Queda'
        ELSE 'Permanencia'
    END AS "Tendencia_Oriente",
    
    COALESCE(CEIL(SO.SALDO), 0) AS "Saldo_Oriental",

GREATEST(
    ROUND(
        (
            ROUND((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3, 2) *
            CASE
                WHEN NVL(OR1.QTD, 0) > ROUND((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 1.05, 2) THEN 1.05
                WHEN NVL(OR1.QTD, 0) < ROUND((NVL(OR1.QTD, 0) + NVL(OR2.QTD, 0) + NVL(OR3.QTD, 0)) / 3 * 0.95, 2) THEN 0.95
                ELSE 1
            END
        ) / 30 * 28122004
    , 2) - COALESCE(CEIL(SO.SALDO), 0)
, 0) AS "Sugestao_Oriental",





    
    -- VENDAS B2B
    
    NVL(B2B1.QTD, 0) AS "Vendas_B2B_0_30",

    NVL(B2B2.QTD, 0) AS "Vendas_B2B_31_60",

    NVL(B2B3.QTD, 0) AS "Vendas_B2B_61_90",

    ROUND((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3, 2) AS "Media_B2B_90_dias",

    CASE
        WHEN NVL(B2B1.QTD, 0) > ROUND((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 1.05, 2) THEN 'Aumento'
        WHEN NVL(B2B1.QTD, 0) < ROUND((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 0.95, 2) THEN 'Queda'
        ELSE 'Permanencia'
    END AS "Sugestao_B2B",

GREATEST(
    ROUND(
        (
            ROUND((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3, 2) *
            CASE
                WHEN NVL(B2B1.QTD, 0) > ROUND((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 1.05, 2) THEN 1.05
                WHEN NVL(B2B1.QTD, 0) < ROUND((NVL(B2B1.QTD, 0) + NVL(B2B2.QTD, 0) + NVL(B2B3.QTD, 0)) / 3 * 0.95, 2) THEN 0.95
                ELSE 1
            END
        ) / 30 * 28122004
    , 2)
, 0) AS "Sugestao_B2B",





    -- VENDAS FRANQUEADO

    NVL(FR1.QTD, 0) AS "Vendas_Franqueado_0_30",

    NVL(FR2.QTD, 0) AS "Vendas_Franqueado_31_60",

    NVL(FR3.QTD, 0) AS "Vendas_Franqueado_61_90",

    ROUND((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3, 2) AS "Media_Franqueado_90_dias",

    CASE
        WHEN NVL(FR1.QTD, 0) > ROUND((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 1.05, 2) THEN 'Aumento'
        WHEN NVL(FR1.QTD, 0) < ROUND((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 0.95, 2) THEN 'Queda'
        ELSE 'Permanencia'
    END AS "Tendencia_Franqueado",

GREATEST(
    ROUND(
        (
            ROUND((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3, 2) *
            CASE
                WHEN NVL(FR1.QTD, 0) > ROUND((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 1.05, 2) THEN 1.05
                WHEN NVL(FR1.QTD, 0) < ROUND((NVL(FR1.QTD, 0) + NVL(FR2.QTD, 0) + NVL(FR3.QTD, 0)) / 3 * 0.95, 2) THEN 0.95
                ELSE 1
            END
        ) / 30 * 28122004
    , 2)
, 0) AS "Sugestao_Franqueado"

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




-- informacoes da ultima compra
LEFT JOIN (
    SELECT 
        ITE.CODPROD,
        MAX(CAB.DTNEG) AS DATA_COMPRA,
        MAX(ITE.QTDNEG) KEEP (DENSE_RANK FIRST ORDER BY CAB.DTNEG DESC) AS QTD_COMPRA
    FROM TGFITE ITE
    INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
    WHERE CAB.CODTIPOPER = 1301
      AND CAB.STATUSNOTA IN ('L', 'A')
      AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    GROUP BY ITE.CODPROD
) ULTIMA ON ULTIMA.CODPROD = PRO.CODPROD

-- COMPRADOS

LEFT JOIN (
    SELECT ITE.CODPROD, SUM(ITE.QTDNEG - ITE.QTDENTREGUE) AS QTD_PENDENTE
    FROM TGFITE ITE
    INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
    WHERE CAB.CODTIPOPER = 1301
      AND CAB.STATUSNOTA IN ('L', 'A')
      AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
      AND ITE.QTDENTREGUE = 0
    GROUP BY ITE.CODPROD
) PEND ON PEND.CODPROD = PRO.CODPROD

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
    WHERE CODEMP = 3 AND CODLOCAL IN (201, 101)
    GROUP BY CODPROD
) SP ON SP.CODPROD = PRO.CODPROD

-- Saldo Oriental (Empresa 4 - Locais 301, 101)
LEFT JOIN (
    SELECT CODPROD, SUM(ESTOQUE) AS SALDO
    FROM TGFEST
    WHERE CODEMP = 4 AND CODLOCAL IN (301, 101)
    GROUP BY CODPROD
) SO ON SO.CODPROD = PRO.CODPROD



-- (JOINS PARA PG1, PG2, PG3, OR1, OR2, OR3, DG1, DG2, DG3, B2B1, B2B2, B2B3, FR1, FR2, FR3)

-- ----------- VENDAS PAGE
LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
    AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 30 AND SYSDATE
    AND CUS.DESCRCENCUS = 'VENDAS LOJA PAGE'    GROUP BY PRO.REFERENCIA
) PG1 ON PG1.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
    AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 60 AND SYSDATE - 31
    AND CUS.DESCRCENCUS = 'VENDAS LOJA PAGE'    GROUP BY PRO.REFERENCIA
) PG2 ON PG2.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
    AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 90 AND SYSDATE - 61
    AND CUS.DESCRCENCUS = 'VENDAS LOJA PAGE'    GROUP BY PRO.REFERENCIA
) PG3 ON PG3.REFERENCIA = PRO.REFERENCIA

-- ----------- VENDAS ORIENTAL
LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
    AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 30 AND SYSDATE
    AND CUS.DESCRCENCUS = 'VENDAS LOJA ORIENTE'    GROUP BY PRO.REFERENCIA
) OR1 ON OR1.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
    AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 60 AND SYSDATE - 31
    AND CUS.DESCRCENCUS = 'VENDAS LOJA ORIENTE'    GROUP BY PRO.REFERENCIA
) OR2 ON OR2.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V'
    AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 90 AND SYSDATE - 61
    AND CUS.DESCRCENCUS = 'VENDAS LOJA ORIENTE'    GROUP BY PRO.REFERENCIA
) OR3 ON OR3.REFERENCIA = PRO.REFERENCIA

-- ----------- VENDAS principal
LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 30 AND SYSDATE
    AND CUS.DESCRCENCUS IN ('VENDAS ONLINE', 'VENDAS E-COMMERCE', 'VENDAS MERCADO LIVRE', 'VENDAS SHOPEE')
    GROUP BY PRO.REFERENCIA
) DG1 ON DG1.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 60 AND SYSDATE - 31
    AND CUS.DESCRCENCUS IN ('VENDAS ONLINE', 'VENDAS E-COMMERCE', 'VENDAS MERCADO LIVRE', 'VENDAS SHOPEE')
    GROUP BY PRO.REFERENCIA
) DG2 ON DG2.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    JOIN TSICUS CUS ON CAB.CODCENCUS = CUS.CODCENCUS
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC <> 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 90 AND SYSDATE - 61
    AND CUS.DESCRCENCUS IN ('VENDAS ONLINE', 'VENDAS E-COMMERCE', 'VENDAS MERCADO LIVRE', 'VENDAS SHOPEE')
    GROUP BY PRO.REFERENCIA
) DG3 ON DG3.REFERENCIA = PRO.REFERENCIA


-- ----------- B2B
LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC = 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 30 AND SYSDATE
    GROUP BY PRO.REFERENCIA
) B2B1 ON B2B1.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC = 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 60 AND SYSDATE - 31
    GROUP BY PRO.REFERENCIA
) B2B2 ON B2B2.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201)
    AND CAB.CODPARC = 16322
    AND CAB.DTNEG BETWEEN SYSDATE - 90 AND SYSDATE - 61
    GROUP BY PRO.REFERENCIA
) B2B3 ON B2B3.REFERENCIA = PRO.REFERENCIA

-- ----------- FRANQUEADOS
LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (1952, 1958, 1961)
    AND CAB.DTNEG BETWEEN SYSDATE - 30 AND SYSDATE
    GROUP BY PRO.REFERENCIA
) FR1 ON FR1.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (1952, 1958, 1961)
    AND CAB.DTNEG BETWEEN SYSDATE - 60 AND SYSDATE - 31
    GROUP BY PRO.REFERENCIA
) FR2 ON FR2.REFERENCIA = PRO.REFERENCIA

LEFT JOIN (
    SELECT PRO.REFERENCIA, SUM(ITE.QTDNEG) QTD
    FROM TGFITE ITE
    JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    WHERE CAB.TIPMOV = 'V' AND CAB.STATUSNOTA = 'L'
    AND CAB.CODTIPOPER IN (1952, 1958, 1961)
    AND CAB.DTNEG BETWEEN SYSDATE - 90 AND SYSDATE - 61
    GROUP BY PRO.REFERENCIA
) FR3 ON FR3.REFERENCIA = PRO.REFERENCIA





-- FILTROS 

WHERE
    PRO.REFERENCIA <> '0'
    AND SUBSTR(PRO.CODGRUPOPROD, 0, 2) NOT IN (11, 12, 13, 14)
    AND PRO.ATIVO = 'S'





-- ORDER BY 

ORDER BY PRO.CODPROD