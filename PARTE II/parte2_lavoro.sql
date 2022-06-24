--B VISTA


DROP VIEW riassuntoNucleoFamiliare
SELECT * FROM riassuntoNucleoFamiliare



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


--D FUNZIONI



--E TRIGGER


--b : mantenimento della disponibilità corrente dei prodotti

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




CREATE OR REPLACE TRIGGER updateQnt
AFTER UPDATE ON Prodotto
FOR EACH ROW
EXECUTE FUNCTION funDecr();
