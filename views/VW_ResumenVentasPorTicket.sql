USE [BDD2_TPI_Basico];
GO

CREATE VIEW dbo.VW_ResumenVentasPorTicket
AS
SELECT
    t.IDTicket,
    t.Fecha,
    t.IDCliente,
    c.Nombre AS NombreCliente,
    c.Apellido AS ApellidoCliente,
    t.MedioDePago,
    t.ImporteTotal,
    COUNT_BIG(d.IDDetalleVenta) AS CantidadRenglones,
    ISNULL(SUM(CAST(d.Cantidad AS BIGINT)), 0) AS UnidadesVendidas
FROM dbo.Ticket AS t
LEFT JOIN dbo.Cliente AS c ON c.IDCliente = t.IDCliente
LEFT JOIN dbo.DetalleVenta AS d ON d.IDTicket = t.IDTicket
WHERE t.Estado = 'EMITIDO'
GROUP BY t.IDTicket, t.Fecha, t.IDCliente, c.Nombre, c.Apellido,
         t.MedioDePago, t.ImporteTotal;
GO