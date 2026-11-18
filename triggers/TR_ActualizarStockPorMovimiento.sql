USE [BDD2_TPI_Basico];
GO

-- Controla el movimiento y actualiza el stock en el mismo INSERT.
CREATE TRIGGER dbo.TR_ActualizarStockPorMovimiento
ON dbo.MovimientoStock
AFTER INSERT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- Si dos usuarios mueven el mismo producto, uno espera a que termine el otro.
    DECLARE @ProductosBloqueados BIGINT;

    SELECT @ProductosBloqueados = COUNT_BIG(*)
    FROM dbo.Producto AS p WITH (UPDLOCK, HOLDLOCK)
    INNER JOIN (SELECT DISTINCT IDProducto FROM inserted) AS i
        ON i.IDProducto = p.IDProducto;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.DetalleDevolucionVenta AS dd
            ON dd.IDDetalleDevolucionVenta = i.IDDetalleDevolucionVenta
        INNER JOIN dbo.DevolucionVenta AS d ON d.IDDevolucionVenta = dd.IDDevolucionVenta
        INNER JOIN dbo.DetalleVenta AS original ON original.IDDetalleVenta = dd.IDDetalleVenta
        WHERE i.IDTicket <> d.IDTicket OR d.IDTicket <> original.IDTicket
           OR i.IDProducto <> original.IDProducto OR i.Cantidad <> dd.Cantidad
           OR i.EstadoStock <> dd.EstadoDestino
    )
        THROW 50102, N'El movimiento no coincide con el renglón de devolución de venta.', 1;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.DetalleDevolucionCompraProveedor AS dd
            ON dd.IDDetalleDevolucionCompra = i.IDDetalleDevolucionCompra
        INNER JOIN dbo.DevolucionCompraProveedor AS d
            ON d.IDDevolucionCompra = dd.IDDevolucionCompra
        INNER JOIN dbo.DetalleCompraProveedor AS original ON original.IDDetalleCompra = dd.IDDetalleCompra
        WHERE i.IDCompra <> d.IDCompra OR d.IDCompra <> original.IDCompra
           OR i.IDProducto <> original.IDProducto OR i.Cantidad <> dd.Cantidad
           OR i.EstadoStock <> dd.EstadoOrigen
    )
        THROW 50103, N'El movimiento no coincide con el renglón de devolución al proveedor.', 1;

    -- Sumar lo devuelto para cada línea original, incluida la devolución nueva.
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.DetalleDevolucionVenta AS dd
            ON dd.IDDetalleDevolucionVenta = i.IDDetalleDevolucionVenta
        INNER JOIN dbo.DetalleVenta AS original ON original.IDDetalleVenta = dd.IDDetalleVenta
        WHERE original.Cantidad < (
            SELECT SUM(CAST(m.Cantidad AS BIGINT))
            FROM dbo.DetalleDevolucionVenta AS anterior
            INNER JOIN dbo.MovimientoStock AS m WITH (READCOMMITTEDLOCK)
                ON m.IDDetalleDevolucionVenta = anterior.IDDetalleDevolucionVenta
            WHERE anterior.IDDetalleVenta = original.IDDetalleVenta
        )
    )
        THROW 50104, N'La devolución acumulada supera la cantidad vendida.', 1;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.DetalleDevolucionCompraProveedor AS dd
            ON dd.IDDetalleDevolucionCompra = i.IDDetalleDevolucionCompra
        INNER JOIN dbo.DetalleCompraProveedor AS original ON original.IDDetalleCompra = dd.IDDetalleCompra
        WHERE original.Cantidad < (
            SELECT SUM(CAST(m.Cantidad AS BIGINT))
            FROM dbo.DetalleDevolucionCompraProveedor AS anterior
            INNER JOIN dbo.MovimientoStock AS m WITH (READCOMMITTEDLOCK)
                ON m.IDDetalleDevolucionCompra = anterior.IDDetalleDevolucionCompra
            WHERE anterior.IDDetalleCompra = original.IDDetalleCompra
        )
    )
        THROW 50105, N'La devolución acumulada supera la cantidad comprada.', 1;

    DECLARE @Saldos TABLE (
        IDProducto INT,
        EstadoStock VARCHAR(20),
        Cantidad BIGINT,
        PRIMARY KEY (IDProducto, EstadoStock)
    );

    -- Las entradas suman y las salidas restan.
    INSERT INTO @Saldos (IDProducto, EstadoStock, Cantidad)
    SELECT
        i.IDProducto,
        i.EstadoStock,
        SUM(CASE
            WHEN i.TipoMovimiento IN ('COMPRA', 'DEVOLUCION_VENTA', 'AJUSTE_POSITIVO')
                THEN CAST(i.Cantidad AS BIGINT)
            ELSE -CAST(i.Cantidad AS BIGINT)
        END)
        + CASE
            WHEN i.EstadoStock = 'NORMAL' THEN p.StockActual
            ELSE ISNULL(s.Cantidad, 0)
        END
    FROM inserted AS i
    INNER JOIN dbo.Producto AS p ON p.IDProducto = i.IDProducto
    LEFT JOIN dbo.StockProductoEstado AS s WITH (READCOMMITTEDLOCK)
        ON s.IDProducto = i.IDProducto AND s.EstadoStock = i.EstadoStock
    GROUP BY i.IDProducto, i.EstadoStock, p.StockActual, s.Cantidad;

    IF EXISTS (SELECT 1 FROM @Saldos WHERE Cantidad < 0 OR Cantidad > 2147483647)
        THROW 50106, N'El movimiento deja un saldo fuera del rango permitido para ese estado de stock.', 1;

    -- Actualizar el saldo si ya existe.
    UPDATE s
    SET Cantidad = n.Cantidad
    FROM dbo.StockProductoEstado AS s
    INNER JOIN @Saldos AS n
        ON n.IDProducto = s.IDProducto AND n.EstadoStock = s.EstadoStock;

    -- Crear el saldo la primera vez que el producto entra en ese estado.
    INSERT INTO dbo.StockProductoEstado (IDProducto, EstadoStock, Cantidad)
    SELECT n.IDProducto, n.EstadoStock, n.Cantidad
    FROM @Saldos AS n
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.StockProductoEstado AS s WITH (READCOMMITTEDLOCK)
        WHERE s.IDProducto = n.IDProducto AND s.EstadoStock = n.EstadoStock
    );

    -- El catálogo muestra solamente el saldo normal.
    UPDATE p
    SET StockActual = n.Cantidad
    FROM dbo.Producto AS p
    INNER JOIN @Saldos AS n ON n.IDProducto = p.IDProducto
    WHERE n.EstadoStock = 'NORMAL';
END;
GO

