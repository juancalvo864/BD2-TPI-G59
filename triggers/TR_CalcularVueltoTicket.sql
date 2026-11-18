USE [BDD2_TPI_Basico];
GO

-- El vuelto se calcula al registrar o modificar el ticket.
CREATE TRIGGER dbo.TR_CalcularVueltoTicket
ON dbo.Ticket
AFTER INSERT, UPDATE
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    WITH VueltoCalculado AS (
        SELECT IDTicket,
               CASE
                   WHEN MedioDePago = 'EFECTIVO' THEN ImporteRecibido - ImporteTotal
                   ELSE 0
               END AS Vuelto
        FROM inserted
    )
    UPDATE t
    SET Vuelto = v.Vuelto
    FROM dbo.Ticket AS t
    INNER JOIN VueltoCalculado AS v ON v.IDTicket = t.IDTicket
    WHERE t.Vuelto <> v.Vuelto;
END;
GO