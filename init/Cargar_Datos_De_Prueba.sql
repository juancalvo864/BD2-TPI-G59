USE [BDD2_TPI_Basico];
GO

IF DB_NAME() <> N'BDD2_TPI_Basico'
    THROW 50200, N'Seleccione BDD2_TPI_Basico para cargar los datos.', 1;

-- Si falla un INSERT, se deshace la carga.
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- Datos que se usan para las compras y ventas.
INSERT INTO dbo.Categoria (Nombre, Descripcion)
VALUES ('Perifericos', 'Accesorios para equipos'),
       ('Impresion', 'Insumos de impresion');

DECLARE @Perifericos INT = (SELECT IDCategoria FROM dbo.Categoria WHERE Nombre = 'Perifericos');
DECLARE @Impresion INT = (SELECT IDCategoria FROM dbo.Categoria WHERE Nombre = 'Impresion');

INSERT INTO dbo.Producto (IDCategoria, Codigo, Nombre, CostoNeto, MargenGanancia, PorcentajeIVA, StockMinimo)
VALUES (@Perifericos, 'DEMO-TEC-001', 'Teclado USB', 10000, 25, 21, 5),
       (@Perifericos, 'DEMO-MOU-001', 'Mouse USB', 4000, 50, 21, 4),
       (@Impresion, 'DEMO-TON-001', 'Toner negro', 20000, 25, 21, 2);

DECLARE @Teclado INT = (SELECT IDProducto FROM dbo.Producto WHERE Codigo = 'DEMO-TEC-001');
DECLARE @Mouse INT = (SELECT IDProducto FROM dbo.Producto WHERE Codigo = 'DEMO-MOU-001');
DECLARE @Toner INT = (SELECT IDProducto FROM dbo.Producto WHERE Codigo = 'DEMO-TON-001');

INSERT INTO dbo.Proveedor (
    RazonSocial, CUIT, Telefono, Email, DiasCredito, TiempoEntregaDias, MedioPago
)
VALUES ('Distribuidora Demo Norte', '30-00000001-0', '1100000101', 'norte@example.com', 15, 2, 'TRANSFERENCIA'),
       ('Insumos Demo Sur', '30-00000002-0', '1100000102', 'sur@example.com', 30, 4, 'CHEQUE');

DECLARE @Norte INT = (SELECT IDProveedor FROM dbo.Proveedor WHERE CUIT = '30-00000001-0');
DECLARE @Sur INT = (SELECT IDProveedor FROM dbo.Proveedor WHERE CUIT = '30-00000002-0');

INSERT INTO dbo.ProveedorContacto (IDProveedor, Puesto, Telefono, NombreCompleto, Mail)
VALUES (@Norte, 'Ventas', '1100000111', 'Ana Demo', 'ana@example.com'),
       (@Sur, 'Ventas', '1100000112', 'Martin Demo', 'martin@example.com');

INSERT INTO dbo.ProductoProveedor (IDProducto, IDProveedor, PrecioCompraReferenciaNeto, EsPrincipal)
VALUES (@Teclado, @Norte, 10000, 1), (@Teclado, @Sur, 10500, 0),
       (@Mouse, @Norte, 4000, 1), (@Toner, @Sur, 20000, 1);

INSERT INTO dbo.Cliente (Nombre, Apellido, Documento, Email, CondicionIVA, MedioDePago)
VALUES ('Lucia', 'Demo', '99000001', 'lucia@example.com', 'CONSUMIDOR_FINAL', 'EFECTIVO'),
       ('Nicolas', 'Demo', '99000002', 'nicolas@example.com', 'RESPONSABLE_INSCRIPTO', 'TRANSFERENCIA');

DECLARE @Cliente INT = (SELECT IDCliente FROM dbo.Cliente WHERE Documento = '99000001');
DECLARE @CompraNorte INT, @CompraSur INT, @DetalleCompraToner INT;
DECLARE @TicketCliente INT, @TicketAnonimo INT, @DetalleVentaTeclado INT;
DECLARE @DevVenta INT, @DevCompra INT, @DetalleDevCompra INT;

-- Entradas. Diez teclados, cinco mouse y tres toners.
INSERT INTO dbo.CompraProveedor (IDProveedor, Fecha, NumeroComprobante, Total)
VALUES (@Norte, '20261110', 'DEMO-COMPRA-001', 145200.00);
-- Guardamos el ID generado para usarlo en los detalles de la compra.
SET @CompraNorte = SCOPE_IDENTITY();

INSERT INTO dbo.CompraProveedor (IDProveedor, Fecha, NumeroComprobante, Total)
VALUES (@Sur, '20261110', 'DEMO-COMPRA-002', 72600.00);
SET @CompraSur = SCOPE_IDENTITY();

INSERT INTO dbo.DetalleCompraProveedor (
    IDCompra, IDProducto, Cantidad, CostoUnitarioNeto, PorcentajeDescuento, PorcentajeIVA
)
VALUES (@CompraNorte, @Teclado, 10, 10000, 0, 21),
       (@CompraNorte, @Mouse, 5, 4000, 0, 21);

INSERT INTO dbo.DetalleCompraProveedor (
    IDCompra, IDProducto, Cantidad, CostoUnitarioNeto, PorcentajeDescuento, PorcentajeIVA
)
VALUES (@CompraSur, @Toner, 3, 20000, 0, 21);
SET @DetalleCompraToner = SCOPE_IDENTITY();

INSERT INTO dbo.MovimientoStock (TipoMovimiento, Cantidad, FechaMovimiento, IDCompra, IDProducto)
VALUES ('COMPRA', 10, '20261110', @CompraNorte, @Teclado),
       ('COMPRA', 5, '20261110', @CompraNorte, @Mouse),
       ('COMPRA', 3, '20261110', @CompraSur, @Toner);

-- Una venta identificada por cuatro teclados y otra anónima por dos mouse.
INSERT INTO dbo.Ticket (IDCliente, Fecha, Estado, MedioDePago, ImporteTotal, ImporteRecibido)
VALUES (@Cliente, '20261111', 'EMITIDO', 'EFECTIVO', 60500.00, 61000.00);
SET @TicketCliente = SCOPE_IDENTITY();

INSERT INTO dbo.Ticket (Fecha, Estado, MedioDePago, ImporteTotal, ImporteRecibido)
VALUES ('20261111', 'EMITIDO', 'DEBITO', 14520.00, 14520.00);
SET @TicketAnonimo = SCOPE_IDENTITY();

INSERT INTO dbo.DetalleVenta (
    IDTicket, IDProducto, Cantidad, PrecioUnitarioNeto, PorcentajeDescuento, PorcentajeIVA
)
VALUES (@TicketCliente, @Teclado, 4, 12500, 0, 21);
SET @DetalleVentaTeclado = SCOPE_IDENTITY();

INSERT INTO dbo.DetalleVenta (
    IDTicket, IDProducto, Cantidad, PrecioUnitarioNeto, PorcentajeDescuento, PorcentajeIVA
)
VALUES (@TicketAnonimo, @Mouse, 2, 6000, 0, 21);

INSERT INTO dbo.MovimientoStock (TipoMovimiento, Cantidad, FechaMovimiento, IDTicket, IDProducto)
VALUES ('VENTA', 4, '20261111', @TicketCliente, @Teclado),
       ('VENTA', 2, '20261111', @TicketAnonimo, @Mouse);

-- Devolución parcial. Los tres renglones corresponden a la misma línea de venta.
INSERT INTO dbo.DevolucionVenta (IDTicket, Fecha, Motivo)
VALUES (@TicketCliente, '20261112', 'Devolucion parcial de tres teclados');
SET @DevVenta = SCOPE_IDENTITY();

INSERT INTO dbo.DetalleDevolucionVenta (
    IDDevolucionVenta, IDDetalleVenta, Cantidad, CondicionFisica, EstadoDestino
)
VALUES (@DevVenta, @DetalleVentaTeclado, 1, 'SELLADO', 'NORMAL'),
       (@DevVenta, @DetalleVentaTeclado, 1, 'CAJA_ABIERTA', 'OUTLET'),
       (@DevVenta, @DetalleVentaTeclado, 1, 'SIN_INSPECCION', 'REVISION');

INSERT INTO dbo.MovimientoStock (
    TipoMovimiento, Cantidad, FechaMovimiento, IDTicket, IDProducto,
    EstadoStock, IDDetalleDevolucionVenta
)
SELECT 'DEVOLUCION_VENTA', Cantidad, '20261112', @TicketCliente, @Teclado,
       EstadoDestino, IDDetalleDevolucionVenta
FROM dbo.DetalleDevolucionVenta
WHERE IDDevolucionVenta = @DevVenta;

-- Una unidad sale del stock normal para volver al proveedor.
INSERT INTO dbo.DevolucionCompraProveedor (IDCompra, Fecha, Motivo)
VALUES (@CompraSur, '20261113', 'Devolucion de un toner al proveedor');
SET @DevCompra = SCOPE_IDENTITY();

INSERT INTO dbo.DetalleDevolucionCompraProveedor (
    IDDevolucionCompra, IDDetalleCompra, Cantidad, EstadoOrigen
)
VALUES (@DevCompra, @DetalleCompraToner, 1, 'NORMAL');
SET @DetalleDevCompra = SCOPE_IDENTITY();

INSERT INTO dbo.MovimientoStock (
    TipoMovimiento, Cantidad, FechaMovimiento, IDCompra, IDProducto,
    EstadoStock, IDDetalleDevolucionCompra
)
VALUES ('DEVOLUCION_COMPRA', 1, '20261113', @CompraSur, @Toner, 'NORMAL', @DetalleDevCompra);

COMMIT TRANSACTION;


