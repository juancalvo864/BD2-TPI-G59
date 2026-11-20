-- 01. Crear la base, las tablas y sus relaciones.
CREATE DATABASE [BDD2_TPI_Basico];
GO

USE [BDD2_TPI_Basico];
GO

-- Productos y datos de contacto
CREATE TABLE dbo.Categoria (
    IDCategoria INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(80) NOT NULL UNIQUE,
    Descripcion VARCHAR(250) NULL,
    Activo BIT NOT NULL DEFAULT 1
);

CREATE TABLE dbo.Cliente (
    IDCliente INT not null IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(80) NOT NULL,
    Apellido VARCHAR(80) NOT NULL,
    Documento VARCHAR(20) UNIQUE NOT NULL,
    Telefono VARCHAR(30) NULL,
    Email VARCHAR(120) NULL,
    Activo BIT NOT NULL DEFAULT 1,
    CondicionIVA VARCHAR(25) NOT NULL DEFAULT 'CONSUMIDOR_FINAL',
    MedioDePago VARCHAR(25) NOT NULL,

    CONSTRAINT CK_Cliente_CondicionIVA CHECK (CondicionIVA IN ('CONSUMIDOR_FINAL', 'RESPONSABLE_INSCRIPTO', 'MONOTRIBUTO', 'EXENTO')),
    CONSTRAINT CK_Cliente_MedioDePago CHECK (MedioDePago IN ('EFECTIVO', 'TRANSFERENCIA', 'CREDITO', 'DEBITO'))
);

CREATE TABLE dbo.Producto (
    IDProducto INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IDCategoria INT NOT NULL,
    Codigo VARCHAR(30) not null unique,
    Nombre VARCHAR(120) NOT NULL,
    Descripcion VARCHAR(250) NULL,
    CostoNeto DECIMAL(12,2) NOT NULL,
    MargenGanancia DECIMAL(5,2) NOT NULL,
    PorcentajeIVA DECIMAL(4,2) NOT NULL,
    PrecioVentaNeto AS (
        CAST(CostoNeto * (1.0 + MargenGanancia / 100.0) AS DECIMAL(18,2))
    ) PERSISTED NOT NULL,
    StockActual INT NOT NULL default 0,
    StockMinimo INT not null DEFAULT 0,
    Activo BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_Producto_CostoNeto CHECK (CostoNeto > 0),
    CONSTRAINT CK_Producto_MargenGanancia CHECK (MargenGanancia >= 0),
    CONSTRAINT CK_Producto_PorcentajeIVA CHECK (PorcentajeIVA >= 0),
    CONSTRAINT CK_Producto_StockActual CHECK (StockActual >= 0),
    CONSTRAINT CK_Producto_StockMinimo CHECK (StockMinimo >= 0),

    CONSTRAINT FK_Producto_Categoria
        FOREIGN KEY (IDCategoria) REFERENCES dbo.Categoria(IDCategoria)
);

CREATE TABLE dbo.Proveedor (
    IDProveedor INT IDENTITY (1,1) PRIMARY KEY,
    RazonSocial VARCHAR(120) NOT NULL,
    CUIT VARCHAR(13) NOT NULL UNIQUE,
    Telefono VARCHAR (20) NOT NULL,
    Email VARCHAR (120) NOT NULL,
    Activo BIT NOT NULL DEFAULT 1,
    DiasCredito TINYINT NOT NULL DEFAULT 0,
    TiempoEntregaDias TINYINT NOT NULL DEFAULT 0,
    MedioPago VARCHAR(20) NOT NULL,

    CONSTRAINT CK_Proveedor_MedioPago CHECK (MedioPago IN ('TRANSFERENCIA', 'CHEQUE', 'EFECTIVO'))
);

CREATE TABLE dbo.ProveedorContacto (
    IDContacto INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IDProveedor INT NOT NULL,
    Puesto VARCHAR(20) NOT NULL,
    Telefono VARCHAR(20) NOT NULL,
    NombreCompleto VARCHAR(50) NOT NULL,
    Mail VARCHAR(50) NOT NULL,

    CONSTRAINT FK_ProveedorContacto_Proveedor
        FOREIGN KEY (IDProveedor) REFERENCES dbo.Proveedor(IDProveedor)
);

CREATE TABLE dbo.ProductoProveedor (
    IDProducto INT NOT NULL,
    IDProveedor INT NOT NULL,
    PrecioCompraReferenciaNeto DECIMAL(12,2) NOT NULL,
    EsPrincipal BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_ProductoProveedor PRIMARY KEY (IDProducto, IDProveedor),

    CONSTRAINT CK_ProductoProveedor_PrecioCompraReferenciaNeto CHECK (PrecioCompraReferenciaNeto > 0),

    CONSTRAINT FK_ProductoProveedor_Producto
        FOREIGN KEY (IDProducto) REFERENCES dbo.Producto(IDProducto),
    CONSTRAINT FK_ProductoProveedor_Proveedor
        FOREIGN KEY (IDProveedor) REFERENCES dbo.Proveedor(IDProveedor)
);

-- Compras a proveedores
CREATE TABLE dbo.CompraProveedor (
    IDCompra INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IDProveedor INT NOT NULL,
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    NumeroComprobante VARCHAR(40) NOT NULL,
    Estado VARCHAR(15) NOT NULL DEFAULT 'RECIBIDA',
    Total DECIMAL(12,2) NOT NULL,

    CONSTRAINT CK_CompraProveedor_Total CHECK (Total >= 0),
    CONSTRAINT CK_CompraProveedor_Estado CHECK (Estado IN ('RECIBIDA', 'ANULADA')),

    CONSTRAINT FK_CompraProveedor_Proveedor
        FOREIGN KEY (IDProveedor) REFERENCES dbo.Proveedor(IDProveedor)
);

CREATE TABLE dbo.DetalleCompraProveedor (
    IDDetalleCompra INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IDCompra INT NOT NULL,
    IDProducto INT NOT NULL,
    Cantidad INT NOT NULL,
    CostoUnitarioNeto DECIMAL(12,2) NOT NULL,
    PorcentajeDescuento DECIMAL (5,2) NOT NULL,
    PorcentajeIVA DECIMAL(4,2) NOT NULL,
    PrecioConDescuento AS (
        CAST(CostoUnitarioNeto * (1 - PorcentajeDescuento / 100.0) AS DECIMAL(14,2))
    ) PERSISTED NOT NULL,
    SubtotalNeto AS (
        CAST((CostoUnitarioNeto * (1 - PorcentajeDescuento / 100.0)) * Cantidad AS DECIMAL(24,2))
    ) PERSISTED NOT NULL,
    SubtotalFinal AS (
        CAST(((CostoUnitarioNeto * (1 - PorcentajeDescuento / 100.0)) * Cantidad) * (1 + PorcentajeIVA / 100.0) AS DECIMAL(24,2))
    ) PERSISTED NOT NULL,

    CONSTRAINT CK_DetalleCompraProveedor_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleCompraProveedor_PorcentajeDescuento CHECK (PorcentajeDescuento BETWEEN 0 AND 100),
    CONSTRAINT CK_DetalleCompraProveedor_PorcentajeIVA CHECK (PorcentajeIVA >= 0),
    CONSTRAINT CK_DetalleCompraProveedor_CostoUnitarioNeto CHECK (CostoUnitarioNeto > 0),

    CONSTRAINT FK_DetalleCompraProveedor_CompraProveedor
        FOREIGN KEY (IDCompra) REFERENCES dbo.CompraProveedor(IDCompra),
    CONSTRAINT FK_DetalleCompraProveedor_Producto
        FOREIGN KEY (IDProducto) REFERENCES dbo.Producto(IDProducto)
);

-- Ventas a clientes
CREATE TABLE dbo.Ticket (
    IDTicket INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IDCliente INT NULL,
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Estado VARCHAR(10) NOT NULL,
    NumeroOrdenCompra VARCHAR(50) NULL, --por si una empresa compra y quiere dejar registrado su numero de orden, B2B.
    MedioDePago VARCHAR(25) NOT NULL,
    ImporteTotal DECIMAL(12,2) NOT NULL,
    ImporteRecibido DECIMAL (12,2) NOT NULL,
    Vuelto DECIMAL(13,2) NOT NULL DEFAULT 0,

    CONSTRAINT CK_Ticket_ImporteTotal CHECK (ImporteTotal >= 0),
    CONSTRAINT CK_Ticket_ImporteRecibido CHECK (ImporteRecibido >= 0),
    CONSTRAINT CK_Ticket_Estado CHECK (Estado IN ('EMITIDO', 'ANULADO')),
    CONSTRAINT CK_Ticket_MedioDePago CHECK (MedioDePago IN ('EFECTIVO', 'TRANSFERENCIA', 'CREDITO', 'DEBITO')),

    CONSTRAINT FK_Ticket_Cliente
        FOREIGN KEY (IDCliente) REFERENCES dbo.Cliente(IDCliente)
);

CREATE TABLE dbo.DetalleVenta (
    IDDetalleVenta INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IDTicket INT NOT NULL,
    IDProducto INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitarioNeto DECIMAL(12,2) NOT NULL,
    PorcentajeDescuento DECIMAL (5,2) NOT NULL,
    PorcentajeIVA DECIMAL(4,2) NOT NULL,
    PrecioConDescuento AS (
        CAST(PrecioUnitarioNeto * (1 - PorcentajeDescuento / 100) AS DECIMAL(14,2))
    ) PERSISTED NOT NULL,
    SubtotalNeto AS (
        CAST((PrecioUnitarioNeto * (1 - PorcentajeDescuento / 100)) * Cantidad AS DECIMAL(24,2))
    ) PERSISTED NOT NULL,
    SubtotalFinal AS (
        CAST(((PrecioUnitarioNeto * (1 - PorcentajeDescuento / 100)) * Cantidad) * (1 + PorcentajeIVA / 100) AS DECIMAL(24,2))
    ) PERSISTED NOT NULL,

    CONSTRAINT CK_DetalleVenta_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleVenta_PorcentajeDescuento CHECK (PorcentajeDescuento BETWEEN 0 AND 100),
    CONSTRAINT CK_DetalleVenta_PorcentajeIVA CHECK (PorcentajeIVA >= 0),
    CONSTRAINT CK_DetalleVenta_PrecioUnitarioNeto CHECK (PrecioUnitarioNeto > 0),

    CONSTRAINT FK_DetalleVenta_Ticket
        FOREIGN KEY (IDTicket) REFERENCES dbo.Ticket(IDTicket),
    CONSTRAINT FK_DetalleVenta_Producto
        FOREIGN KEY (IDProducto) REFERENCES dbo.Producto(IDProducto)
);

-- Devoluciones de compras y ventas
CREATE TABLE dbo.DevolucionCompraProveedor (
    IDDevolucionCompra INT IDENTITY(1,1) PRIMARY KEY,
    IDCompra INT NOT NULL,
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Motivo VARCHAR(250) NOT NULL,

    CONSTRAINT FK_DevolucionCompraProveedor_CompraProveedor
        FOREIGN KEY (IDCompra) REFERENCES dbo.CompraProveedor(IDCompra)
);

CREATE TABLE dbo.DevolucionVenta (
    IDDevolucionVenta INT IDENTITY(1,1) PRIMARY KEY,
    IDTicket INT NOT NULL,
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Motivo VARCHAR(250) NOT NULL,

    CONSTRAINT FK_DevolucionVenta_Ticket
        FOREIGN KEY (IDTicket) REFERENCES dbo.Ticket(IDTicket)
);

CREATE TABLE dbo.DetalleDevolucionCompraProveedor (
    IDDetalleDevolucionCompra INT IDENTITY(1,1) PRIMARY KEY,
    IDDevolucionCompra INT NOT NULL,
    IDDetalleCompra INT NOT NULL,
    Cantidad INT NOT NULL,
    EstadoOrigen VARCHAR(20) NOT NULL,
    Observacion VARCHAR(250) NULL,

    CONSTRAINT CK_DetalleDevolucionCompraProveedor_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleDevolucionCompraProveedor_EstadoOrigen CHECK (EstadoOrigen IN ('NORMAL', 'OUTLET', 'REVISION', 'NO_VENDIBLE')),

    CONSTRAINT FK_DetalleDevolucionCompraProveedor_DevolucionCompraProveedor
        FOREIGN KEY (IDDevolucionCompra) REFERENCES dbo.DevolucionCompraProveedor(IDDevolucionCompra),
    CONSTRAINT FK_DetalleDevolucionCompraProveedor_DetalleCompraProveedor
        FOREIGN KEY (IDDetalleCompra) REFERENCES dbo.DetalleCompraProveedor(IDDetalleCompra)
);

CREATE TABLE dbo.DetalleDevolucionVenta (
    IDDetalleDevolucionVenta INT IDENTITY(1,1) PRIMARY KEY,
    IDDevolucionVenta INT NOT NULL,
    IDDetalleVenta INT NOT NULL,
    Cantidad INT NOT NULL,
    CondicionFisica VARCHAR(25) NOT NULL,
    EstadoDestino VARCHAR(20) NOT NULL,
    Observacion VARCHAR(250) NULL,

    CONSTRAINT CK_DetalleDevolucionVenta_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleDevolucionVenta_CondicionFisica CHECK (LEN(LTRIM(CondicionFisica)) > 0),
    CONSTRAINT CK_DetalleDevolucionVenta_EstadoDestino CHECK (EstadoDestino IN ('NORMAL', 'OUTLET', 'REVISION', 'NO_VENDIBLE')),

    CONSTRAINT FK_DetalleDevolucionVenta_DevolucionVenta
        FOREIGN KEY (IDDevolucionVenta) REFERENCES dbo.DevolucionVenta(IDDevolucionVenta),
    CONSTRAINT FK_DetalleDevolucionVenta_DetalleVenta
        FOREIGN KEY (IDDetalleVenta) REFERENCES dbo.DetalleVenta(IDDetalleVenta)
);

-- Saldos y movimientos de stock
CREATE TABLE dbo.StockProductoEstado (
    IDProducto INT NOT NULL,
    EstadoStock VARCHAR(20) NOT NULL,
    Cantidad INT NOT NULL,
    CONSTRAINT PK_StockProductoEstado PRIMARY KEY (IDProducto, EstadoStock),

    CONSTRAINT CK_StockProductoEstado_EstadoStock CHECK (EstadoStock IN ('NORMAL', 'OUTLET', 'REVISION', 'NO_VENDIBLE')),
    CONSTRAINT CK_StockProductoEstado_Cantidad CHECK (Cantidad >= 0),

    CONSTRAINT FK_StockProductoEstado_Producto
        FOREIGN KEY (IDProducto) REFERENCES dbo.Producto(IDProducto)
);

CREATE TABLE dbo.MovimientoStock (
    IDMovimiento INT IDENTITY(1,1) PRIMARY KEY,
    TipoMovimiento VARCHAR(20) NOT NULL,
    Cantidad INT NOT NULL,
    FechaMovimiento DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    IDTicket INT NULL,
    IDCompra INT NULL,
    Motivo VARCHAR(250) NULL,
    IDProducto INT NOT NULL,
    EstadoStock VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    IDDetalleDevolucionVenta INT NULL,
    IDDetalleDevolucionCompra INT NULL,

    CONSTRAINT CK_MovimientoStock_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_MovimientoStock_EstadoStock CHECK (EstadoStock IN ('NORMAL', 'OUTLET', 'REVISION', 'NO_VENDIBLE')),
    CONSTRAINT CK_MovimientoStock_Origen CHECK (
        (TipoMovimiento = 'VENTA'
            AND IDTicket IS NOT NULL AND IDCompra IS NULL AND EstadoStock = 'NORMAL'
            AND IDDetalleDevolucionVenta IS NULL AND IDDetalleDevolucionCompra IS NULL)
        OR (TipoMovimiento = 'COMPRA'
            AND IDCompra IS NOT NULL AND IDTicket IS NULL AND EstadoStock = 'NORMAL'
            AND IDDetalleDevolucionVenta IS NULL AND IDDetalleDevolucionCompra IS NULL)
        OR (TipoMovimiento = 'DEVOLUCION_VENTA'
            AND IDTicket IS NOT NULL AND IDCompra IS NULL
            AND IDDetalleDevolucionVenta IS NOT NULL AND IDDetalleDevolucionCompra IS NULL)
        OR (TipoMovimiento = 'DEVOLUCION_COMPRA'
            AND IDCompra IS NOT NULL AND IDTicket IS NULL
            AND IDDetalleDevolucionCompra IS NOT NULL AND IDDetalleDevolucionVenta IS NULL)
        OR (TipoMovimiento IN ('AJUSTE_POSITIVO', 'AJUSTE_NEGATIVO')
            AND IDTicket IS NULL AND IDCompra IS NULL
            AND IDDetalleDevolucionVenta IS NULL AND IDDetalleDevolucionCompra IS NULL)
    ),

    CONSTRAINT FK_MovimientoStock_Ticket
        FOREIGN KEY (IDTicket) REFERENCES dbo.Ticket(IDTicket),
    CONSTRAINT FK_MovimientoStock_CompraProveedor
        FOREIGN KEY (IDCompra) REFERENCES dbo.CompraProveedor(IDCompra),
    CONSTRAINT FK_MovimientoStock_Producto
        FOREIGN KEY (IDProducto) REFERENCES dbo.Producto(IDProducto),
    CONSTRAINT FK_MovimientoStock_DetalleDevolucionVenta
        FOREIGN KEY (IDDetalleDevolucionVenta) REFERENCES dbo.DetalleDevolucionVenta(IDDetalleDevolucionVenta),
    CONSTRAINT FK_MovimientoStock_DetalleDevolucionCompraProveedor
        FOREIGN KEY (IDDetalleDevolucionCompra) REFERENCES dbo.DetalleDevolucionCompraProveedor(IDDetalleDevolucionCompra)
);

-- Cada renglón de devolución se contabiliza una sola vez.
CREATE UNIQUE INDEX UX_MovimientoStock_DevolucionVenta
    ON dbo.MovimientoStock (IDDetalleDevolucionVenta)
    WHERE IDDetalleDevolucionVenta IS NOT NULL;

CREATE UNIQUE INDEX UX_MovimientoStock_DevolucionCompra
    ON dbo.MovimientoStock (IDDetalleDevolucionCompra)
    WHERE IDDetalleDevolucionCompra IS NOT NULL;
GO
