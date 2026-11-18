USE [BDD2_TPI_Basico];
GO

CREATE PROCEDURE dbo.SP_ConsultarMovimientosPorProducto
    @IDProducto INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.Producto WHERE IDProducto = @IDProducto)
    BEGIN
        PRINT 'El producto especificado no existe';
        RETURN;
    END;

    SELECT
        m.FechaMovimiento, m.TipoMovimiento, m.Cantidad, m.Motivo,
        m.IDTicket, m.IDCompra, m.EstadoStock,
        m.IDDetalleDevolucionVenta, m.IDDetalleDevolucionCompra,
        dv.CondicionFisica,
        COALESCE(dv.Observacion, dc.Observacion) AS ObservacionDevolucion
    FROM dbo.MovimientoStock AS m
    LEFT JOIN dbo.DetalleDevolucionVenta AS dv
        ON dv.IDDetalleDevolucionVenta = m.IDDetalleDevolucionVenta
    LEFT JOIN dbo.DetalleDevolucionCompraProveedor AS dc
        ON dc.IDDetalleDevolucionCompra = m.IDDetalleDevolucionCompra
    WHERE m.IDProducto = @IDProducto
    ORDER BY m.FechaMovimiento DESC, m.IDMovimiento DESC;
END;
GO