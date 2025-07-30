-- CONSULTA FINAL COM CURVA ABC POR FAMÍLIA (ÚLTIMOS 365 DIAS ATÉ ONTEM)
SELECT 
    Sku,
    Familia,
    Soma_de_Quantidade,
    SUM(Soma_de_Quantidade) OVER (PARTITION BY Familia) AS Total_da_Familia,
    
    -- Participação percentual
    ROUND(
        Soma_de_Quantidade / NULLIF(SUM(Soma_de_Quantidade) OVER (PARTITION BY Familia), 0) * 100,
        2
    ) AS Participacao_Percentual,

    -- Percentual acumulado por família
    ROUND(
        SUM(Soma_de_Quantidade) OVER (
            PARTITION BY Familia 
            ORDER BY Soma_de_Quantidade DESC, Sku
        ) 
        / NULLIF(SUM(Soma_de_Quantidade) OVER (PARTITION BY Familia), 0) * 100,
        2
    ) AS Percentual_Acumulado,

    -- Classificação ABC
    CASE
        WHEN ROUND(
            SUM(Soma_de_Quantidade) OVER (
                PARTITION BY Familia 
                ORDER BY Soma_de_Quantidade DESC, Sku
            ) 
            / NULLIF(SUM(Soma_de_Quantidade) OVER (PARTITION BY Familia), 0) * 100,
            2
        ) <= 70 THEN 'A'
        WHEN ROUND(
            SUM(Soma_de_Quantidade) OVER (
                PARTITION BY Familia 
                ORDER BY Soma_de_Quantidade DESC, Sku
            ) 
            / NULLIF(SUM(Soma_de_Quantidade) OVER (PARTITION BY Familia), 0) * 100,
            2
        ) <= 95 THEN 'B'
        ELSE 'C'
    END AS Curva_ABC

FROM (
    SELECT 
        PRO.REFERENCIA AS Sku,
        GRU.DESCRGRUPOPROD AS Familia,
        FLOOR(
            SUM(
                CASE 
                    WHEN CAB.TIPMOV = 'V' THEN ITE.QTDNEG
                    ELSE ITE.QTDNEG
                END
            )
        ) AS Soma_de_Quantidade
    FROM TGFITE ITE
    INNER JOIN TGFCAB CAB ON CAB.NUNOTA = ITE.NUNOTA
    INNER JOIN TGFPRO PRO ON PRO.CODPROD = ITE.CODPROD
    INNER JOIN TGFGRU GRU ON PRO.CODGRUPOPROD = GRU.CODGRUPOPROD
    WHERE
        CAB.TIPMOV = 'V'
        AND CAB.CODTIPOPER IN (3021, 3022, 4201, 4056, 4057, 4025, 4028, 4029, 4021, 1201)
        AND CAB.DTNEG BETWEEN TRUNC(SYSDATE - 366) AND TRUNC(SYSDATE - 1)
        AND CAB.STATUSNOTA = 'L'
    GROUP BY 
        PRO.REFERENCIA, 
        GRU.DESCRGRUPOPROD
) SUB

ORDER BY 
    Familia ASC,
    Soma_de_Quantidade DESC