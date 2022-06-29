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

#### Query_1

Alice, membro del social market, vuole organizzare una festa per tutti i volontari che hanno meno di 25 anni

```sql
SELECT CF
FROM Volontario
WHERE dataNascita > '1997-1-1';
```

#### Query_2

Marco, organizzatore del social market, necessita di sapere quali clienti hanno saldo "critico" (minore di 10 punti) e hanno nuclei familiari con almeno due elementi in una delle fasce "sensibili" (minori di 16 anni o maggiori di 64 anni).

```sql
SELECT codCli
FROM CARTA_CLIENTE
WHERE saldo < 5  and (età_16 >= 2 or età_64 >= 2);
```

#### Query_3

Anna, vuole sapere i punti totali spesi dai clienti dopo l'inizio di Maggio per prodotti non deperibili

```sql
SELECT SUM(costoPunti)
FROM Prodotto NATURAL JOIN Inventario
WHERE scadenza is NULL and dataOra >= '2022-5-1';
```

### Progetto fisico (b)

#### Query_1

Per la prima query del carico di lavoro scelto,  scegliamo di creare a suo supporto un indice ordinato clusterizzato (secondario) ad albero sull'attributo dataNascita della tabella VOLONTARIO, questo ci permetterà di effettuare una selezione di tipo range sull'attributo in modo più efficiente, lo creiamo clusterizzato perché per il nostro carico di lavoro è necessario creare su volontario un solo indice.

```sql

```

#### Query_2

Per la seconda query del carico di lavoro scelto, abbiamo scelto di creare a suo supporto un indice ordinato clusterizzato (secondario) ad albero sull'attributo saldo, poiché l'attributo saldo nella query_2 è il fattore booleano e quindi ci permette di selezionare più efficientemente rappresentando una condizione che se false rende falsa la selezione della tupla considerata, nel nostro caso possiamo percorrere l'indice e trovare il punto nel file da cui poi scorrere i blocchi nel senso inverso all'ordinamento, essendo clusterizzato  rendiamo così minimi gli accessi ai blocchi.

```sql

```

#### Query_3

Per la terza query delcarico di lavoro

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

Per questa transazione il livello di isolamento consigliato è il **READ COMMITED*** poiché non riteniamo di dover considerare anomalie di *phantom row* dato che le letture effettuate nella transazione coinvolgono singole tuple, riteniamo che acquisire i lock sulle intere tabelle sia eccessivo, inoltre anche le anomalie di *unreptable read* non ci interessano poiché non effettuiamo letture ripetute sulla stessa risorsa nel corso della transazione  

Il livello *REPETABLE READ* fa si che nella nostra transazione debbano essere acuisti i lock di scrittura (esclusivi) all'inizio e rilasciati al suo termine (COMMIT o ROLLBACK) mentre i lock condivisi (lettura) vengono acquisiti e rilasciati appena possibile, questo ci permette di evitare*:

- *lost update*: in caso una transazione concorrente leggesse  la tupla  X di AUTORIZZA prima che la nostra transazione la modifichi e poi dopo la nostra modifica (non avendola vista) la modificasse ulteriormente si perderebbe il nostro update, questo è evitato acquisendo il lock di scrittura (esclusivo) su X, una transazione concorrente non potrà acquisire un lock in lettura su X fino al COMMIT della transazione e quindi leggere in seguito un valore aggiornato.
- *dirty read:* in caso una transazione T2 concorrente volesse leggere la tupla che aggiorniamo X di AUTORIZZA, nel caso in cui la nostra transazione andasse in rollback e la lettura effettuata da T2 avvenisse prima del ROLLBACK, essa leggere un valore "sporco" e quindi acquisendo il lock su X in scrittura e rilasciandolo solo al ROLLBACK della transazione T2 potrebbe acquisire lock solo quando il valore di X è stato riprisitinato ad uno stato corretto.



## **Controllo dell'accesso (11)**
