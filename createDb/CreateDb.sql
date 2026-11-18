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
    IDCategoria INT NOT NULL REFERENCES dbo.Categoria(IDCategoria),
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
    CONSTRAINT CK_Producto_StockMinimo CHECK (StockMinimo >= 0)
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
    IDProveedor INT NOT NULL REFERENCES dbo.Proveedor(IDProveedor),
    Puesto VARCHAR(20) NOT NULL,
    Telefono VARCHAR(20) NOT NULL,
    NombreCompleto VARCHAR(50) NOT NULL,
    Mail VARCHAR(50) NOT NULL
);

CREATE TABLE dbo.ProductoProveedor (
    IDProducto INT NOT NULL REFERENCES dbo.Producto(IDProducto),
    IDProveedor INT NOT NULL REFERENCES dbo.Proveedor(IDProveedor),
    PrecioCompraReferenciaNeto DECIMAL(12,2) NOT NULL,
    EsPrincipal BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_ProductoProveedor PRIMARY KEY (IDProducto, IDProveedor),

    CONSTRAINT CK_ProductoProveedor_PrecioCompraReferenciaNeto CHECK (PrecioCompraReferenciaNeto > 0)
);

-- Compras a proveedores
CREATE TABLE dbo.CompraProveedor (
    IDCompra INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IDProveedor INT NOT NULL REFERENCES dbo.Proveedor(IDProveedor),
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    NumeroComprobante VARCHAR(40) NOT NULL,
    Estado VARCHAR(15) NOT NULL DEFAULT 'RECIBIDA',
    Total DECIMAL(12,2) NOT NULL,

    CONSTRAINT CK_CompraProveedor_Total CHECK (Total >= 0),
    CONSTRAINT CK_CompraProveedor_Estado CHECK (Estado IN ('RECIBIDA', 'ANULADA'))
);

CREATE TABLE dbo.DetalleCompraProveedor (
    IDDetalleCompra INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IDCompra INT NOT NULL REFERENCES dbo.CompraProveedor(IDCompra),
    IDProducto INT NOT NULL REFERENCES dbo.Producto(IDProducto),
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
    CONSTRAINT CK_DetalleCompraProveedor_CostoUnitarioNeto CHECK (CostoUnitarioNeto > 0)
);

-- Ventas a clientes
CREATE TABLE dbo.Ticket (
    IDTicket INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IDCliente INT NULL REFERENCES dbo.Cliente(IDCliente),
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
    CONSTRAINT CK_Ticket_MedioDePago CHECK (MedioDePago IN ('EFECTIVO', 'TRANSFERENCIA', 'CREDITO', 'DEBITO'))
);

CREATE TABLE dbo.DetalleVenta (
    IDDetalleVenta INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IDTicket INT NOT NULL REFERENCES dbo.Ticket(IDTicket),
    IDProducto INT NOT NULL REFERENCES dbo.Producto(IDProducto),
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
    CONSTRAINT CK_DetalleVenta_PrecioUnitarioNeto CHECK (PrecioUnitarioNeto > 0)
);

-- Devoluciones de compras y ventas
CREATE TABLE dbo.DevolucionCompraProveedor (
    IDDevolucionCompra INT IDENTITY(1,1) PRIMARY KEY,
    IDCompra INT NOT NULL REFERENCES dbo.CompraProveedor(IDCompra),
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Motivo VARCHAR(250) NOT NULL
);

CREATE TABLE dbo.DevolucionVenta (
    IDDevolucionVenta INT IDENTITY(1,1) PRIMARY KEY,
    IDTicket INT NOT NULL REFERENCES dbo.Ticket(IDTicket),
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Motivo VARCHAR(250) NOT NULL
);

CREATE TABLE dbo.DetalleDevolucionCompraProveedor (
    IDDetalleDevolucionCompra INT IDENTITY(1,1) PRIMARY KEY,
    IDDevolucionCompra INT NOT NULL
        REFERENCES dbo.DevolucionCompraProveedor(IDDevolucionCompra),
    IDDetalleCompra INT NOT NULL REFERENCES dbo.DetalleCompraProveedor(IDDetalleCompra),
    Cantidad INT NOT NULL,
    EstadoOrigen VARCHAR(20) NOT NULL,
    Observacion VARCHAR(250) NULL,

    CONSTRAINT CK_DetalleDevolucionCompraProveedor_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleDevolucionCompraProveedor_EstadoOrigen CHECK (EstadoOrigen IN ('NORMAL', 'OUTLET', 'REVISION', 'NO_VENDIBLE'))
);

CREATE TABLE dbo.DetalleDevolucionVenta (
    IDDetalleDevolucionVenta INT IDENTITY(1,1) PRIMARY KEY,
    IDDevolucionVenta INT NOT NULL REFERENCES dbo.DevolucionVenta(IDDevolucionVenta),
    IDDetalleVenta INT NOT NULL REFERENCES dbo.DetalleVenta(IDDetalleVenta),
    Cantidad INT NOT NULL,
    CondicionFisica VARCHAR(25) NOT NULL,
    EstadoDestino VARCHAR(20) NOT NULL,
    Observacion VARCHAR(250) NULL,

    CONSTRAINT CK_DetalleDevolucionVenta_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleDevolucionVenta_CondicionFisica CHECK (LEN(LTRIM(CondicionFisica)) > 0),
    CONSTRAINT CK_DetalleDevolucionVenta_EstadoDestino CHECK (EstadoDestino IN ('NORMAL', 'OUTLET', 'REVISION', 'NO_VENDIBLE'))
);

-- Saldos y movimientos de stock
CREATE TABLE dbo.StockProductoEstado (
    IDProducto INT NOT NULL REFERENCES dbo.Producto(IDProducto),
    EstadoStock VARCHAR(20) NOT NULL,
    Cantidad INT NOT NULL,
    CONSTRAINT PK_StockProductoEstado PRIMARY KEY (IDProducto, EstadoStock),

    CONSTRAINT CK_StockProductoEstado_EstadoStock CHECK (EstadoStock IN ('NORMAL', 'OUTLET', 'REVISION', 'NO_VENDIBLE')),
    CONSTRAINT CK_StockProductoEstado_Cantidad CHECK (Cantidad >= 0)
);

CREATE TABLE dbo.MovimientoStock (
    IDMovimiento INT IDENTITY(1,1) PRIMARY KEY,
    TipoMovimiento VARCHAR(20) NOT NULL,
    Cantidad INT NOT NULL,
    FechaMovimiento DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    IDTicket INT NULL REFERENCES dbo.Ticket(IDTicket),
    IDCompra INT NULL REFERENCES dbo.CompraProveedor(IDCompra),
    Motivo VARCHAR(250) NULL,
    IDProducto INT NOT NULL REFERENCES dbo.Producto(IDProducto),
    EstadoStock VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    IDDetalleDevolucionVenta INT NULL
        REFERENCES dbo.DetalleDevolucionVenta(IDDetalleDevolucionVenta),
    IDDetalleDevolucionCompra INT NULL
        REFERENCES dbo.DetalleDevolucionCompraProveedor(IDDetalleDevolucionCompra),

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
    )
);

-- Cada renglón de devolución se contabiliza una sola vez.
CREATE UNIQUE INDEX UX_MovimientoStock_DevolucionVenta
    ON dbo.MovimientoStock (IDDetalleDevolucionVenta)
    WHERE IDDetalleDevolucionVenta IS NOT NULL;

CREATE UNIQUE INDEX UX_MovimientoStock_DevolucionCompra
    ON dbo.MovimientoStock (IDDetalleDevolucionCompra)
    WHERE IDDetalleDevolucionCompra IS NOT NULL;
GO
