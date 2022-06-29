# PROGETTO: social market 

# PARTE III

> **Capiaghi Ludovico, Elia Federico, Savchuk Iryna**
>
> **Basi di Dati, team 4**
>
> **Informatica - Unige anno 21/22**

[TOC]

## **Progetto fisico e sua valutazione (9)**

### Interrogazioni e carico di lavoro (a)

Alice, membro del social market, vuole organizzare una festa per tutti i volontari che hanno meno di 25 anni

```sql
SELECT CF
FROM Volontario
WHERE dataNascita > '1997-1-1';
```

Marco, organizzatore del social market, necessita di sapere quali clienti hanno saldo "critico" (minore di 10 punti) e hanno nuclei familiari con almeno due elementi in una delle fasce "sensibili" (minori di 16 anni o maggiori di 64 anni).

```sql
SELECT codCli
FROM CARTA_CLIENTE
WHERE saldo < 5  and (età_16 >= 2 or età_64 >= 2);
```

Anna, vuole sapere i punti totali spesi dai clienti dopo l'inizio di Maggio per prodotti non deperibili

```sql
SELECT SUM(costoPunti)
FROM Prodotto NATURAL JOIN Appuntamento  NATURAL JOIN Inventario
WHERE scadenza is NULL and dataOra >= '2022-5-1';
```



### Progetto fisico (b)



### Tuple e dimensioni dei blocchi (c)





### Descrizione piani di esecuzione (d)



## **Descrizione transazione (10)**

Un' ente vuole rinnovare l'autorizzazione per un determinato titolare *cliente* , e conosce il suo indirizzo, *indirizzoEnte*,  e il suo nome *indirizzoNome* ( che sono chiave univoca in ente), la transazione che implementa questa operazione deve effettuare:

- una lettura da ENTE per determinare codEnte dell'ente
- una lettura da CARTA_CLIENTE per determinare il codCli della tessera del cliente
- una scrittura (update) su AUTORIZZA per impostare la data dell'autorizzazione  alla data odierna per la tupla con  codEnte e codCli come chiave 

Il corrispondente codice SQL per la transazione è:

```sql
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
```





## **Controllo dell'accesso (11)**
