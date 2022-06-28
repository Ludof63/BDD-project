set search_path to socialMarket;

--B VISTA
-- Come ultimo mese intendiamo maggio (per i nostri dati "siamo a metà giugno quindi mese precedente")

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



--C QUERY

--C.A:
SELECT codCli
FROM  Carta_Cliente NATURAL JOIN Autorizza
WHERE codCli NOT IN(
    SELECT codCli
    FROM Prodotto NATURAL JOIN INVENTARIO NATURAL JOIN Appuntamento
    WHERE Appuntamento.dataOra BETWEEN '2022-05-01' and '2022-05-30'
);


--C.B:
SELECT tipo
FROM Prodotto NATURAL JOIN Inventario NATURAL JOIN Appuntamento
WHERE Appuntamento.dataOra >(current_date - INTERVAL '12 months')
GROUP BY(tipo) 
HAVING COUNT(DISTINCT codCli) =
                    (SELECT COUNT(*)
                     FROM Carta_Cliente);


--C.C:
SELECT codProdotto
FROM Prodotto NATURAL JOIN Scarico NATURAL JOIN INVENTARIO I
GROUP BY(codProdotto,tipo)
HAVING COUNT(codUnità) >
            (SELECT COUNT(codUnità)/COUNT(DISTINCT codProdotto)
            FROM Prodotto NATURAL JOIN Scarico NATURAL JOIN INVENTARIO
            WHERE tipo = I.tipo);






--D FUNZIONI

--D.A:
CREATE OR REPLACE PROCEDURE doScarico() AS
$$
BEGIN
    PERFORM(
    SELECT *
    FROM Scarico
    WHERE dataScarico = current_date);
    
    IF(found)
    THEN
        RAISE EXCEPTION 'Oggi è già presente uno scarico';    
    END IF;

	INSERT INTO Scarico VALUES (current_date);
    
    UPDATE Prodotto
    SET dataScarico = current_date
    FROM Inventario
    WHERE Prodotto.codProdotto = Inventario.codProdotto  and
    scadenza is not null  and dataOra is null and dataScarico is null 
    and (scadenzaAggiuntiva is null or  scadenza + interval '1 month' * scadenzaAggiuntiva < current_date) ;  
END;
$$ LANGUAGE plpgsql;

CALL doScarico();



--D.B:
CREATE OR REPLACE FUNCTION test(volontarioCF CHAR (17), startDate DATE, endDate DATE ) 
RETURNS void
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
    
END; 
$$ LANGUAGE plpgsql;


DROP FUNCTION turniInData
CREATE OR REPLACE FUNCTION turniInData(volontarioCF CHAR (17), startDate DATE, endDate DATE ) 
RETURNS TABLE (inizioDelTurno timeStamp , fineDelTurno timeStamp)
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
    SELECT turnoInizio,turnoFine
    FROM turno 
    WHERE (turnoInizio BETWEEN startDate and endDate)
    and   (turnoFine BETWEEN startDate and endDate)
    and volontarioCF = CF); 
END; 
$$ LANGUAGE plpgsql;

SELECT turniInData('YLYBSG62L6KD442W', '2022-01-15', '2022-06-15')

--E TRIGGER
--E.A:
/*
verifica del vincolo che nessun volontario possa essere assegnato a più attività contemporanee

-   In caso di INSERT dobbiamo solo verificare che il volntario per cui stiamo inserendo un nuovo turno 
    non abbia turni con orari che si sovrappongo
-   In caso di modifica dobbiamo verificare:
        - che non sia stato modificato l'ora del turno e che si soivrappomnga ad atri turni del volontario
        - che inzio e fine delle attività del turno siano comprese nel turno (in caso fossero state modificate)

*/


--INZIO TRIGGER A
CREATE OR REPLACE FUNCTION checkTurniInsertFun() RETURNS trigger AS 
$$ 
BEGIN
    IF((
        SELECT COUNT(dataOra)
        FROM Turno T
        WHERE T.cf = NEW.cf AND (T.turnoInizio,T.turnoFine) OVERLAPS (NEW.turnoInizio, new.TurnoFine)
       ) > 0)
    THEN 
        RAISE EXCEPTION 'Il volontario ha già un turno tra questi orari';  
    ELSE
        RETURN NEW; 
    END IF;
       
END; 
$$ LANGUAGE plpgsql;

CREATE TRIGGER checkTurni 
BEFORE INSERT ON turno 
FOR EACH ROW 
EXECUTE FUNCTION checkTurniInsertFun(); 


CREATE OR REPLACE FUNCTION checkTurniUpdateFun() RETURNS trigger AS 
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
    IF(NEW.turnoInizio <> OLD.turnoInizio OR NEW.turnoFine <> OLD.turnoFine)
    THEN
        IF((
            SELECT COUNT(dataOra)
            FROM Turno T
            WHERE T.cf = NEW.cf AND (T.turnoInizio,T.turnoFine) OVERLAPS (NEW.turnoInizio, new.TurnoFine)
            ) > 0)
        THEN 
            RAISE EXCEPTION 'Il volontario ha già un turno tra questi orari';  
        END IF;
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
        END iF;
        
    ELSE
        ric := false;
    END IF; 
    
    IF(NEW.codTrasporto is not null)
    THEN
        SELECT rtrasportoInizio,trasportoFine INTO traspStart,traspEnd
        FROM Trasportp
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
        appStart := dataOra;
        appEnd := dataOra + (20 * interval '1 minute');
        app  := true;
        
        IF(not (appStart >= NEW.turnoInizio  and appEnd <= NEW.turnoFine))
        THEN
            RAISE EXCEPTION 'Appuntamento va fuori dal turno'; 
        END iF;
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
                IF( ((riceveStart,riceveEnd) OVERLAPS (traspStar,traspEnd))  or OVERLAPS ((appStart,appEnd) OVERLAPS (traspStar,traspEnd))
                or OVERLAPS ((appStart,appEnd) OVERLAPS (riceveStar,riceveEnd))
                  )
                THEN 
                   RAISE EXCEPTION 'Il volontario ha attivà sovrapposte come orari'; 
                ELSE
                    RETURN NEW;
                END IF;

            ELSE
                -- app tr
                IF((appStart,appEnd) OVERLAPS (traspStar,traspEnd))
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
                IF( (appStart,appEnd) OVERLAPS (riceveStar,riceveEnd))
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
                IF( (riceveStart,riceveEnd) OVERLAPS (traspStar,traspEnd) )
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
BEFORE UPDATE ON turno 
FOR EACH ROW 
EXECUTE FUNCTION checkTurniUpdateFun();
--FINE TRIGGER A


UPDATE Turno
SET codTrasporto = 5
WHERE turnoInizio = '2022-03-25 15:30:41' and cf = 'YCYSNK31P04I594B'







--E.B:
--abbiamo già usato questo trigger nello script di inizializzione
--INZIO TRIGGER B
CREATE OR REPLACE FUNCTION funIncr() RETURNS trigger AS
$$
BEGIN
    IF (NEW.dataOra is null AND NEW.dataScarico is null) 
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
    IF (OLD.dataOra is null AND OLD.dataScarico is null)
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
    IF(NEW.codProdotto <> OLD.codProdotto and (NEW.dataOra is null AND NEW.dataScarico is null))
    THEN
        UPDATE Inventario
	    SET quantità = quantità-1
	    WHERE codProdotto = OLD.codProdotto;
        
        UPDATE Inventario
        SET quantità = quantità+1
        WHERE codProdotto = NEW.codProdotto;
    END IF;
    IF( (OLD.dataOra is null AND OLD.dataScarico is null) and (NEW.dataOra is not null OR NEW.dataScarico is not null) )
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



