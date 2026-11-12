-- Esercitazione 1 - Soluzione di riferimento
-- Schema AZIENDA della lezione 08 (slide 3), corrispondente allo schema COMPANY di Elmasri-Navathe, Fig. 5.5 e 5.7
DROP DATABASE IF EXISTS Azienda;
CREATE DATABASE Azienda CHARACTER SET utf8mb4;
USE Azienda;

-- CodiceFiscale e' CHAR(16): lunghezza fissa, contiene lettere, non si fanno calcoli.
-- CHAR non impone la lunghezza minima: serve il CHECK con CHAR_LENGTH (lezione 08, slide 14).
CREATE TABLE DIPENDENTE (
  Nome           VARCHAR(15)   NOT NULL,
  Cognome        VARCHAR(30)   NOT NULL,
  CodiceFiscale  CHAR(16),
  DataNascita    DATE,
  Indirizzo      VARCHAR(60),
  Sesso          CHAR(1),
  Stipendio      DECIMAL(10,2),
  CF_supervisore CHAR(16),
  N_dip          INT           NOT NULL DEFAULT 1,
  CONSTRAINT pk_dipendente   PRIMARY KEY (CodiceFiscale),
  CONSTRAINT chk_cf          CHECK (CHAR_LENGTH(CodiceFiscale) = 16),
  CONSTRAINT chk_sesso       CHECK (Sesso IN ('M', 'F')),
  CONSTRAINT chk_stipendio   CHECK (Stipendio > 0),
  CONSTRAINT fk_supervisore  FOREIGN KEY (CF_supervisore) REFERENCES DIPENDENTE(CodiceFiscale)
      ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE DIPARTIMENTO (
  Nome_dip      VARCHAR(20) NOT NULL,
  Numero_dip    INT,
  CF_direttore  CHAR(16)    NOT NULL,
  Data_inizio   DATE,
  CONSTRAINT pk_dipartimento PRIMARY KEY (Numero_dip),
  CONSTRAINT uq_nome_dip     UNIQUE (Nome_dip),
  CONSTRAINT fk_direttore    FOREIGN KEY (CF_direttore) REFERENCES DIPENDENTE(CodiceFiscale)
      ON UPDATE CASCADE
);

-- Il riferimento circolare: la FK DIPENDENTE -> DIPARTIMENTO si aggiunge dopo (slide 16)
ALTER TABLE DIPENDENTE ADD CONSTRAINT fk_dip_dipartimento
  FOREIGN KEY (N_dip) REFERENCES DIPARTIMENTO(Numero_dip) ON UPDATE CASCADE;

CREATE TABLE SEDI_DIPARTIMENTO (
  Numero_dip INT,
  Sede       VARCHAR(20),
  PRIMARY KEY (Numero_dip, Sede),
  FOREIGN KEY (Numero_dip) REFERENCES DIPARTIMENTO(Numero_dip) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE PROGETTO (
  Nome_progetto   VARCHAR(20) NOT NULL,
  Numero_progetto INT,
  Luogo           VARCHAR(20),
  Numero_dip      INT         NOT NULL,
  PRIMARY KEY (Numero_progetto),
  UNIQUE (Nome_progetto),
  FOREIGN KEY (Numero_dip) REFERENCES DIPARTIMENTO(Numero_dip) ON UPDATE CASCADE
);

CREATE TABLE LAVORA_SU (
  CF_dipendente   CHAR(16),
  Numero_progetto INT,
  Ore             DECIMAL(3,1),
  PRIMARY KEY (CF_dipendente, Numero_progetto),
  CONSTRAINT chk_ore CHECK (Ore >= 0),
  FOREIGN KEY (CF_dipendente)   REFERENCES DIPENDENTE(CodiceFiscale) ON UPDATE CASCADE,
  FOREIGN KEY (Numero_progetto) REFERENCES PROGETTO(Numero_progetto) ON UPDATE CASCADE
);

-- ON DELETE CASCADE: un parente a carico non ha senso senza il dipendente
CREATE TABLE PARENTE (
  CF_dipendente CHAR(16),
  Nome_parente  VARCHAR(15),
  Sesso         CHAR(1),
  DataNascita   DATE,
  Relazione     VARCHAR(10),
  PRIMARY KEY (CF_dipendente, Nome_parente),
  CONSTRAINT chk_sesso_parente CHECK (Sesso IN ('M', 'F')),
  FOREIGN KEY (CF_dipendente) REFERENCES DIPENDENTE(CodiceFiscale) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Parte B: utenti con privilegi minimi (da eseguire come root)
DROP USER IF EXISTS 'dev_azienda'@'localhost', 'analista'@'localhost';
CREATE USER 'dev_azienda'@'localhost' IDENTIFIED BY 'CambiaMi_2026!';
GRANT ALL PRIVILEGES ON Azienda.* TO 'dev_azienda'@'localhost';
CREATE USER 'analista'@'localhost' IDENTIFIED BY 'SoloLettura_2026!';
GRANT SELECT ON Azienda.* TO 'analista'@'localhost';
SHOW GRANTS FOR 'analista'@'localhost';
-- Collegato come analista, DROP TABLE PARENTE; produce ERROR 1142 (comando negato).

-- Domanda 1: il primo dipendente (Rossi, direttore della Direzione, N_dip = 1).
-- Soluzione A (scelta qui): disattivare temporaneamente i controlli. Rischio: se il dipartimento
-- non viene poi inserito, il dato resta incoerente e MySQL non lo ricontrolla alla riattivazione.
SET FOREIGN_KEY_CHECKS = 0;
INSERT INTO DIPENDENTE VALUES ('Mario', 'Rossi', 'RSSMRA70A01D548X', '1970-01-01',
  'Via Garibaldi 1, Ferrara', 'M', 55000, NULL, 1);
SET FOREIGN_KEY_CHECKS = 1;
INSERT INTO DIPARTIMENTO VALUES ('Direzione', 1, 'RSSMRA70A01D548X', '2015-06-19');
-- Soluzione B: rendere N_dip annullabile, inserire il dipendente con N_dip NULL, poi il dipartimento,
-- poi UPDATE del dipendente. Rischio: per un momento esiste un dipendente senza dipartimento,
-- e il NOT NULL va tolto per sempre. Lo standard SQL offre i vincoli DEFERRABLE, che MySQL non supporta.

-- Domanda 2: CF_supervisore ON DELETE SET NULL (il subordinato resta senza supervisore);
-- PARENTE.CF_dipendente ON DELETE CASCADE (il parente esiste solo in relazione al dipendente).
-- Domanda 3: 'analista'@'%' e' un account diverso, raggiungibile da qualunque host:
-- piu' superficie di attacco; se esistono entrambi, MySQL sceglie l'account con host piu' specifico.
SHOW TABLES;
