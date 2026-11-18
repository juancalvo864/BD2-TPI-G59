USE [BDD2_TPI_Basico];
GO

CREATE VIEW dbo.VW_ProductosParaReposicion
AS
SELECT
    p.IDProducto,
    p.Codigo,
    p.Nombre AS Producto,
    c.Nombre AS Categoria,
    p.StockActual,
    p.StockMinimo,
    p.StockMinimo - p.StockActual AS UnidadesHastaMinimo
FROM dbo.Producto AS p
INNER JOIN dbo.Categoria AS c ON c.IDCategoria = p.IDCategoria
WHERE p.Activo = 1
  AND c.Activo = 1
  AND p.StockActual <= p.StockMinimo;
GO