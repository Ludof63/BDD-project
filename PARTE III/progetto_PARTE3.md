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

Il social market organizza una giornata della condivisione dove i clienti possono donare punt



## **Controllo dell'accesso (11)**
