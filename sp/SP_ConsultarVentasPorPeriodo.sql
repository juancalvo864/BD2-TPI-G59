USE [BDD2_TPI_Basico];
GO

CREATE PROCEDURE dbo.SP_ConsultarVentasPorPeriodo
    @Desde DATETIME2,
    @HastaExclusiva DATETIME2
AS
BEGIN
    IF @Desde IS NULL OR @HastaExclusiva IS NULL OR @Desde >= @HastaExclusiva
        THROW 50006, N'Indique un rango valido. Desde debe ser menor que HastaExclusiva.', 1;

    SELECT
        IDTicket, Fecha, IDCliente, NombreCliente, ApellidoCliente,
        MedioDePago, ImporteTotal, CantidadRenglones, UnidadesVendidas
    FROM dbo.VW_ResumenVentasPorTicket
    WHERE Fecha >= @Desde
      AND Fecha < @HastaExclusiva
    ORDER BY Fecha, IDTicket;
END;
GO
