USE [BDD2_TPI_Basico];
GO

CREATE VIEW dbo.VW_CatalogoProductos
AS
SELECT
    p.Codigo,
    p.Nombre AS Producto,
    p.Descripcion,
    p.PrecioVentaNeto,
    p.StockActual, 
    p.PorcentajeIVA,
    p.PrecioVentaNeto * (1.0 + p.PorcentajeIVA / 100.0) AS PrecioFinalConIVA,
    c.Nombre AS Categoria,
    c.Descripcion AS DescripcionCategoria
FROM dbo.Producto AS p
INNER JOIN dbo.Categoria AS c ON c.IDCategoria = p.IDCategoria
WHERE p.Activo = 1 AND c.Activo = 1;
GO