USE [BDD2_TPI_Basico];
GO

CREATE PROCEDURE dbo.SP_RegistrarAjusteStock
    @IDProducto INT,
    @TipoMovimiento VARCHAR(20),
    @Cantidad INT,
    @Motivo VARCHAR(250),
    @EstadoStock VARCHAR(20) = 'NORMAL'
AS
BEGIN
    IF @TipoMovimiento IS NULL
       OR @TipoMovimiento NOT IN ('AJUSTE_POSITIVO', 'AJUSTE_NEGATIVO')
        THROW 50002, N'El tipo de ajuste de stock es invalido.', 1;

    IF @Cantidad IS NULL OR @Cantidad <= 0
        THROW 50003, N'La cantidad debe ser mayor a cero.', 1;

    IF NULLIF(LTRIM(RTRIM(@Motivo)), '') IS NULL
        THROW 50004, N'El ajuste debe tener un motivo.', 1;

    INSERT INTO dbo.MovimientoStock (IDProducto, TipoMovimiento, Cantidad, Motivo, EstadoStock)
    VALUES (@IDProducto, @TipoMovimiento, @Cantidad, @Motivo, @EstadoStock);
END;
GO