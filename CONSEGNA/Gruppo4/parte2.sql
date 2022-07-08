/*
PROGETTO: social market 
PARTE II

Capiaghi Ludovico, Elia Federico, Savchuk Iryna
Basi di Dati, team 4
Informatica - Unige anno 21/22
*/

--A : CREAZIONE SCHEMA  -----------------------------
-- Inizializzazione
create schema socialMarket;
set search_path to socialMarket;


--ENTE
CREATE TABLE Ente(
codEnte int PRIMARY KEY,
nome varchar(40) NOT NULL,
indirizzo varchar(70) NOT NULL
);


--CARTA_CLIENTE
CREATE TABLE Carta_Cliente(
codCli int PRIMARY KEY,
titolare char(17) NOT NULL,
saldo int NOT NULL CHECK(saldo >= 0),
età_16 int NOT NULL CHECK(età_16 >= 0),
età_16_64 int NOT NULL CHECK(età_16_64 >= 0),
età_64 int NOT NULL CHECK(età_64 >= 0),
UNIQUE(titolare)
);

CREATE TYPE sex as ENUM('M','F','Others');

-- FAMILIARE
CREATE TABLE Familiare(
cf char(17) PRIMARY KEY,
nome varchar(20) NOT NULL,
cognome varchar(20) NOT NULL,
dataNascita date NOT NULL,
luogoNascita varchar(40) NOT NULL,
telefono varchar(20) NOT NULL,
sesso sex NOT NULL,
codCli int REFERENCES Carta_Cliente (codCli) ON UPDATE CASCADE NOT NULL
);

ALTER TABLE CARTA_CLIENTE
    ADD FOREIGN KEY (titolare)
    REFERENCES  FAMILIARE (cf)
    DEFERRABLE INITIALLY DEFERRED;


-- VOLONTARIO
CREATE TABLE Volontario(
cf char(17) PRIMARY KEY,
nome varchar(20) NOT NULL,
cognome varchar(20) NOT NULL,
dataNascita date NOT NULL,
luogoNascita varchar(40) NOT NULL,
telefono varchar(20) NOT NULL,
sesso sex NOT NULL,
tipiVeicolo varchar(20),
tipiServizio varchar(40),
disponibilità varchar(50)
);

-- RICEZIONE
CREATE TABLE Ricezione(
codRiceve int PRIMARY KEY,
riceveInizio timestamp NOT NULL,
riceveFine timestamp NOT NULL,
CHECK(riceveInizio <= riceveFine)
);


-- INVENTARIO
CREATE TABLE Inventario(
codProdotto int PRIMARY KEY,
quantità integer NOT NULL CHECK(quantità >= 0),
tipoProdotto varchar(20) NOT NULL,
nomeProdotto varchar(20) NOT NULL,
costoPunti integer NOT NULL CHECK(costoPunti >= 0),
scadenzaAggiuntiva integer,
UNIQUE(nomeProdotto)
);

-- SCARICO
CREATE TABLE Scarico(
dataScarico date,
codProdotto int REFERENCES Inventario (codProdotto) ON UPDATE CASCADE,
quantità int NOT NULL CHECK(quantità > 0),
PRIMARY KEY(dataScarico, codProdotto)
);

-- DONATORE
CREATE TABLE Donatore(
cf char(17) PRIMARY KEY,
telefono varchar(20) NOT NULL,
nome varchar(40) NOT NULL,
cognome varchar(20)
);

--SPESA
CREATE TABLE Spesa(
codSpesa int PRIMARY KEY,
importo decimal(8,2) NOT NULL
);

-- COLLEGATO
CREATE TABLE Collegato(
codEnte int REFERENCES Ente (codEnte) ON UPDATE CASCADE,
cf char(17) REFERENCES Volontario (CF) ON UPDATE CASCADE,
PRIMARY KEY(codEnte,CF)
);

-- AUTORIZZA
CREATE TABLE Autorizza(
codEnte int REFERENCES Ente (codEnte) ON UPDATE CASCADE,
codCli int  REFERENCES Carta_Cliente (codCli) ON UPDATE CASCADE,
puntiMensili integer NOT NULL,
dataInizio date NOT NULL,
PRIMARY KEY(codEnte,codCli),
CHECK(puntiMensili >= 30 and puntiMensili <= 60)
);

-- APPUNTAMENTO
CREATE TABLE Appuntamento(
dataOra timestamp PRIMARY KEY,
saldoInizio integer NOT NULL,
saldoFine integer NOT NULL,
cf char(17) REFERENCES Familiare (CF) ON UPDATE CASCADE NOT NULL,
codCli int REFERENCES Carta_Cliente (codCli) ON UPDATE CASCADE NOT NULL,
CHECK(saldoFine <= saldoInizio)
);

--TRASPORTO
CREATE TABLE Trasporto(
codTrasporto int PRIMARY KEY,
trasportoInizio timestamp NOT NULL,
trasportoFine timestamp NOT NULL,
nCasse int NOT NULL,
sedeRitiro varchar(50) NOT NULL,
codRiceve int REFERENCES Ricezione (codRiceve) ON UPDATE CASCADE NOT NULL,
CHECK(trasportoInizio <= trasportoFine)
);

-- TURNO
CREATE TABLE Turno(
turnoInizio timestamp,
cf char(17) REFERENCES Volontario (CF) ON UPDATE CASCADE,
turnoFine timestamp NOT NULL,
dataOra timestamp REFERENCES Appuntamento (dataOra) ON UPDATE CASCADE,
codTrasporto int REFERENCES Trasporto (codTrasporto) ON UPDATE CASCADE,
codRiceve int REFERENCES Ricezione (codRiceve) ON UPDATE CASCADE,
PRIMARY KEY(turnoInizio, CF),
CHECK(turnoInizio <= turnoFine),
UNIQUE(dataOra)
);

-- DONAZIONE
CREATE TABLE Donazione(
codDonazione int PRIMARY KEY,   
dataOra timestamp NOT NULL,
importo decimal(8,2),
codTrasporto int REFERENCES Trasporto (codTrasporto),
cf char(17) REFERENCES Donatore (CF) ON UPDATE CASCADE,  
codSpesa int REFERENCES Spesa (codSpesa) ON UPDATE CASCADE,

CHECK (
    ((cf is null) and (codSpesa is not null))
    OR
    ((cf is not null) and (codSpesa is null))
),
CHECK(
    (importo is null)
    OR
    ((importo is not null) and (codTrasporto is null))
) 
);

-- PRODOTTO
CREATE TABLE Prodotto(
codUnità int PRIMARY KEY,   
scadenza date,
dataOra timestamp REFERENCES Appuntamento (dataOra) ON UPDATE CASCADE,
codProdotto int REFERENCES Inventario (codProdotto) ON UPDATE CASCADE NOT NULL,
codDonazione int REFERENCES Donazione (codDonazione) ON UPDATE CASCADE NOT NULL
);










--B : VISTA  -----------------------------
/*
Consegna:
La definizione di una vista che fornisca alcune informazioni riassuntive per ogni nucleo familiare: il numero di
punti mensili a disposizione, i punti residui per il mese corrente, il numero di persone autorizzate per l’accesso
al market, il numero di componenti totali e quelli appartenenti alla fascia d’età più bassa, il numero di
spese effettuate nell’ultimo anno, i punti eventualmente non utilizzati nell’ultimo anno, la percentuale di punti
utilizzata per prodotti deperibili e non deperibili nell’ultimo anno.
*/

-- Come ultimo mese intendiamo tutto il mese di maggio (per i nostri dati di test)

CREATE OR REPLACE VIEW riassuntoNucleoFamiliare (Famiglia, PuntiMensili, PuntiResidui, Autorizzati, Minori16, NumeroSpese,PuntiNonUtilizzati, PercReperibili,PercPerReperibili)  AS
SELECT Q1.famiglia,Q1.PuntiMensili, Q1.puntiResidui, Q1.autorizzati , Q1.età_16, 
Q2.numeroSpese, Q2.puntiNonUtilizzati, ((Q3.puntiPerReperibili* 100)/Q2.PuntiUtilizzati), (100 - ((Q3.puntiPerReperibili* 100)/Q2.PuntiUtilizzati))
FROM(
    SELECT Carta_Cliente.codCli as famiglia,PuntiMensili, PuntiMensili - COALESCE (SUM(costoPunti),0) as puntiResidui, età_16_64 + età_64 as Autorizzati , età_16
    FROM  Carta_Cliente NATURAL JOIN Autorizza NATURAL LEFT JOIN
    (Prodotto  NATURAL JOIN INVENTARIO  JOIN Appuntamento ON Appuntamento.dataOra = Prodotto.dataOra and (Appuntamento.dataOra BETWEEN '2022-05-01' and '2022-05-30')) 
    GROUP BY(Carta_Cliente.codCli,PuntiMensili, età_64 , età_16, età_16_64)
)
as Q1 JOIN
(
    SELECT Carta_Cliente.codCli as famiglia, count(distinct Appuntamento.dataOra) as numeroSpese ,
    (12* PuntiMensili) - COALESCE (SUM(costoPunti),0) as PuntiNonUtilizzati, COALESCE (SUM(costoPunti),0) as PuntiUtilizzati
    FROM  Carta_Cliente NATURAL JOIN Autorizza NATURAL LEFT JOIN
    (Prodotto  NATURAL JOIN INVENTARIO  JOIN Appuntamento ON Appuntamento.dataOra = Prodotto.dataOra and (Appuntamento.dataOra >(current_date - INTERVAL '12 months'))) 
    GROUP BY(Carta_Cliente.codCli,PuntiMensili)
)
as Q2
ON Q1.famiglia = Q2.famiglia
JOIN
(
    SELECT Carta_Cliente.codCli as famiglia, SUM(costoPunti) as puntiPerReperibili
    FROM  Carta_Cliente NATURAL JOIN Autorizza NATURAL LEFT JOIN
    (Prodotto  NATURAL JOIN INVENTARIO  JOIN Appuntamento ON Appuntamento.dataOra = Prodotto.dataOra and (Appuntamento.dataOra >(current_date - INTERVAL '12 months'))) 
    WHERE Scadenza is not null
    GROUP BY(Carta_Cliente.codCli,PuntiMensili)
)
as Q3
ON Q2.famiglia = Q3.famiglia;





--C : QUERY  -----------------------------

--C.A:
/*
Consegna:
determinare i nuclei familiari che, pur avendo punti assegnati, non hanno effettuato spese nell’ul-
timo mese.
*/
SELECT codCli
FROM  Carta_Cliente NATURAL JOIN Autorizza
WHERE codCli NOT IN(
    SELECT codCli
    FROM Prodotto NATURAL JOIN INVENTARIO NATURAL JOIN Appuntamento
    WHERE Appuntamento.dataOra BETWEEN '2022-05-01' and '2022-05-30'
);



--C.B:
/*
Consegna:
determinare le tipologie di prodotti acquistate nell’ultimo anno da tutte le famiglie (cioè ogni fa-
miglia ha acquistato almeno un prodotto di tale tipologia nell’ultimo anno).
*/
SELECT tipoProdotto
FROM Prodotto NATURAL JOIN Inventario NATURAL JOIN Appuntamento
WHERE Appuntamento.dataOra >(current_date - INTERVAL '12 months')
GROUP BY(tipoProdotto) 
HAVING COUNT(DISTINCT codCli) =
                    (SELECT COUNT(*)
                     FROM Carta_Cliente);


--C.C:
/*
Consegna:
determinare i prodotti che vengono scaricati (cioè non riescono ad essere distribuiti alle famiglie)
in quantitativo maggiore rispetto al quantitativo medio scaricato per prodotti della loro tipologia.
*/
SELECT I.codProdotto
FROM Scarico JOIN INVENTARIO I ON Scarico.codProdotto = I.codProdotto
GROUP BY (I.codProdotto, I.tipoProdotto)
HAVING COUNT(Scarico.quantità) >
            (SELECT COUNT(Scarico.quantità)/ COUNT(DISTINCT Scarico.codProdotto)
            FROM Scarico JOIN INVENTARIO ON Scarico.codProdotto = Inventario.codProdotto
            WHERE tipoProdotto = I.tipoProdotto);





----D : FUNZIONI  -----------------------------

--D.A:
/*
Consegna:
funzione che realizza lo scarico dall’inventario dei prodotti scaduti.
*/
CREATE OR REPLACE PROCEDURE doScarico() AS
$$
DECLARE 
temprow record;
BEGIN
    FOR temprow IN
        SELECT codProdotto as codP, COUNT(codUnità) as quantità
        FROM Prodotto NATURAL JOIN Inventario
        WHERE scadenza is not null  and dataOra is null 
        and (scadenzaAggiuntiva is null or  scadenza + interval '1 month' * scadenzaAggiuntiva < current_date)
        GROUP BY (codProdotto)
    LOOP
        INSERT INTO Scarico VALUES(current_date, temprow.codP, temprow.quantità);
    END LOOP;
      
    DELETE 
    FROM Prodotto
    WHERE codUnità IN (
        SELECT codUnità
        FROM Prodotto NATURAL JOIN Inventario
        WHERE scadenza is not null  and dataOra is null 
        and (scadenzaAggiuntiva is null or  scadenza + interval '1 month' * scadenzaAggiuntiva < current_date));
END;
$$ LANGUAGE plpgsql;


--Test
--CALL doScarico();


--D.B:
/*
Consegna:
funzione che corrisponde alla seguente query parametrica: dato un volontario e due date, deter-
minare i turni assegnati al volontario nel periodo compreso tra le due date.
*/
CREATE OR REPLACE FUNCTION turniInData(volontarioCF CHAR (17), startDate DATE, endDate DATE ) 
RETURNS TABLE (inizioDelTurno timeStamp)
AS
$$ 
BEGIN
    PERFORM(
    SELECT CF
    FROM Volontario
    WHERE CF = volontarioCF);
    
    IF(not found)
    THEN
        RAISE EXCEPTION 'Il volontario inserito non è presente';     
    END IF;

    RETURN QUERY(
    SELECT turnoInizio
    FROM turno 
    WHERE (turnoInizio BETWEEN startDate and endDate)
    and   (turnoFine BETWEEN startDate and endDate)
    and volontarioCF = CF); 
END; 
$$ LANGUAGE plpgsql;





--E : TRIGGER  -----------------------------
--E.A:
/*
Consegna:
verifica del vincolo che nessun volontario possa essere assegnato a più attività contemporanee
*/

/*
Sul nostro schema:
verifica del vincolo che nessun volontario possa essere assegnato a più attività contemporanee

-   In caso di INSERT dobbiamo solo verificare che il volntario per cui stiamo inserendo un nuovo turno 
    non abbia turni con orari che si sovrappongo
-   In caso di modifica dobbiamo verificare:
        - che non sia stato modificato l'ora del turno e che si soivrappomnga ad atri turni del volontario
        - che inzio e fine delle attività del turno siano comprese nel turno (in caso fossero state modificate)
*/
--INZIO TRIGGER A
CREATE OR REPLACE FUNCTION checkTurniFun() RETURNS trigger AS 
$$
DECLARE
riceveStart timestamp;
riceveEnd timestamp;
ric boolean;

traspStart timestamp;
traspEnd timestamp;
tr boolean;

appStart timestamp;
appEnd timestamp;
app boolean;
BEGIN
    -- prima verifica
    IF((
        SELECT COUNT(dataOra)
        FROM Turno T
        WHERE T.cf = NEW.cf AND (T.turnoInizio,T.turnoFine) OVERLAPS (NEW.turnoInizio, new.TurnoFine)
        ) > 0)
    THEN 
        RAISE EXCEPTION 'Il volontario ha già un turno tra questi orari';  
    END IF;
    
    
    -- seconda verifica
    IF(NEW.codRiceve is not null)
    THEN
        SELECT riceveInizio,riceveFine INTO riceveStart,riceveEnd
        FROM Ricezione
        WHERE Ricezione.codRiceve = NEW.codRiceve;
        ric  := true;  
        
        IF(not (riceveStart >= NEW.turnoInizio  and riceveEnd <= NEW.turnoFine))
        THEN
            RAISE EXCEPTION 'Ricezione va fuori dal turno'; 
        END IF;
        
    ELSE
        ric := false;
    END IF; 
    
    IF(NEW.codTrasporto is not null)
    THEN
        SELECT trasportoInizio,trasportoFine INTO traspStart,traspEnd
        FROM Trasporto
        WHERE Trasporto.codRiceve = NEW.codTrasporto;
        tr  := true;
        
        IF(not (traspStart >= NEW.turnoInizio  and traspEnd <= NEW.turnoFine))
        THEN
            RAISE EXCEPTION 'Trasporto va fuori dal turno'; 
        END iF;
    ELSE
        tr := false;
    END IF;
    
    IF(NEW.dataOra is not null)
    THEN
        appStart := NEW.dataOra;
        appEnd := NEW.dataOra + (20 * interval '1 minute');
        app  := true;
        
        IF(not (appStart >= NEW.turnoInizio  and appEnd <= NEW.turnoFine))
        THEN
            RAISE EXCEPTION 'Appuntamento va fuori dal turno'; 
        END IF;
    ELSE
        app := false;
    END IF;
    
    
    IF(app)
    THEN
        IF(tr)
        THEN
            IF(ric)
            THEN
                -- app ric tr
                IF( ((riceveStart,riceveEnd) OVERLAPS (traspStart,traspEnd))  or OVERLAPS ((appStart,appEnd) OVERLAPS (traspStart,traspEnd))
                or OVERLAPS ((appStart,appEnd) OVERLAPS (riceveStart,riceveEnd))
                  )
                THEN 
                   RAISE EXCEPTION 'Il volontario ha attivà sovrapposte come orari'; 
                ELSE
                    RETURN NEW;
                END IF;

            ELSE
                -- app tr
                IF((appStart,appEnd) OVERLAPS (traspStart,traspEnd))
                THEN 
                   RAISE EXCEPTION 'Il volontario ha attivà sovrapposte come orari'; 
                ELSE
                    RETURN NEW;
                END IF;
            END IF;
        ELSE
            IF(ric)
            THEN
                -- app ric
                IF( (appStart,appEnd) OVERLAPS (riceveStart,riceveEnd))
                THEN 
                   RAISE EXCEPTION 'Il volontario ha attivà sovrapposte come orari'; 
                ELSE
                    RETURN NEW;
                END IF;

            ELSE
               -- app
               RETURN NEW;
            END IF;     
        END IF;
        
    ELSE
        IF(tr)
        THEN
            IF(ric)
            THEN
                -- ric tr
                IF( (riceveStart,riceveEnd) OVERLAPS (traspStart,traspEnd) )
                THEN 
                   RAISE EXCEPTION 'Il volontario ha attivà sovrapposte come orari'; 
                ELSE
                    RETURN NEW;
                END IF;

            ELSE
                -- tr
                RETURN NEW;
            END IF;
        ELSE
            RETURN NEW;

        END IF;
    END IF;
        
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER checkTurni 
BEFORE INSERT or UPDATE ON turno 
FOR EACH ROW 
EXECUTE FUNCTION checkTurniFun();
--FINE TRIGGER A


--E.B:
/*
Consegna:
mantenimento della disponibilità corrente dei prodotti
*/

--abbiamo già usato questo trigger nello script di inizializzione per mantenere quantità consistente
--INZIO TRIGGER B
CREATE OR REPLACE FUNCTION funIncr() RETURNS trigger AS
$$
BEGIN
    IF (NEW.dataOra is null) 
    THEN
        UPDATE Inventario
        SET quantità = quantità+1
        WHERE codProdotto = NEW.codProdotto;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER incrQnt
AFTER INSERT ON Prodotto
FOR EACH ROW
EXECUTE FUNCTION funIncr();


CREATE OR REPLACE FUNCTION funDecr() RETURNS trigger AS
$$
BEGIN
    IF (OLD.dataOra is null)
    THEN
        UPDATE Inventario
        SET quantità = quantità-1
        WHERE codProdotto = OLD.codProdotto;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER decrQnt
AFTER DELETE ON Prodotto
FOR EACH ROW
EXECUTE FUNCTION funDecr();


CREATE OR REPLACE FUNCTION funUpdateQnt() RETURNS trigger AS
$$
BEGIN
    IF(NEW.codProdotto <> OLD.codProdotto and (NEW.dataOra is null ))
    THEN
        UPDATE Inventario
	    SET quantità = quantità-1
	    WHERE codProdotto = OLD.codProdotto;
        
        UPDATE Inventario
        SET quantità = quantità+1
        WHERE codProdotto = NEW.codProdotto;
    END IF;
    IF( (OLD.dataOra is null) and (NEW.dataOra is not null) )
    THEN
        UPDATE Inventario
	    SET quantità = quantità-1
	    WHERE codProdotto = OLD.codProdotto;

    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER updateQnt
AFTER UPDATE ON Prodotto
FOR EACH ROW
EXECUTE FUNCTION funUpdateQnt();
--FINE TRIGGER B





