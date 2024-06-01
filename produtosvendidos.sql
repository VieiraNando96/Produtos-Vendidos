WITH qtd_venda AS (
    SELECT 
        vi.id_produto, 
        SUM(vi.quantidade) AS qtd 
    FROM 
        pdv.vendaitem vi
        JOIN pdv.venda v ON vi.id_venda = v.id
    WHERE 
        v.id_loja = 1 
        AND v.data BETWEEN '2023-09-01' AND '2023-11-30'
    GROUP BY 
        vi.id_produto
)

SELECT 
    p.id AS "Codigo Produto",
    p.descricaocompleta AS "Produto",
    CAST(pc.custocomimposto AS MONEY) AS "Custo",
    CAST(pc.precovenda AS MONEY) AS "Preço Venda",
    CAST(
        CASE 
            WHEN pc.custosemimposto = 0 THEN 0
            ELSE ROUND(
                pc.custosemimposto / 
                (
                    1 - ((tp.valorpis + tp.valorcofins) / 100) - 
                    (a.porcentagemfinal / 100) - 
                    ((SELECT REPLACE(valor, ',', '.') FROM parametrovalor WHERE id_parametro = 96 AND id_loja = l.id)::numeric / 100) - 
                    (pc.operacional / 100)
                ), 2
            ) 
        END AS MONEY
    ) AS "PMZ",
    CASE 
        WHEN pc.margem IS NULL THEN '-' 
        ELSE CONCAT(pc.margem, ' %')  
    END AS "Margem Cadastro",
    qv.qtd AS "Quantidade Vendida",
    CAST(pc.custocomimposto * qv.qtd AS MONEY) AS "Custo Venda",
    CAST(pc.precovenda * qv.qtd AS MONEY) AS "Total Venda",
    CAST((pc.precovenda * qv.qtd) - (pc.custocomimposto * qv.qtd) AS MONEY) AS "Lucro Bruto",
    CONCAT(
        ROUND(
            CASE 
                WHEN pc.precovenda = 0 OR pc.custocomimposto = 0 THEN 0 
                ELSE ((pc.precovenda * qv.qtd) - (pc.custocomimposto * qv.qtd)) * 100 / (pc.precovenda * qv.qtd)
            END, 2
        ), ' %'
    ) AS "% Lucro Bruto"
FROM 
    produto p
    INNER JOIN produtocomplemento pc ON p.id = pc.id_produto
    INNER JOIN tipopiscofins tp ON tp.id = p.id_tipopiscofins
    INNER JOIN produtoaliquota pa ON pa.id_produto = p.id 
    INNER JOIN aliquota a ON a.id = pa.id_aliquotaconsumidor 
    INNER JOIN loja l ON pc.id_loja = l.id
    INNER JOIN qtd_venda qv ON p.id = qv.id_produto
WHERE 
    pc.id_loja = 1
	
order by p.descricaocompleta
