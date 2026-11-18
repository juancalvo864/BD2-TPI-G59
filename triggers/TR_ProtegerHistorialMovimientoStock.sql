USE [BDD2_TPI_Basico];
GO

CREATE TRIGGER dbo.TR_ProtegerHistorialMovimientoStock
ON dbo.MovimientoStock
AFTER UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM deleted)
        THROW 50001, N'Corrija el movimiento con un nuevo ajuste de stock.', 1;
END;
GO

