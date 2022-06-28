# PROGETTO: social market 

# PARTE II

> **Capiaghi Ludovico, Elia Federico, Savchuk Iryna**
>
> **Basi di Dati, team 4**
>
> **Informatica - Unige anno 21/22**

[TOC]



## Creazione dello schema (4)

### Specifica dei vincoli e implementazione

| Nome Vincolo | Relazioni coinvolte (schema logico)             | Vincolo                                                      | Tipo vincolo | Implementato |
| ------------ | ----------------------------------------------- | ------------------------------------------------------------ | ------------ | ------------ |
| V1           | AUTORIZZA                                       | due autorizzazioni per la stessa carta_cliente devono avere *dataInizio* distanti almeno di 6 mesi | trigger      |              |
| V2           | APPUNTAMENTO - FAMILIARE                        | un familiare può prendere appuntamento solo se la sua età è maggiore di 16 anni | trigger      |              |
| V3           | FAMILIARE- titolare- nel_nucleo - CARTA_CLIENTE | Il familiare in relazione titolare con un carta_cliente deve essere in relazione con la carta_cliente attraverso la relazione nel_nucleo | trigger      |              |
| V4           | APPUNTAMENTO                                    | gli appuntamenti devono essere scaglionati di 20 minuti, di conseguenza non possono esserci due appuntamenti con la differenza minore di 20 minuti tra i rispettivi inizi (dataOra) | trigger      |              |
| V5           | APPUNTAMENTO                                    | *saldoFine* <= *saldoInizio*                                 | check        | SI           |
| V6           | TURNO                                           | *turnoInizio <= turnoFine*                                   | check        | SI           |
| V7           | TURNO - RICEZIONE                               | Un turno (volontario in uno slot temporale) in associazione riceve con ricezione deve avere *riceveInizio >= turnoInizio and riceveFine <= turnoFine* | trigger      |              |
| V8           | TURNO - TRASPORTO                               | Un turno in associazione trasporta con trasporto deve avere *trasportoInizio >= turnoInizio and riceveFine <= trasportoFine* | trigger      |              |
| V9           | TURNO - APPUNTAMENTO                            | Un turno in associazione supervisiona con appuntamento deve avere *dataOra >= turnoInizio and dataOra <= trasportoFine* | trigger      |              |
| V10          | TURNO - TRASPORTO - APPUNTAMENTO - RICEZIONE    | Per un turno non ci devono essere attività (svolte da volontario interessato) contemporanee ovvero sovrapposte temporalemente | trigger      |              |
| V11          | RICEZIONE                                       | *riceveInizio <= riceveFine*                                 | check        | SI           |
| V12          | TRASPORTO                                       | *trasportoInizio <= trasportoFine*                           | check        | SI           |
| V13          | PRODOTTO                                        | un prodotto se è in relazione con uno *scarico* (*scarta*) non può essere in relazione con un *appuntamento* (*acquista*) e viceversa. | check        | SI           |
| V14          | DENARO - SPESA                                  | la somma degli importi in *SPESA* è minore uguale alla somma degli importi di *DENARO* | trigger      |              |
| V15          | DONAZIONE                                       | una  donazione che è stata donata non può essere stata comprata e viceversa, quindi una donata può essere o in relazione con *donatore*(*dona*) o con *spesa*(*compra*) | check        | SI           |
| V16          | DONAZIONE                                       | una donazione in denaro (importo is not null) non può essere trasportata | check        | SI           |
| V17          | DONAZIONE- TRASPORTO                            | una donazione in relazione include con un trasporto deve soddisfare *dataOra <= trasportoInizio* | trigger      |              |
| V18          | RICEZIONE - TRASPORTO                           | un trasporto in relazione riceve_trasporto con una ricezione deve soddisfare trasportoInizio <= riceveInizio | trigger      |              |
| v19          | AUTORIZZA                                       | 30 <= puntiMensili <= 60                                     | check        | SI           |
| V20          | DONAZIONE                                       | Se una donazione è in relazione con compra non può essere in relazione con dona e viceversa | check        | SI           |

## Diagramma (5)

![Diagramma BD Social Market](.socialmarket.svg)
