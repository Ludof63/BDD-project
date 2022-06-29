set search_path to socialMarket;


--A:

SELECT CF
FROM Volontario
WHERE dataNascita > '1997-1-1';


SELECT codCli
FROM CARTA_CLIENTE
WHERE saldo < 5  and (età_16 >= 2 or età_64 >= 2);


SELECT SUM(costoPunti)
FROM Prodotto NATURAL JOIN Appuntamento  NATURAL JOIN Inventario
WHERE scadenza is NULL and dataOra >= '2022-5-1';



--B: transazione
--i valori nelle variabili sono per test
BEGIN TRANSACTION;

DO $$
DECLARE spesa int = 10;
DECLARE fam char(17) = 'CFGPNF43D13L730U' ;
BEGIN
    INSERT INTO Appuntamento (dataOra,saldoInizio, saldoFine, cf, codCli)
    SELECT current_date, saldo , saldo -spesa, fam, codCli
    FROM Familiare NATURAL JOIN Carta_CLiente
    WHERE CF = fam;
END$$;

COMMIT;



