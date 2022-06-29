set search_path to socialMarket;


-- A:

-- Query_1
SELECT CF
FROM Volontario
WHERE dataNascita > '1997-1-1';






-- Query_2
SELECT codCli
FROM CARTA_CLIENTE
WHERE saldo < 5  and (età_16 >= 2 or età_64 >= 2);



--Query_3
SELECT SUM(costoPunti)
FROM Prodotto NATURAL JOIN Appuntamento  NATURAL JOIN Inventario
WHERE scadenza is NULL and dataOra >= '2022-5-1';




-- B: transazione
-- utilizzare auto rollback on error
-- i valori nelle variabili sono per test
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



-- C: controllo dell'accesso

--ALICE gestore del social market
CREATE USER Alice password 'Alice';
GRANT USAGE ON SCHEMA socialmarket TO Alice WITH GRANT OPTION;
-- garantiamo ad Alice tutti i permessi
GRANT ALL PRIVILEGES ON SCHEMA socialmarket to Alice WITH GRANT OPTION;


-- ROBERTO: volontario del social market
INSERT INTO volontario  VALUES ('PGNRRT75D01H703D', 'Roberto', 'Paganini', '1975-04-01', 'Salerno', '333333333333', 'M', 'Wagon' , 'ricezione , supervisione , trasporto', 'Mercoledì mattina ');
CREATE USER Roberto PASSWORD 'roberto';

GRANT USAGE ON SCHEMA socialMarket TO roberto;

-- permesoo di leggere e modificare su prodotto
GRANT SELECT,UPDATE ON prodotto TO roberto;

-- permesso di inserire in scarico
GRANT INSERT ON scarico TO roberto;

-- permesso di leggere tutti i suoi turni, appuntamenti, trasporto, ricezione
CREATE VIEW turniCF AS
SELECT *
FROM turno
WHERE CF = 'PGNRRT75D01H703D';

CREATE VIEW appuntamentoCF AS
SELECT *
FROM appuntamento
WHERE dataora = (SELECT dataOra FROM turniCF);

CREATE VIEW trasportoCF AS
SELECT *
FROM trasporto
WHERE codTrasporto = (SELECT codTrasporto FROM turniCF);

CREATE VIEW ricezioneCF AS
SELECT *
FROM ricezione
WHERE codRiceve = (SELECT codRiceve FROM turniCF);

GRANT SELECT ON turniCF,appuntamentoByTurniCF,trasportoByTurniCF,ricezioneByTurniCF TO roberto;








SELECT C.relname as relazione, C.relpages as numeroPagine, C.reltuples as numeroTuple
FROM pg_namespace N JOIN pg_class C ON N.oid = C.relnamespace
WHERE  N.nspname = 'socialmarket' AND relname IN ('volontario','carta_cliente');





