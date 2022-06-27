set search_path to socialMarket;

--B VISTA
-- Come ultimo mese intendiamo maggio nei nostri test

/*TEST VISTA
DROP VIEW riassuntoNucleoFamiliare
SELECT * FROM riassuntoNucleoFamiliare
*/

CREATE OR REPLACE VIEW riassuntoNucleoFamiliare (Famiglia, PuntiMensili, PuntiResidui, Autorizzati, Minori16, NumeroSpese,PuntiNonUtilizzati, PercReperibili,PercPerReperibili)  AS
SELECT Q1.famiglia,Q1.PuntiMensili, Q1.puntiResidui, Q1.autorizzati , Q1.età_16, 
Q2.numeroSpese, Q2.puntiNonUtilizzati, ((Q3.puntiPerReperibili* 100)/Q2.PuntiUtilizzati), (100 - ((Q3.puntiPerReperibili* 100)/Q2.PuntiUtilizzati))
FROM(
    SELECT Carta_Cliente.codCli as famiglia,PuntiMensili, PuntiMensili - COALESCE (SUM(costoPunti),0) as puntiResidui, età_16_64 + età_64 as Autorizzati , età_16
    FROM  Carta_Cliente NATURAL JOIN Autorizza LEFT JOIN
    (Prodotto  NATURAL JOIN INVENTARIO  JOIN Appuntamento ON Appuntamento.dataOra = Prodotto.dataOra and (Appuntamento.dataOra BETWEEN '2022-05-01' and '2022-05-30')) 
    ON Carta_cliente.codCli = Appuntamento.codCli
    GROUP BY(Carta_Cliente.codCli,PuntiMensili, età_64 , età_16, età_16_64)
)
as Q1 JOIN
(
    SELECT Carta_Cliente.codCli as famiglia, count(distinct Appuntamento.dataOra) as numeroSpese ,
    (12* PuntiMensili) - COALESCE (SUM(costoPunti),0) as PuntiNonUtilizzati, COALESCE (SUM(costoPunti),0) as PuntiUtilizzati
    FROM  Carta_Cliente NATURAL JOIN Autorizza LEFT JOIN
    (Prodotto  NATURAL JOIN INVENTARIO  JOIN Appuntamento ON Appuntamento.dataOra = Prodotto.dataOra and (Appuntamento.dataOra >(current_date - INTERVAL '12 months'))) 
    ON Carta_cliente.codCli = Appuntamento.codCli
    GROUP BY(Carta_Cliente.codCli,PuntiMensili)
)
as Q2
ON Q1.famiglia = Q2.famiglia
JOIN
(
    SELECT Carta_Cliente.codCli as famiglia, SUM(costoPunti) as puntiPerReperibili
    FROM  Carta_Cliente NATURAL JOIN Autorizza LEFT JOIN
    (Prodotto  NATURAL JOIN INVENTARIO  JOIN Appuntamento ON Appuntamento.dataOra = Prodotto.dataOra and (Appuntamento.dataOra >(current_date - INTERVAL '12 months'))) 
    ON Carta_cliente.codCli = Appuntamento.codCli
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


SELECT test('YLYBSG62L6KD442W', '2022-01-15', '2022-06-15')








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
In caso di INSERT dobbiamo solo verificare che il volntario per cui stiamo inserendo un nuovo turno 
non abbia turni con orari che si sovrappongo

*/



CREATE OR REPLACE FUNCTION checkTurniFun() RETURNS trigger AS 
$$ 
BEGIN 
 IF(
     ( SELECT Count(*) 
        FROM turno 
        WHERE CF = NEW.CF
        and (New.turnoInizio,NEW.turnoFine) OVERLAPS (turnoInizio and turnoFine)) > 0
    )
    NEW.turnoFine) BETWEEN turnoInizio and turnoFine
 THEN 
   RAISE EXCEPTION 'Questo volontario ha gia un turno assegnato in un orario sovrapposto'; 
 ELSE 
   RETURN NEW; 
  END IF;
END; 
$$ LANGUAGE plpgsql;

CREATE TRIGGER checkTurni 
BEFORE INSERT ON turno 
FOR EACH ROW 
EXECUTE FUNCTION checkTurniFun(); 











--E.B :
--abbiamo già usato questo trigger nello script di inizializzione per mantenere quantità prodotti in inventario valida
CREATE OR REPLACE FUNCTION funIncr() RETURNS trigger AS
$$
BEGIN
	UPDATE Inventario
	SET quantità = quantità+1
	WHERE codProdotto = NEW.codProdotto;
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
	UPDATE Inventario
	SET quantità = quantità-1
	WHERE codProdotto = OLD.codProdotto;
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
    IF(NEW.codProdotto <> OLD.codProdotto)
    THEN
        UPDATE Inventario
	    SET quantità = quantità-1
	    WHERE codProdotto = OLD.codProdotto;
        
        UPDATE Inventario
        SET quantità = quantità+1
        WHERE codProdotto = NEW.codProdotto;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER updateQnt
AFTER UPDATE ON Prodotto
FOR EACH ROW
EXECUTE FUNCTION funUpdateQnt();

