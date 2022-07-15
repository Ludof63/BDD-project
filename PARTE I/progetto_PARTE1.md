# PROGETTO: social market 

# PARTE I

> **Capiaghi Ludovico, Elia Federico, Savchuk Iryna**
>
> **Basi di Dati, team 4**
>
> **Informatica - Unige anno 21/22**

[TOC]



## **Requisiti ristrutturati (1)**

Abbiamo interpretato il dominio fornitoci nel seguente modo:

- Per i punti dei clienti, abbiamo usato numeri interi
- Memorizziamo gli enti che forniscono le autorizzazioni ( Servizi Sociali, Centri di Ascolto...) insieme agli enti che forniscono i volontari poiché riteniamo molti possano essere in comune, inoltre interpretiamo che un volontario possa essere associato a più enti
- ***Memorizziamo solo  l'autorizzazione corrente*** (per i clienti attivi quindi) e ***supponiamo che i punti mensili siano un'invariante  nel tempo per un cliente*** ,ogni mese il saldo della carta_cliente viene resettato ai punti mensili
- Memorizziamo i clienti come l'entità *CARTA_CLIENTE* a cui associamo poi tutti i familiari relativi, in *CARTA_CLIENTE* per riferirci al titolare di essa ( e relativi dati anagrafici) salviamo il *CF* del titolare. La carta cliente ha una durata per il periodo di 6 mesi da autorizza poi se si vuole rinnovare deve avere una nuova autorizzazione)
- Memorizziamo tutti i familiari per una carta_cliente ovvero tutti i familiari indipendemetemente dall'età del nulceo familiare
- La donazione può essere o in denaro o in merci
- Per i donatori, dividiamo in privati o aziende, e in aziende intendiamo anche gli esercizi commerciali che donano, un donatore può essere registrato anche se non ha ancora donato
- Utilizziamo l'entità SPESA per memorizzare le spese, ovvero l'utilizzo di denaro donato. 
- Abbiamo interpretato la ricezione di un gruppo di prodotti , attraverso la ricezione di uno o più traposrti (contiene una o più merci (gruppi di prodotti)) come il lavoro svolto da uno o più volontari per organizzare i prodotti nel magazzino, un trasporto deve essere ricevuto in una certa data-ora
- Per la data aggiuntiva di scadenza per i prodotti che deperibili che la memorizzano la intendiamo in numero di mesi aggiuntivi alla scadenza
- Lo scarico dei prodotti può avvenire una volta per giorno al massimo, e riteniamo opportuno memorizzare almeno la quantità di prodotti scaricati per tipo di prodotto perché lo riteniamo essere un'informazione importante per la futura organizzazione del market (abbiamo scelto questa mediazione di efficienza/informazione) , lo scarico è quindi identificato da una data e da un prodotto
- Memorizziamo i turni dei dipendenti in slot di tempo collegati a uno specifico volontario il lavoro che svolge lo deduciamo poi dalle diverse associazioni con i diversi lavori (trasporta - riceve - supervisiona), ***un volontario non può avere turni che si sovrappongono*** in termini intervalli di tempo, e ***un volontario può svolgere in un turno al massimo un'attività per ogni tipo di attività*** (quindi massimo tre attività (diverse))
  - *In caso un volontario dovesse eseguire attività dello stesso tipo in orari successivi si registrano turni successivi*

- Intendiamo il trasporto come un trasporto di una o più merci (donazioni diverse) mentre la ricezione è un lavoro che fanno più volontari su un trasporto

## **Progetto concettuale (2)**

### Diagramma ER (a)

![Social Market ER](.socialMarket.svg)

### Documentazione relativa ai domini degli attributi  (b)

#### Descrizione entità

- **ENTE** è un ente che fornisce autorizzazione e/o fornisce volontari. Un autorizzazione ha una durata di 6 mesi ed è caratterizzata da un numero di punti mensili e una data di inizio
- **FAMILIARE** è una persona del nucleo familiare relativo ad una carta_cliente.
- **CARTA_CLIENTE** rappresenta il "cliente" inteso come la carta relativa ad un cliente e quindi in relazione nel_nucleo per una o più familiari intese come "gruppo familiare". 
  - Un carta clienti ha *nel_nucleo* più familiari mentre un familiare è *titolare* di essa
  - In fasce d'età si memorizzano il numero di familiari per ogni fascia d'età per ottimizzare non dovendo ricercare su tutti i familiari di un nucleo  le età.

- **VOLONTARIO** rappresenta il volontario del market 
- **TURNO** è uno slot di tempo di 2 ore identificato da data e ora e da un volontario, in cui il volontario può fare delle attività che consisotno nel partcipare alle relazioni supervisione - trasporta - riceve (riceve un trasporto ad un orario che può essere diverso da quello indicato in trasporto)
- **APPUNTAMENTO** rappresenta un appuntamento preso da un familiare e riferito ad una carta_cliente (la stessa in relazione con il familiare che ha preso l'appuntamento) in una certa data e ora, intendiamo rappresentare l'inizio dell'appuntamento. Gli appuntamenti devono essere scaglionati di 20 minuti (15 durata di appuntamento + 5 minuti tra due appuntamenti) quindi utilizziamo come chiave {data,ora} poiché risultano diverse per appuntamenti diversi
- **RICEZIONE** indica per una certa data e ora il lavoro di uno o più volontari per riceve uno o più trasporti
- **TRASPORTO** indica un trasporto in una certa ora e data per una o più merci e coinvolge uno o più volontari
- **PRODOTTO** è il singolo prodotto presente nel market inteso come singola unità
- **INVENTARIO** rappresenta una collezione dello stesso "tipo di prodotto", contiene infatti quantità e ha attributi comuni a tutti i prodotti di quel "tipo", la scandeza aggiuntiva è intesa come la durata in mesi aggiuntiva alla scadenza (di un'unità)
- **DONAZIONE** è una donazione avvenuta che avviene in una data e ora e può essere in *MERCE* o *DENARO*
- **DONATORE** è un donatore del market che ha effettuato almeno una donazione e può essere un **AZIENDA** (inteso anche come esercizio commerciale) o un **PRIVATO** , il privato ha codiceFiscale CF  mentre l'azienda ha partita iva che identifichiamo comunque con CF
- **DENARO** rappresenta una donazione in denaro, caratterizzata da un importo
- **MERCE** è un insieme di prodotti che può essere donato da un donatore o acquista attraverso una spesa dal market, esso viene trasportato da uno o più volontari e ricevuto da uno o più volontari(organizzato nel market)
- **SCARICO** rappresenta uno scarico di un certo tipo di prodotti (la quantità) avvenuto in una certa data
- **SPESA** è un importo di denaro (raccolto dalle donazioni in denaro) per acquistare merce (prodotti) o per spese di gestione (se non è in relazione con merce)

#### Identificatori aggiuntivi

Gli identificatori primari sono deducibili dallo schema indichiamo per le entità che ne hanno, quelli secondari.

**ENTE:**

- {nome,indirizzo}

**CARTA_CLIENTE:**

- titolare

**INVENTARIO:**

- nomeProdotto

#### Domini attributi
<style>table th:first-of-type {
    width: 20%;
}
table th:nth-of-type(2) {
    width: 20%;
}
table th:nth-of-type(3) {
    width: 60%;
}
</style>
**ENTE:**

| Attributo | Dominio |
| :-------- | ------- |
| codEnte   | int     |
| nome      | string  |
| indirizzo | string  |

**autorizza:**

| Attributo    | Dominio      |
| :----------- | ------------ |
| puntiMensili | int  [30,60] |
| dataInizio   | date         |

**CARTA_CLIENTE:**

| Attributo | Dominio                                          |
| :-------- | :----------------------------------------------- |
| codCli    | int                                              |
| saldo     | int (positivo)                                   |
| fasceEtà  | int (positivo) x int (positivo) x int (positivo) |





**FAMILIARE:**

| Attributo    | Dominio               |
| :----------- | :-------------------- |
| CF           | string (16 caratteri) |
| luogoNascita | string                |
| cognome      | string                |
| nome         | string                |
| dataNascita  | date                  |
| telefono     | string                |
| sesso        | {'M','F','Others'}    |

**VOLONTARIO**:

| Attributo     | Dominio                                                                                  |
| :------------ | :--------------------------------------------------------------------------------------- |
| CF            | string (16 caratteri)                                                                    |
| luogoNascita  | string                                                                                   |
| cognome       | string                                                                                   |
| nome          | string                                                                                   |
| dataNascita   | date                                                                                     |
| telefono      | string                                                                                   |
| sesso         | {'M','F','Others'}                                                                       |
| tipiServizio  | string                                                                                   |
| disponibilità | {'Lunedì', 'Martedì', 'Mercoledì','Giovedì','Venerdì','Sabato','Domenica'} x time x time |
| tipoVeicolo   | string                                                                                   |

**TURNO:**

| Attributo   | Dominio   |
| :---------- | :-------- |
| turnoInizio | timestamp |
| turnoFine   | timestamp |

**APPUNTAMENTO**:

| Attributo   | Dominio        |
| :---------- | :------------- |
| dataOra     | timestamp      |
| saldoInizio | int (positivo) |
| saldoFine   | int (positivo) |

**RICEZIONE:**

| Attributo    | Dominio   |
| :----------- | :-------- |
| codRicezione | int       |
| riceveInizio | timestamp |
| riceveFine   | timestamp |

**TRASPORTO:**

| Attributo       | Dominio        |
| :-------------- | :------------- |
| codTrasporto    | int            |
| nCasse          | int (positivo) |
| trasportoInizio | timestamp      |
| trasportoFine   | timestamp      |
| sedeRitiro      | string         |

**PRODOTTO:**

| Attributo | Dominio |
| :-------- | :------ |
| codUnità  | int     |
| scadenza  | date    |

**INVENTARIO:**

| Attributo          | Dominio        |
| :----------------- | :------------- |
| codProdotto        | int            |
| quantità           | int (positivo) |
| tipoProdotto       | string         |
| nomeProdotto       | string         |
| costoPunti         | int (positivo) |
| scadenzaAggiuntiva | int (positivo) |

**DONAZIONE:**

| Attributo    | Dominio   |
| :----------- | :-------- |
| codDonazione | int       |
| dataOra      | timestamp |

**DONATORE:**

| Attributo | Dominio               |
| :-------- | :-------------------- |
| CF        | string (16 caratteri) |
| telefono  | string                |

**DENARO**:

| Attributo | Dominio         |
| :-------- | :-------------- |
| importo   | real (positivo) |





**SCARICO**:

| Attributo   | Dominio            |
| :---------- | :----------------- |
| dataScarico | date               |
| quantità    | int (positivo, >0) |

**AZIENDA**:

| Attributo   | Dominio |
| :---------- | :------ |
| nomeAzienda | string  |

**PRIVATO**:

| Attributo | Dominio |
| :-------- | :------ |
| cognome   | string  |
| nome      | string  |

**SPESA**:

| Attributo | Dominio         |
| :-------- | :-------------- |
| codSpesa  | int             |
| importo   | real (positivo) |

### Vincoli non esprimibili nel diagramma (c)


| Nome Vincolo | Entità - associazioni coinvolte                                                  | Vincolo                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------ | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1           | autorizza - CARTA_CLIENTE                                                        | due autorizzazioni per la stessa carta_cliente devono avere *dataInizio* distanti almeno di 6 mesi                                                                                                                                                                                                                                                                                                              |
| V2           | prende  - FAMILIARE                                                              | un familiare può prendere appuntamento solo se la sua età è maggiore di 16 anni                                                                                                                                                                                                                                                                                                                                 |
| V3           | FAMILIARE- titolare- nel_nucleo - CARTA_CLIENTE                                  | Il familiare in relazione titolare con un carta_cliente deve essere in relazione con la stessa carta_cliente attraverso la relazione nel_nucleo                                                                                                                                                                                                                                                                 |
| V4           | APPUNTAMENTO                                                                     | gli appuntamenti devono essere scaglionati di 20 minuti, di conseguenza non possono esserci due appuntamenti con la differenza minore di 20 minuti tra i rispettivi inizi (dataOra)                                                                                                                                                                                                                             |
| V5           | APPUNTAMENTO                                                                     | *saldoFine* <= *saldoInizio*                                                                                                                                                                                                                                                                                                                                                                                    |
| V6           | TURNO                                                                            | *turnoInizio <= turnoFine*                                                                                                                                                                                                                                                                                                                                                                                      |
| V7           | TURNO - riceve - RICEZIONE                                                       | Un turno (volontario in uno slot temporale) in associazione riceve con ricezione deve avere *riceveInizio >= turnoInizio and riceveFine <= turnoFine*                                                                                                                                                                                                                                                           |
| V8           | TURNO - trasporta - TRASPORTO                                                    | Un turno in associazione trasporta con trasporto deve avere *trasportoInizio >= turnoInizio and riceveFine <= trasportoFine*                                                                                                                                                                                                                                                                                    |
| V9           | TURNO - supervisiona - APPUNTAMENTO                                              | Un turno in associazione supervisiona con appuntamento deve avere *dataOra >= turnoInizio and dataOra <= trasportoFine*                                                                                                                                                                                                                                                                                         |
| V10          | TURNO - riceve - supervisiona - trasporta - TRASPORTO - APPUNTAMENTO - RICEZIONE | Per un turno non ci devono essere attività (svolte da volontario interessato) contemporanee ovvero sovrapposte temporalemente                                                                                                                                                                                                                                                                                   |
| V11          | RICEZIONE                                                                        | *riceveInizio <= riceveFine*                                                                                                                                                                                                                                                                                                                                                                                    |
| V12          | TRASPORTO                                                                        | *trasportoInizio <= trasportoFine*                                                                                                                                                                                                                                                                                                                                                                              |
| V13          | CARTA_CLIENTE - nel_nucleo - FAMILIARE                                           | Il numero di membri per fasce d'età dei familiari in relazione con una CARTA_CLIENTE deve coincidere con i  numeri per fasce d'età in fasce d'età                                                                                                                                                                                                                                                               |
| V14          | DENARO - SPESA                                                                   | la somma degli importi in *SPESA* è minore uguale alla somma degli importi di *DENARO*                                                                                                                                                                                                                                                                                                                          |
| V15          | MERCE                                                                            | una  merce che è stata donata non può essere stata comprata e viceversa, quindi una merce può essere o in relazione con *donatore*(*dona*) o con *spesa*(*compra*)                                                                                                                                                                                                                                              |
| V16          | MERCE - include - TRASPORTO                                                      | una merce in relazione include con un trasporto deve soddisfare *dataOra <= trasportoInizio*                                                                                                                                                                                                                                                                                                                    |
| V17          | RICEZIONE - riceve_trasporto - TRASPORTO                                         | un trasporto in relazione riceve_trasporto con una ricezione deve soddisfare trasportoInizio <= riceveInizio                                                                                                                                                                                                                                                                                                    |
| V18          | PRODOTTO - INVENTARIO - di_tipo  - acquista - APPUNTAMENTO                       | La quantità di un prodotto p in inventario deve essere il numero di unità (in prodotto) in relazione di_tipo con p non acquistati                                                                                                                                                                                                                                                                               |
| V19          | CARTA_CLIENTE - autorizza - APPUNTAMENTO - riferita                              | Il saldo a current_date in CARTA_CLIENTE deve corrispondere alla differenza tra PuntiMensili dell'autorizzazione della CARTA_CLIENTE e la somma delle differenze tra saldoInizio  e saldoFine degli appuntamenti in relazione riferita con la CARTA_CLIENTE, in particolare dovrà essere uguale al saldoFine dell'appuntamento in relazione con la CARTA_CLIENTE per cui la data è la più vicina a current_date |

### Gerarchie (d)

| Gerarchia | Descrizione                                                                                                     | Specifica             |
| --------- | --------------------------------------------------------------------------------------------------------------- | --------------------- |
| DONAZIONE | una donazione può essere specializzata in MERCE o DENARO a seconda che sia rispettivamente in prodotti o denaro | *totale ed esclusiva* |
| DONATORE  | un donatore può essere specializzato un PRIVATO o  un' AZIENDA                                                  | *totale ed esclusiva* |

## **Progetto logico (3)**

### Schema ER ristrutturato (a)

![Social Market Ristrutturato ER](.socialMarket_res.svg)

#### Modifiche ristrutturazione (b)

#### Scelte modifiche attributi

- **CARTA_CLIENTE** (attributo):
  - *fasceEtà*: abbiamo trasformato questo attributo multi-attributo in tre attributi corrispondenti a le tre classi di età, attributi:
    - età_<16: numero di familiari di età minore di 16 anni
    - età_16-64: numero di familiari di età compresa tra 16 e 64 anni
    - età_>64: numero di familiari di età maggiore di 64 anni

- **VOLONTARIO** (attributi): 
  - *disponibilità*: abbiamo trasformato questo attributo da multi-attributo multi valore ad un attributo singolo (opzionale) che utilizziamo come stringa che contiene le informazioni relative alla disponibilità di un volontario 
    - *Motivazioni:* non riteniamo per come interpretato il dominio che disponibilità  diventi a sua volta un'entità
  - *tipiServizio*: abbiamo trasformato questo attributo da un attributo multi-valore ad un attributo singolo (opzionale) che descrive a parole (stringa) i tipi di servizio di un volontario
    - *Motivazioni:* non riteniamo per come interpretato il dominio che tipiServizio  diventi a sua volta un'entità
  - *tipiVeicolo*: abbiamo trasformato questo attributo da un attributo multi-valore ad un attributo singolo (opzionale) che descrive a parole (stringa) i tipi di veicolo di cui il volontario dispone
    - *Motivazioni:* non riteniamo per come interpretato il dominio che tipiVeicolo  diventi a sua volta un'entità

#### Modifiche domini

Riportiamo solo le tabelle dei domini di relazioni di cui abbiamo modificato attributi durante relazione

**CARTA_CLIENTE:**

| Attributo  | Dominio        |
| :--------- | :------------- |
| codCli     | int            |
| saldo      | int (positivo) |
| età_<16    | int (positivo) |
| età_ 16-64 | int (positivo) |
| età_>64    | int (positivo) |

**VOLONTARIO**:

| Attributo     | Dominio               |
| :------------ | :-------------------- |
| CF            | string (16 caratteri) |
| luogoNascita  | string                |
| cognome       | string                |
| nome          | string                |
| dataNascita   | date                  |
| telefono      | string                |
| sesso         | {'M','F','Others'}    |
| tipiServizio  | string                |
| disponibilità | string                |
| tipoVeicolo   | string                |

### Modifiche  dei vincoli (c)

Riportiamo tabella con sole aggiunte e modifiche di vicoli dovute a ristrutturazione 

| Nome Vincolo | Entità - associazioni coinvolte        | Vincolo                                                                                                                                                                 |
| ------------ | -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V13          | CARTA_CLIENTE - nel_nucleo - FAMILIARE | Il numero di membri per fasce d'età dei familiari in relazione con una CARTA_CLIENTE deve coincidere con i  numeri per fasce d'età in età_<16, età_ 16-64, età_>64      |
| V15          | DONAZIONE                              | una  donazione che è stata donata non può essere stata comprata e viceversa, quindi una donata può essere o in relazione con *donatore*(*dona*) o con *spesa*(*compra*) |
| V16          | DONAZIONE- include - TRASPORTO         | una donazione in relazione include con un trasporto deve soddisfare *dataOra <= trasportoInizio*                                                                        |
| V20          | DONAZIONE - compra - dona              | Se una donazione è in relazione con compra non può essere in relazione con dona e viceversa                                                                             |
| V21          | DONAZIONE                              | una donazione in denaro non può essere trasportata                                                                                                                      |
| V22          | TURNO                                  | Non ci possono essere turni con lo stesso dataOra (dataOra  è unique)                                                                                                   |



### Scelte fatte per l'eliminazione di gerarchie (d)

- **DONATORE** (gerarchia): eliminazione entità figlie (azienda e privato) mettendo in donatore attributi opzionali *cognome* che identifica un privato mentre nome indica il nome per un privato o il nomeAzienda per un'azienda (cognome non presente)
  - *Motivazioni*: riteniamo le entità azienda e privato non centrali nello schema e riteniamo che con attributi opzionali indicati si possa risalire comunque alla suddivisone tra i due tipo
- **DONAZIONE** (gerarchia): eliminazione entità figlie (denaro e merce) mettendo in donatore attributi opzionali *importo* che identifica una donazione in denaro, se non è presente  implicitamente è una donazione in merci.
  - *Motivazioni*: riteniamo denaro e merce riducibili entrambe a donazione, non aggiungendo nuovi attributi e riuscendo, per le motivazioni precedenti a identificarle
  - *Modifica cardinalità*: la cardinalità dell'associazione dona da parte di DONAZIONE è stata modificata da (1,1) a (0,1) perché ora una donazione (merce in particolare) può essere acquistata tramite spesa e quindi non essere in relazione con un donatore

### Schema logico (e)

![Schema Logico Social Market](.schema_logico.png)

### Verifica qualità dello schema (f)

Per come abbiamo interpretato il dominio, per ogni relazione cerchiamo le dipendenze funzionali, chiavi verificando le qualità delle relazioni.

- **ENTE:**
  - Dipendenze funzionali:
    - $codEnte \rightarrow nome\; indirizzo $
    - $nome\; indirizzo  \rightarrow codEnte$
  - Chiavi e conclusioni:
    - Le chiavi della relazione *ENTE* sono quindi *{codEnte}* e *{nome, indirizzo}*
    - La relazione è in *BCNF* poiché  le dipendenzae funzionali presentano a sinistra una chiave della relazione
- **AUTORIZZA**
  - Dipendenze funzionali:
    - $codEnte\; codCli  \rightarrow puntiMensili\; dataInzio$
  - Chiavi e conclusioni:
    - Le chiave della relazione *FAMILIARE*  è quindi *{codEnte, codCli}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **FAMILIARE:**
  - Dipendenze funzionali:
    - $CF \rightarrow nome\; cognome\; dataNascita\; luogoNascita\; telefono\; sesso\; codCli\;$
  - Chiavi e conclusioni:
    - Le chiave della relazione *AUTORIZZA*  è quindi *{CF}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **CARTA_CLIENTE:**
  - Dipendenze funzionali:
    - $codCli \rightarrow titolare\; saldo\; età\_16\; età\_16\_64\; età\_64$
    - $titolare \rightarrow codCli\; saldo\; età\_16\; età\_16\_64\; età\_64$
  - Chiavi e conclusioni:
    - Le chiavi della relazione *CARTA_CLIENTE* sono quindi *{codCli}* e {titolare}
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **VOLONTARIO:**
  - Dipendenze funzionali:
    - $CF \rightarrow nome\; cognome\; dataNascita\; luogoNascita\; telefono\; sesso\; tipiServizio\; tipiVeicolo\; disponibilità\;$
  - Chiavi e conclusioni:
    - Le chiave della relazione *VOLONTARIO*  è quindi *{CF}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **TURNO:**
  - Dipendenze funzionali:
    - $turnoInizio\; CF \rightarrow turnoFine\; dataOra\; dataNascita\; codTrasporto\; codRiceve\;$
  - Chiavi e conclusioni:
    - Le chiave della relazione *TURNO*  è quindi *{turnoInizio, CF}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **APPUNTAMENTO:**
  - Dipendenze funzionali:
    - $dataOra \rightarrow saldoInizio\; codCli$
  - Chiavi e conclusioni:
    - Le chiave della relazione *APPUNTAMENTO*  è quindi *{dataOra}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **RICEVE:**
  - Dipendenze funzionali:
    - $codRiceve \rightarrow riceveInizio\; riceveFine$
  - Chiavi e conclusioni:
    - Le chiave della relazione *RICEVE*  è quindi *{codRiceve}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **TRASPORTO:**
  - Dipendenze funzionali:
    - $codTrasporto \rightarrow trasportoInizio\; trasportoFine\; nCasse\; sedeRitiro\; codRiceve\;$
  - Chiavi e conclusioni:
    - Le chiave della relazione *TRASPORTO* è quindi *{codTrasporto}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **PRODOTTO:**
  - Dipendenze funzionali:
    - $codUnità \rightarrow scadenza\; dataOra\; codProdotto\; codDonazione\;$
  - Chiavi e conclusioni:
    - Le chiave della relazione *PRODOTTO* è quindi *{codUnità}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **INVENTARIO:**
  - Dipendenze funzionali:
    - $codProdotto \rightarrow quantità\; tipo\; nomeProdotto\; costoPunti\; scadenzaAggiuntiva\;$
    - $nomeProdotto \rightarrow quantità\; tipo\; codProdotto\; costoPunti\; scadenzaAggiuntiva\;$
  - Chiavi e conclusioni:
    - Le chiavi della relazione *INVENTARIO* sono quindi *{codProdotto} *e *{nomeProdotto}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **DONAZIONE:**
  - Dipendenze funzionali:
    - $codDonazione \rightarrow dataOra\; importo\; codTrasporto\; CF\; codSpesa\;$
  - Chiavi e conclusioni:
    - Le chiave della relazione *DONAZIONE* è quindi *{codDonazione}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **DONATORE:**
  - Dipendenze funzionali:
    - $CF \rightarrow telefono\; nome\; cognome$
  - Chiavi e conclusioni:
    - Le chiave della relazione *DONAZIONE* è quindi *{CF}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **SCARICO:**
  - Dipendenze funzionali:
    - $dataScarico\; codProdotto \rightarrow quantità$
  - Chiavi e conclusioni:
    - Le chiave della relazione SCARICO è quindi *{dataScarico, codProdotto}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione
- **SPESA:**
  - Dipendenze funzionali:
    - $codSpesa \rightarrow importo$
  - Chiavi e conclusioni:
    - Le chiave della relazione *SPESA* è quindi *{codSpesa}*
    - La relazione è in *BCNF* poiché  la dipendenza funzionale presenta a sinistra la chiave della relazione

**Conclusione**: *essendo tutte le relazioni ottenute in BCNF allora lo schema è di qualità*.
