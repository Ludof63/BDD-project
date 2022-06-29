set search_path to socialMarket;


SELECT CF
FROM Volontario
WHERE dataNascita > '1997-1-1';


SELECT codCli
FROM CARTA_CLIENTE
WHERE saldo < 5  and (età_16 >= 2 or età_64 >= 2);


SELECT SUM(costoPunti)
FROM Prodotto NATURAL JOIN Appuntamento  NATURAL JOIN Inventario
WHERE scadenza is NULL and dataOra >= '2022-5-1';


DECLARE vSiteID CONSTANT integer DEFAULT 50;

--B: transazione
BEGIN TRANSACTION;

DO $$ 
DECLARE volontario char(17);
DECLARE spesa int = 10;
BEGIN
    INSERT INTO Appuntamento
    VALUES(
    )
END$$;

INSERT INTO Appuntamento


