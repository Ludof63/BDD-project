/*
PROGETTO: social market 
PARTE II

Capiaghi Ludovico, Elia Federico, Savchuk Iryna
Basi di Dati, team 4
Informatica - Unige anno 21/22
*/

-- Inizializzazione
create schema socialMarket;
set search_path to socialMarket;

--A : CREAZIONE SCHEMA

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
tipo varchar(20) NOT NULL,
nomeProdotto varchar(20) NOT NULL,
costoPunti integer NOT NULL CHECK(costoPunti >= 0),
scadenzaAggiuntiva integer,
UNIQUE(nomeProdotto)
);

-- SCARICO
CREATE TABLE Scarico(
dataScarico date PRIMARY KEY
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
dataScarico date REFERENCES Scarico (dataScarico) ON UPDATE CASCADE,
codDonazione int REFERENCES Donazione (codDonazione) ON UPDATE CASCADE NOT NULL,
CHECK (
    ((dataOra is null) and (dataScarico is not null))
    OR
    ((dataOra is not null) and (dataScarico is null))
    OR 
    ((dataOra is null) and (dataScarico is null)))

);





