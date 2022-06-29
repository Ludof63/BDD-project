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
-- utilizzare auto rollback on error
--i valori nelle variabili sono per test
BEGIN TRANSACTION;
DO $$
DECLARE  enteCod int;
DECLARE  cliCod  int;
DECLARE  nomeEnte varchar := 'Nibali, Ginese e Trupiano SPA'; 
DECLARE  indirizzoEnte varchar := 'Incrocio Fabrizia, 99 Piano 8 42024, Castelnovo Di Sotto (RE)';
DECLARE cliente char(17) := 'PJBBKX81R05M263F ';
BEGIN
        SELECT E.codEnte INTO enteCod
        FROM Ente E
        WHERE E.nome = nomeEnte and E.indirizzo = indirizzoEnte;
        
        SELECT C.codCli INTO cliCod
        FROM Carta_Cliente C
        WHERE C.titolare = cliente;
        
        UPDATE Autorizza
        SET dataInizio = current_date
        WHERE codEnte = enteCod and codCli = cliCod;
END$$;
COMMIT;



