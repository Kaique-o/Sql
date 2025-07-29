WITH ESTOQUE_AGRUPADO AS (
    SELECT 
        EST.CODPROD,
        EST.CODLOCAL,
        SUM(EST.ESTOQUE) AS TOTAL_ESTOQUE
    FROM TGFEST EST
    WHERE (EST.CODLOCAL = 101 AND EST.CODEMP = 8)
       OR (EST.CODLOCAL = 201 AND EST.CODEMP = 3)
       OR (EST.CODLOCAL = 301 AND EST.CODEMP = 4)
       OR (EST.CODLOCAL = 401 AND EST.CODEMP = 2)
    GROUP BY EST.CODPROD, EST.CODLOCAL, EST.CODEMP
), 

VENDAS_MENSAL AS (
   SELECT
    ITE.CODPROD,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 1 THEN ITE.QTDNEG ELSE 0 END)) AS Janeiro,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 2 THEN ITE.QTDNEG ELSE 0 END)) AS Fevereiro,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 3 THEN ITE.QTDNEG ELSE 0 END)) AS Marco,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 4 THEN ITE.QTDNEG ELSE 0 END)) AS Abril,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 5 THEN ITE.QTDNEG ELSE 0 END)) AS Maio,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 6 THEN ITE.QTDNEG ELSE 0 END)) AS Junho, -- Correção da vírgula errada
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 7 THEN ITE.QTDNEG ELSE 0 END)) AS Julho,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 8 THEN ITE.QTDNEG ELSE 0 END)) AS Agosto,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 9 THEN ITE.QTDNEG ELSE 0 END)) AS Setembro,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 10 THEN ITE.QTDNEG ELSE 0 END)) AS Outubro,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 11 THEN ITE.QTDNEG ELSE 0 END)) AS Novembro,
    TRUNC(SUM(CASE WHEN EXTRACT(MONTH FROM CAB.DTNEG) = 12 THEN ITE.QTDNEG ELSE 0 END)) AS Dezembro,
    TRUNC(SUM(CASE WHEN CAB.DTNEG >= TRUNC(SYSDATE) - 30 THEN ITE.QTDNEG ELSE 0 END)) AS Vendas_Ultimos_30_Dias,
    TRUNC(SUM(CASE WHEN CAB.DTNEG >= TRUNC(SYSDATE) - 60 AND CAB.DTNEG < TRUNC(SYSDATE) - 30 THEN ITE.QTDNEG ELSE 0 END)) AS Vendas_30_Dias_Anteriores,
    TRUNC(SUM(CASE WHEN CAB.DTNEG >= TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM') AND CAB.DTNEG < TRUNC(SYSDATE, 'MM') THEN ITE.QTDNEG ELSE 0 END)) AS Mes_Atual, -- Correção da ausência de "ITE."
    TRUNC(SUM(CASE WHEN CAB.DTNEG >= TRUNC(ADD_MONTHS(SYSDATE, -2), 'MM') AND CAB.DTNEG < TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM') THEN ITE.QTDNEG ELSE 0 END)) AS Mes_Anterior_1,
    TRUNC(SUM(CASE WHEN CAB.DTNEG >= TRUNC(ADD_MONTHS(SYSDATE, -3), 'MM') AND CAB.DTNEG < TRUNC(ADD_MONTHS(SYSDATE, -2), 'MM') THEN ITE.QTDNEG ELSE 0 END)) AS Mes_Anterior_2
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE ITE.QTDNEG > 0 -- Considera apenas vendas (quantidade negociada positiva)
  AND CAB.DTNEG >= ADD_MONTHS(TRUNC(SYSDATE), -12) -- Últimos 12 meses
  AND CAB.CODTIPOPER IN (3021, 3022, 4021, 4201, 4056, 4057, 4025, 4028, 4029, 1201, 1958, 1952, 1961)
  AND CAB.STATUSNOTA = 'L'
  --AND CAB.CODVEND = 25
  AND CAB.TIPMOV = 'V'
 AND (
      :P_LOJA IS NULL OR :P_LOJA = '' OR ITE.CODLOCALORIG = :P_LOJA)
GROUP BY ITE.CODPROD
),
CALCULADO_ESTOQUE AS (
    SELECT
        PRO.CODPROD,
        CASE 
            WHEN :P_ESTOQUE = '101' THEN COALESCE(EST101.TOTAL_ESTOQUE, 0)
            WHEN :P_ESTOQUE = '201' THEN COALESCE(EST201.TOTAL_ESTOQUE, 0)
            WHEN :P_ESTOQUE = '301' THEN COALESCE(EST301.TOTAL_ESTOQUE, 0)
            WHEN :P_ESTOQUE = '401' THEN COALESCE(EST401.TOTAL_ESTOQUE, 0)
            WHEN :P_ESTOQUE IS NULL OR :P_ESTOQUE = '' THEN COALESCE(
                (COALESCE(EST101.TOTAL_ESTOQUE, 0) + 
                 COALESCE(EST201.TOTAL_ESTOQUE, 0) + 
                 COALESCE(EST301.TOTAL_ESTOQUE, 0) + 
                 COALESCE(EST401.TOTAL_ESTOQUE, 0)), 0)
            ELSE 0
        END AS ESTOQUE
    FROM TGFPRO PRO
    LEFT JOIN ESTOQUE_AGRUPADO EST101 ON PRO.CODPROD = EST101.CODPROD AND EST101.CODLOCAL = 101
    LEFT JOIN ESTOQUE_AGRUPADO EST201 ON PRO.CODPROD = EST201.CODPROD AND EST201.CODLOCAL = 201
    LEFT JOIN ESTOQUE_AGRUPADO EST301 ON PRO.CODPROD = EST301.CODPROD AND EST301.CODLOCAL = 301
    LEFT JOIN ESTOQUE_AGRUPADO EST401 ON PRO.CODPROD = EST401.CODPROD AND EST401.CODLOCAL = 401
),

ESTOQUE_TRANSICAO AS (
    SELECT 
        ESTRANS.CODPROD,
        ESTRANS.CODLOCAL,
        ESTRANS.CODEMP,
        SUM(ESTRANS.ESTOQUE) AS ESTOQUE_TRANS
    FROM TGFEST ESTRANS
    WHERE (ESTRANS.CODLOCAL = 101 AND ESTRANS.CODEMP = 2)
       OR (ESTRANS.CODLOCAL = 101 AND ESTRANS.CODEMP = 3)
       OR (ESTRANS.CODLOCAL = 101 AND ESTRANS.CODEMP = 4)
    GROUP BY ESTRANS.CODPROD, ESTRANS.CODLOCAL, ESTRANS.CODEMP
),

CALC_ESTOQUE_TRANS AS (
    SELECT
        PRO.CODPROD,
        CASE 
            WHEN :P_TRANS = '101' AND :P_EMPRESA = 2 THEN COALESCE(T121.ESTOQUE_TRANS, 0)
            WHEN :P_TRANS = '101' AND :P_EMPRESA = 3 THEN COALESCE(T131.ESTOQUE_TRANS, 0)
            WHEN :P_TRANS = '101' AND :P_EMPRESA = 4 THEN COALESCE(T141.ESTOQUE_TRANS, 0)
            WHEN :P_TRANS IS NULL OR :P_TRANS = '' THEN COALESCE(
                (COALESCE(T121.ESTOQUE_TRANS, 0) + 
                 COALESCE(T131.ESTOQUE_TRANS, 0) + 
                 COALESCE(T141.ESTOQUE_TRANS, 0)), 0)
                
            ELSE 0
        END AS EST_TRANS
    FROM TGFPRO PRO
    LEFT JOIN ESTOQUE_TRANSICAO T121 ON PRO.CODPROD = T121.CODPROD AND T121.CODLOCAL = 101 AND T121.CODEMP = 2
    LEFT JOIN ESTOQUE_TRANSICAO T131 ON PRO.CODPROD = T131.CODPROD AND T131.CODLOCAL = 101 AND T131.CODEMP = 3
    LEFT JOIN ESTOQUE_TRANSICAO T141 ON PRO.CODPROD = T141.CODPROD AND T141.CODLOCAL = 101 AND T141.CODEMP = 4

),

TENDENCIA_CALCULADA AS (
    SELECT
        PRO.CODPROD,
        CASE
            WHEN 
                (SELECT SUM(VENDAS.Vendas_Ultimos_30_Dias)
                 FROM VENDAS_MENSAL VENDAS
                 WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) = 0
                AND 
                (SELECT SUM(VENDAS.Vendas_30_Dias_Anteriores)
                 FROM VENDAS_MENSAL VENDAS
                 WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) <> 0
            THEN 'Queda'
            WHEN 
                (SELECT SUM(VENDAS.Vendas_Ultimos_30_Dias)
                 FROM VENDAS_MENSAL VENDAS
                 WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) <> 0
                AND 
                (SELECT SUM(VENDAS.Vendas_30_Dias_Anteriores)
                 FROM VENDAS_MENSAL VENDAS
                 WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) = 0
            THEN 'Aumento'
            ELSE 
                CASE
                    WHEN 
                        COALESCE(
                            (SELECT SUM(VENDAS.Vendas_Ultimos_30_Dias) 
                             FROM VENDAS_MENSAL VENDAS
                             WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) - 
                            (SELECT SUM(VENDAS.Vendas_30_Dias_Anteriores) 
                             FROM VENDAS_MENSAL VENDAS
                             WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)), 
                        0) < 0
                    THEN 'Queda'
                    WHEN 
                        COALESCE(
                            (SELECT SUM(VENDAS.Vendas_Ultimos_30_Dias) 
                             FROM VENDAS_MENSAL VENDAS
                             WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) - 
                            (SELECT SUM(VENDAS.Vendas_30_Dias_Anteriores) 
                             FROM VENDAS_MENSAL VENDAS
                             WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)), 
                        0) = 0
                    THEN 'Permanência'
                    ELSE 'Aumento'
                END
        END AS Tendencia_30D_Canal
    FROM TGFPRO PRO
)
SELECT
    PRO.REFERENCIA AS SKU,
    PRO.DESCRPROD AS PRODUTO,
    PRO.MARCA,
    PRO.AD_TIPOTELA AS QUALIDADE,
    PRO.AD_ANOMODELO AS ANO,
    GRU.DESCRGRUPOPROD AS FAMILIA,
    ABC.CURVA AS CURVA,
    COALESCE(CE.ESTOQUE, 0) AS ESTOQUE,
    COALESCE(TE.EST_TRANS, 0) AS T_ESTOQUE,
    COALESCE((SELECT SUM(EST.TOTAL_ESTOQUE) FROM ESTOQUE_AGRUPADO EST WHERE EST.CODLOCAL = 101 AND EST.CODPROD = PRO.CODPROD), 0) AS EST_PRINCIPAL,
    /* Lógica do Status_Estoques */
    CASE
        WHEN ABC.CURVA = 'PHASEOUT' THEN 'OVERSTOCK'
        WHEN ABC.CURVA = 'D' AND COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) > 3 THEN 'OVERSTOCK'
        WHEN ABC.CURVA = 'D' AND COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) = 0 THEN 'OOS'
        WHEN ABC.CURVA = 'D' AND COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) < 3 THEN 'SHORTAGE'
        WHEN ABC.CURVA = 'D' THEN 'STOCK OK'
        WHEN ABC.CURVA = 'NOVOS' AND COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) > 5 THEN 'OVERSTOCK'
        WHEN ABC.CURVA = 'NOVOS' AND COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) = 0 THEN 'OOS'
        WHEN ABC.CURVA = 'NOVOS' AND COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) < 3 THEN 'SHORTAGE'
        WHEN ABC.CURVA = 'NOVOS' THEN 'STOCK OK'
        WHEN CE.ESTOQUE = 0 THEN 'OOS'
        WHEN (ROUND(
                  (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
              ) / 30) * :P_LEADTIME > COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) THEN 'SHORTAGE'
        WHEN ROUND(
                 (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
             ) * 3 < COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) THEN 'OVERSTOCK'
        ELSE 'STOCK OK'
    END AS Status_Estoques,
    ROUND(
        (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
    ) AS Media_3_Meses,
    CASE
        WHEN ROUND(
            (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
        ) /
        NULLIF(
            ROUND(
                (COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
            ), 0
        ) > 1.2 THEN 'Queda'
        WHEN ROUND(
            (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
        ) /
        NULLIF(
            ROUND(
                (COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
            ), 0
        ) > 0.8 THEN 'Permanência'
        ELSE 'Aumento'
    END AS Status,
    VENDAS.Janeiro,
    VENDAS.Fevereiro,
    VENDAS.Marco,
    VENDAS.Abril,
    VENDAS.Maio,
    VENDAS.Junho,
    VENDAS.Julho,
    VENDAS.Agosto,
    VENDAS.Setembro,
    VENDAS.Outubro,
    VENDAS.Novembro,
    VENDAS.Dezembro,
    VENDAS.Vendas_Ultimos_30_Dias,
    VENDAS.Vendas_30_Dias_Anteriores,
    ROUND(
        (COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) / 2, 2
    ) AS Media_Vendas_30_Dias,
  CASE 
    WHEN VENDAS.Vendas_30_Dias_Anteriores = 0 THEN 0 -- Evita divisão por zero
    ELSE ROUND(((VENDAS.Vendas_Ultimos_30_Dias - VENDAS.Vendas_30_Dias_Anteriores) 
               / VENDAS.Vendas_30_Dias_Anteriores) * 100, 2)
END AS Diferenca_Percentual,

CASE 
    WHEN (COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) = 0 THEN 0
    ELSE CEIL(
        (COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0)) /
        NULLIF((COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) / 60, 0)
    )
END AS Quantos_dias_de_Estoque_60D,

CASE 
    WHEN (COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) = 0 THEN 0 -- Evita divisão por zero ou valores irrelevantes
    ELSE CEIL(
        COALESCE(
            (SELECT SUM(EST.TOTAL_ESTOQUE) 
             FROM ESTOQUE_AGRUPADO EST 
             WHERE EST.CODLOCAL = 101 
               AND EST.CODPROD = PRO.CODPROD), 
            0
        ) / NULLIF(
            (COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) / 60, 
        0)
    )
END AS Quantos_dias_de_Estoque_Principal,

CASE 
    WHEN VENDAS.Mes_Atual IS NULL AND VENDAS.Mes_Anterior_1 IS NULL AND VENDAS.Mes_Anterior_2 IS NULL THEN 0
    WHEN ROUND(
        (COALESCE(VENDAS.Mes_Atual, 0) + 
         COALESCE(VENDAS.Mes_Anterior_1, 0) + 
         COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) = 0 THEN 0
    ELSE CEIL(
        (COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0)) / 
        NULLIF(ROUND(
            (COALESCE(VENDAS.Mes_Atual, 0) + 
             COALESCE(VENDAS.Mes_Anterior_1, 0) + 
             COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30, 0)
    )
END AS Quantos_dias_de_Estoque_90D,
   
    CASE
    WHEN (CASE 
              WHEN VENDAS.Mes_Atual IS NULL AND VENDAS.Mes_Anterior_1 IS NULL AND VENDAS.Mes_Anterior_2 IS NULL THEN 0
              WHEN ROUND(
                  (COALESCE(VENDAS.Mes_Atual, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) = 0 THEN 0
              ELSE ROUND(
                  COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) / NULLIF(
                      ROUND((COALESCE(VENDAS.Mes_Atual, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30, 0), 0)
          END) = 0 THEN '0 - OOS'
    WHEN (CASE 
              WHEN VENDAS.Mes_Atual IS NULL AND VENDAS.Mes_Anterior_1 IS NULL AND VENDAS.Mes_Anterior_2 IS NULL THEN 0
              WHEN ROUND(
                  (COALESCE(VENDAS.Mes_Atual, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) = 0 THEN 0
              ELSE ROUND(
                  COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) / NULLIF(
                      ROUND((COALESCE(VENDAS.Mes_Atual, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30, 0), 0)
          END) > 60 THEN '5 - Excesso'
    WHEN (CASE 
              WHEN VENDAS.Mes_Atual IS NULL AND VENDAS.Mes_Anterior_1 IS NULL AND VENDAS.Mes_Anterior_2 IS NULL THEN 0
              WHEN ROUND(
                  (COALESCE(VENDAS.Mes_Atual, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) = 0 THEN 0
              ELSE ROUND(
                  COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) / NULLIF(
                      ROUND((COALESCE(VENDAS.Mes_Atual, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30, 0), 0)
          END) > 45 THEN '4 - Over'
    WHEN (CASE 
              WHEN VENDAS.Mes_Atual IS NULL AND VENDAS.Mes_Anterior_1 IS NULL AND VENDAS.Mes_Anterior_2 IS NULL THEN 0
              WHEN ROUND(
                  (COALESCE(VENDAS.Mes_Atual, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) = 0 THEN 0
              ELSE ROUND(
                  COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) / NULLIF(
                      ROUND((COALESCE(VENDAS.Mes_Atual, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30, 0), 0)
          END) > 15 THEN '3 - Ponto de equilíbrio'
    WHEN (CASE 
              WHEN VENDAS.Mes_Atual IS NULL AND VENDAS.Mes_Anterior_1 IS NULL AND VENDAS.Mes_Anterior_2 IS NULL THEN 0
              WHEN ROUND(
                  (COALESCE(VENDAS.Mes_Atual, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                   COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) = 0 THEN 0
              ELSE ROUND(
                  COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) / NULLIF(
                      ROUND((COALESCE(VENDAS.Mes_Atual, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                            COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30, 0), 0)
          END) > 7 THEN '2 - Short'
    ELSE '1 - Crítico'
END AS Nivel_de_dias_em_estoque,
CASE 
    WHEN :P_LEADTIME IS NULL THEN 0
    ELSE ROUND(
        (ROUND(
            (COALESCE(VENDAS.Mes_Atual, 0) + 
             COALESCE(VENDAS.Mes_Anterior_1, 0) + 
             COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30) * :P_LEADTIME, 0)
END AS Minimo,

CASE 
    WHEN :P_LEADTIME IS NULL THEN 0
    ELSE ROUND(
        (ROUND(
            (COALESCE(VENDAS.Mes_Atual, 0) + 
             COALESCE(VENDAS.Mes_Anterior_1, 0) + 
             COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30) * :P_LEADTIME * 2, 0)
END AS Maximo,

COALESCE((
   SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8
), 0) AS Qtd_comprada,

COALESCE(
    GREATEST(
        CEIL(
            (ROUND(
                (COALESCE(VENDAS.Mes_Atual, 0) + 
                 COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                 COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2) / 30) * :P_LEADTIME
        ) 
        - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) 
        - COALESCE(
            (SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8
            ), 0)
    , 0)
, 0) AS S_de_Compra,

COALESCE(
    CASE 
        WHEN 
            CASE
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) / NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                         COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 1.2 THEN 'Queda'
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) / NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                         COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 0.8 THEN 'Permanência'
                ELSE 'Aumento'
            END = 'Permanência' THEN 
            GREATEST(
                CEIL(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Atual, 0) + 
                         COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                         COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                    ) / 30 * :P_LEADTIME
                ) 
                - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0)
                - COALESCE(
                    (SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8
                    ), 0)
            , 0)
        WHEN 
            CASE
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) / NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                         COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 1.2 THEN 'Queda'
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) / NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                         COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 0.8 THEN 'Permanência'
                ELSE 'Aumento'
            END = 'Aumento' THEN 
            GREATEST(
                CEIL(
                    (SELECT MAX(VENDAS.Mes_Atual) 
                     FROM DUAL WHERE VENDAS.Mes_Atual IS NOT NULL
                    ) * 1.05 / 30 * :P_LEADTIME
                ) 
                - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0)
                - COALESCE(
                    (SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8
                    ), 0)
            , 0)
        WHEN 
            CASE
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) / NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                         COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 1.2 THEN 'Queda'
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                     COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) / NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + 
                         COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 0.8 THEN 'Permanência'
                ELSE 'Aumento'
            END = 'Queda' THEN 
            GREATEST(
                CEIL(
                    (SELECT MIN(VENDAS.Mes_Atual) 
                     FROM DUAL WHERE VENDAS.Mes_Atual IS NOT NULL
                    ) * 0.95 / 30 * :P_LEADTIME
                ) 
                - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) 
                - COALESCE(
                    (SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8
                    ), 0)
            , 0)
        ELSE 0
    END, 0
) AS S_de_Compra_C_Tendencia,

COALESCE(
    CASE 
        WHEN 
            CASE
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) /
                NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 1.2 THEN 'Queda'
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) /
                NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 0.8 THEN 'Permanência'
                ELSE 'Aumento'
            END = 'Permanência' THEN 
            GREATEST(
                CEIL((VENDAS.Vendas_Ultimos_30_Dias / 30) * :P_LEADTIME) 
                - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) 
                - COALESCE(
                    (SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8
                    ), 0)
            , 0)
        WHEN 
            CASE
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) /
                NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 1.2 THEN 'Queda'
                ELSE 'Aumento'
            END = 'Aumento' THEN 
            GREATEST(
                CEIL(((VENDAS.Vendas_Ultimos_30_Dias * 1.05) / 30) * :P_LEADTIME) 
                - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) 
                - COALESCE(
                    (SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8
                    ), 0)
            , 0)
        WHEN 
            CASE
                WHEN ROUND(
                    (COALESCE(VENDAS.Mes_Atual, 0) + COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 3, 2
                ) /
                NULLIF(
                    ROUND(
                        (COALESCE(VENDAS.Mes_Anterior_1, 0) + COALESCE(VENDAS.Mes_Anterior_2, 0)) / 2, 2
                    ), 0
                ) > 1.2 THEN 'Queda'
                ELSE 'Aumento'
            END = 'Queda' THEN 
            GREATEST(
                CEIL(((VENDAS.Vendas_Ultimos_30_Dias * 0.95) / 30) * :P_LEADTIME) 
                - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) 
                - COALESCE(
                    (SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8
                    ), 0)
            , 0)
        ELSE 0
    END
, 0) AS S_de_compra_30d,

CASE
    WHEN TENDENCIA.Tendencia_30D_Canal = 'Queda' THEN 
        GREATEST(
            CEIL(
                (SELECT SUM(VENDAS.Vendas_Ultimos_30_Dias) 
                 FROM VENDAS_MENSAL VENDAS
                 WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) / 30 * :P_LEADTIME * 0.95
            ) - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) - COALESCE((SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8), 0)
        , 0)
    WHEN TENDENCIA.Tendencia_30D_Canal = 'Aumento' THEN 
        GREATEST(
            CEIL(
                (SELECT SUM(VENDAS.Vendas_Ultimos_30_Dias) 
                 FROM VENDAS_MENSAL VENDAS
                 WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) / 30 * :P_LEADTIME * 1.05
            ) - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) - COALESCE((SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8), 0)
        , 0)
    ELSE 
        GREATEST(
            CEIL(
                (SELECT SUM(VENDAS.Vendas_Ultimos_30_Dias) 
                 FROM VENDAS_MENSAL VENDAS
                 WHERE VENDAS.CODPROD = PRO.CODPROD AND :P_LOJA = TO_CHAR(:P_LOJA)) / 30 * :P_LEADTIME
            ) - COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0) - COALESCE((SELECT COALESCE(SUM(
    CASE 
        WHEN (ITE.QTDNEG - ITE.QTDENTREGUE) > 0 THEN (ITE.QTDNEG - ITE.QTDENTREGUE) 
        ELSE 0 
    END
), 0) AS QTD_PENDENTE
FROM TGFITE ITE
INNER JOIN TGFCAB CAB ON ITE.NUNOTA = CAB.NUNOTA
WHERE 
    CAB.CODTIPOPER IN (1301)
    AND CAB.STATUSNOTA IN ('L','A')
    AND CAB.DTNEG > TO_DATE('01/07/2024', 'DD/MM/YYYY')
    AND ITE.CODPROD = PRO.CODPROD -- Filtra pelo produto atual
    AND CAB.CODEMP = 8), 0)
        , 0)
END AS S_de_Compra_30D_Canal,

CASE 
    WHEN (COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) = 0 THEN 'Não Vende'
    ELSE
        CASE 
            WHEN CEIL((COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0)) / 
                      NULLIF((COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) / 60, 0)) = 0 THEN 'Ruptura'
            WHEN CEIL((COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0)) / 
                      NULLIF((COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) / 60, 0)) < 15 THEN 'Crítico'
            WHEN CEIL((COALESCE(CE.ESTOQUE, 0) + COALESCE(TE.EST_TRANS, 0)) / 
                      NULLIF((COALESCE(VENDAS.Vendas_Ultimos_30_Dias, 0) + COALESCE(VENDAS.Vendas_30_Dias_Anteriores, 0)) / 60, 0)) > 60 THEN 'Excesso'
            ELSE 'Normal'
        END
END AS Classificacao_Ruptura


FROM TGFPRO PRO
LEFT JOIN CND_CABCPRO ABC ON PRO.CODPROD = ABC.CODPROD
LEFT JOIN TGFGRU GRU ON PRO.CODGRUPOPROD = GRU.CODGRUPOPROD
LEFT JOIN CALC_ESTOQUE_TRANS TE ON PRO.CODPROD = TE.CODPROD
LEFT JOIN CALCULADO_ESTOQUE CE ON PRO.CODPROD = CE.CODPROD
LEFT JOIN VENDAS_MENSAL VENDAS ON PRO.CODPROD = VENDAS.CODPROD
LEFT JOIN TENDENCIA_CALCULADA TENDENCIA ON PRO.CODPROD = TENDENCIA.CODPROD
WHERE PRO.ATIVO = 'S'
  AND (
      :P_GRUPO IS NULL OR :P_GRUPO = '' OR PRO.AD_MACROGRUPO = :P_GRUPO
  )
AND PRO.PERMCOMPPROD = 'S'
--AND PRO.REFERENCIA = 'FRO1072'