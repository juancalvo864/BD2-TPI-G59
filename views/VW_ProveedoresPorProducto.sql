USE [BDD2_TPI_Basico];
GO

CREATE VIEW dbo.VW_ProveedoresPorProducto
AS
SELECT
    p.IDProducto,
    p.Codigo,
    p.Nombre AS Producto,
    pr.IDProveedor,
    pr.RazonSocial AS Proveedor,
    pp.PrecioCompraReferenciaNeto,
    pr.TiempoEntregaDias,
    pr.DiasCredito,
    pp.EsPrincipal
FROM dbo.ProductoProveedor AS pp
INNER JOIN dbo.Producto AS p ON p.IDProducto = pp.IDProducto
INNER JOIN dbo.Proveedor AS pr ON pr.IDProveedor = pp.IDProveedor
WHERE p.Activo = 1
  AND pr.Activo = 1;
GO