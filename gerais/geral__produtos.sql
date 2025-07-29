SELECT
    PRO.ATIVO,
    PRO.CODPROD AS "Códio interno",
    PRO.REFERENCIA AS "SKU",
    PRO.DESCRPROD AS "Produto",
    PRO.MARCA AS "Marca",
    PRO.AD_QUALIDADE AS "Qualidade",
    PRO.AD_CORES AS "Cores",
    GRU.DESCRGRUPOPROD AS "Família",
    CASE WHEN PRO.USOPROD = 'R' THEN 'Revenda' WHEN PRO.USOPROD = 'B' THEN 'Brinde' WHEN PRO.USOPROD = 'C' THEN 'Consumo' ELSE PRO.USOPROD END AS "Classificação",
    PRO.AD_MODCOM AS "Modelo Comercial",
    PRO.AD_MODELO AS "Modelo Técnico",
    PRO.AD_ANOMODELO AS "Ano de lançamento",
    PRO.AD_TIPOTELA AS "Tecnologia Skytech",
    PRO.AD_DTCRIACAO AS "Data de Criação",
    NVL(ABC.CURVA, 'D') AS "curva",
    PRO.AD_CODPAI AS "Código pai",
    PRO.AD_HERTZ AS "Tecnologia original",
    PRO.AD_COMPATIBILIDADE AS "Compatibilidade",
    PRO.CARACTERISTICAS AS "Característica",
    PRO.DTALTER AS "Data alteração",
    PRO.IMAGEM AS "Imagem",
    PRO.NCM as "NCM",
    PRO.AD_MODREF AS "Modelo referencia",
    PRO.AD_LINREF AS "Linha referencia",
    PRO.AD_MACROGRUPO AS "Macro Grupo",
    PRO.AD_QUALIFORN AS "Qualidade Fornecedor",
    PRO.AD_DESCRFORN AS "Descrição Fornecedor"
    
FROM TGFPRO PRO

INNER JOIN TGFGRU GRU ON PRO.CODGRUPOPROD = GRU.CODGRUPOPROD
LEFT JOIN AD_CABCPRO ABC ON PRO.CODPROD = ABC.CODPROD

WHERE
   PRO.REFERENCIA <> '0'
   AND SUBSTR(PRO.CODGRUPOPROD,0,2) NOT IN (11, 12, 13, 14)
    AND PRO.ATIVO = 'S'
    --AND SUBSTR(PRO.REFERENCIA,0,3) = 'FRO' 
ORDER BY PRO.CODPROD 


--select * from tgfpro