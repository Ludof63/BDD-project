set search_path to socialMarket;

-- A:

-- Query_1
--prima
EXPLAIN ANALYZE 
SELECT CF
FROM Volontario
WHERE dataNascita > '1997-1-1';

--creazione piano fisico per query_1
CREATE INDEX idx_ord_dataNascita_volontario 
ON Volontario (dataNascita);

CLUSTER Volontario
USING idx_ord_dataNascita_volontario;

--dopo
EXPLAIN ANALYZE 
SELECT CF
FROM Volontario
WHERE dataNascita > '1997-1-1';




-- Query_2
--prima
EXPLAIN ANALYZE
SELECT codCli
FROM CARTA_CLIENTE
WHERE saldo < 5  and (età_16 >= 2 or età_64 >= 2);

--creazione piano fisico per query_2
CREATE INDEX idx_ord_saldo_carta_cliente
ON Carta_Cliente (saldo);

CLUSTER Carta_Cliente
USING idx_ord_saldo_carta_cliente;

--dopo
EXPLAIN ANALYZE
SELECT codCli
FROM CARTA_CLIENTE
WHERE saldo < 5  and (età_16 >= 2 or età_64 >= 2);




--Query_3
--prima
EXPLAIN ANALYZE
SELECT codUnità
FROM Prodotto JOIN Donazione ON Prodotto.codDonazione = Donazione.codDonazione
JOIN Trasporto ON Donazione.codTrasporto = Trasporto.codTrasporto
WHERE nCasse < 3 and (Donazione.dataOra BETWEEN'2022-05-01' AND  '2022-06-01');

--creazione piano fisico per query_3
CREATE INDEX idx_ord_ncasse_trasporto
ON Trasporto (nCasse);

CLUSTER Trasporto
USING idx_ord_ncasse_trasporto;

CREATE INDEX idx_ord_dataOra_Donazione
ON Donazione (dataOra);

CLUSTER Donazione
USING idx_ord_dataOra_Donazione;

--dopo
EXPLAIN ANALYZE
SELECT codUnità
FROM Prodotto JOIN Donazione ON Prodotto.codDonazione = Donazione.codDonazione
JOIN Trasporto ON Donazione.codTrasporto = Trasporto.codTrasporto
WHERE nCasse < 3 and (Donazione.dataOra BETWEEN'2022-05-01' AND  '2022-06-01');


-- B: transazione
-- utilizzare auto rollback on error
-- i valori nelle variabili sono per test
BEGIN TRANSACTION;
DO $$
DECLARE  enteCod int;
DECLARE  cliCod  int;
DECLARE  nomeEnte varchar := 'Seddio, Chindamo e Tognazzi Group'; 
DECLARE  indirizzoEnte varchar := 'Incrocio Antonini, 11 Appartamento 36
10054, Bousson (TO)';
DECLARE cliente char(17) := 'PAOEEP25H45L924Z';
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

GRANT SELECT ON turniCF,appuntamentoCF,trasportoCF,ricezioneCF TO roberto;

-- permesso di leggere e modificare su prodotto
GRANT SELECT,DELETE ON prodotto TO roberto;

-- permesso di inserire in scarico
GRANT INSERT ON scarico TO roberto;