-- ============================================================
-- GestioneCantieri — Dati di esempio
-- Coerenti con i mockup HTML (operai, cantieri, EVM, presenze)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- per crypt() / gen_salt()

BEGIN;

-- ── Pulizia dati smoke-test ───────────────────────────────────
DELETE FROM avanzamento_cantieri WHERE id_cantiere IN (SELECT id FROM cantieri WHERE nome='Cantiere Test');
DELETE FROM presenze             WHERE id_cantiere IN (SELECT id FROM cantieri WHERE nome='Cantiere Test');
DELETE FROM cantieri_operai      WHERE id_cantiere IN (SELECT id FROM cantieri WHERE nome='Cantiere Test');
DELETE FROM cantieri  WHERE nome = 'Cantiere Test';
DELETE FROM clienti   WHERE ragione_sociale = 'Test SpA';
DELETE FROM operai    WHERE codice_fiscale  = 'RSSMRA80A01H501Z';

-- ════════════════════════════════════════════════════════════
-- UTENTI
-- ════════════════════════════════════════════════════════════
INSERT INTO utenti (id, id_ruolo, username, email, password_hash, nome, cognome) VALUES
(uuidv7(), (SELECT id FROM ruoli WHERE nome='admin'),
 'admin.bianchi', 'admin@gestionecantieri.it',
 crypt('admin123', gen_salt('bf')), 'Alberto', 'Bianchi'),

(uuidv7(), (SELECT id FROM ruoli WHERE nome='capo_cantiere'),
 'g.russo', 'g.russo@gestionecantieri.it',
 crypt('capo456', gen_salt('bf')), 'Giulio', 'Russo'),

(uuidv7(), (SELECT id FROM ruoli WHERE nome='capo_cantiere'),
 'a.conti', 'a.conti@gestionecantieri.it',
 crypt('capo456', gen_salt('bf')), 'Andrea', 'Conti'),

(uuidv7(), (SELECT id FROM ruoli WHERE nome='operaio'),
 'm.ferrari', 'm.ferrari@gestionecantieri.it',
 crypt('op789', gen_salt('bf')), 'Marco', 'Ferrari'),

(uuidv7(), (SELECT id FROM ruoli WHERE nome='operaio'),
 'g.romano', 'g.romano@gestionecantieri.it',
 crypt('op789', gen_salt('bf')), 'Giuseppe', 'Romano');

-- ════════════════════════════════════════════════════════════
-- CLIENTI
-- ════════════════════════════════════════════════════════════
INSERT INTO clienti (id, ragione_sociale, tipo, piva, codice_fiscale, referente, email, telefono, pec, codice_sdi, indirizzo) VALUES
(uuidv7(), 'Famiglia Rossi',           'privato',       NULL,           'RSSLCU75A01F205Z', 'Luca Rossi',          'l.rossi@email.it',         '011 4521890', NULL,                              NULL,     'Via Roma 12, Torino'),
(uuidv7(), 'Condominio Verde Srl',     'azienda',       '03451280154',  NULL,              'Amm. Carla Ferretti', 'condverde@pec.it',         '02 7731200',  'condverde@legalmail.it',          'M5UXCR1', 'Viale Po 45, Milano'),
(uuidv7(), 'FabbricaTech SpA',         'azienda',       '01876540987',  NULL,              'Ing. Paolo Manzoni',  'pmanzoni@fabbricatech.it', '030 8874120', 'fabbricatech@pecaziendale.it',    'USAL8PV', 'Zona Industriale Est, Brescia'),
(uuidv7(), 'Banca Territoriale SpA',   'azienda',       '00654321098',  NULL,              'Dir. Anna Ferraro',   'ferraro@bancaterritoriale.it','06 3312980','bancaterritoriale@pec.it',       'T04ZHR3', 'Corso Italia 3, Roma'),
(uuidv7(), 'Mario Esposito',           'privato',       NULL,           'SPSMRA68D12H501K', 'Mario Esposito',      'm.esposito@email.it',       '081 5561234', NULL,                              NULL,     'Via Napoli 7, Napoli'),
(uuidv7(), 'Comune di Bergamo',        'ente_pubblico', '00218080163',  NULL,              'Arch. Sara Poli',     's.poli@comune.bergamo.it', '035 3991111', 'protocollo@pec.comune.bergamo.it','KQYDKQY', 'Piazza Matteotti 27, Bergamo');

-- ════════════════════════════════════════════════════════════
-- FORNITORI
-- ════════════════════════════════════════════════════════════
INSERT INTO fornitori (id, ragione_sociale, categoria, piva, referente, email, telefono, iban, indirizzo) VALUES
(uuidv7(), 'Cementi Rossi Srl',    'mat_edili',       '02341560321', 'Franco Rossi',    'ordini@cementirossi.it',    '011 6789012', 'IT60 X054 2811 1010 0000 0123 456', 'Via Industriale 5, Torino'),
(uuidv7(), 'ElettroImpianti Srl',  'elettrico',       '08765432109', 'Ing. Sara Neri',  's.neri@elettroimpianti.it', '02 4512340',  'IT45 H010 3001 0000 0001 2345 678', 'Via Volta 18, Milano'),
(uuidv7(), 'IdroService SpA',      'idraulico',       '05432198760', 'Tecn. Luca Bruni','l.bruni@idroservice.it',    '030 9871234', 'IT29 U033 5901 6001 0000 0654 321', 'Via Acquedotto 3, Brescia'),
(uuidv7(), 'Ferramenta Bianchi',   'ferramenta',      '01234567891', 'Mario Bianchi',   'info@ferrbianchi.it',       '011 3456789', 'IT76 B060 1601 6001 0000 0987 654', 'Corso Francia 88, Torino'),
(uuidv7(), 'Legnami del Nord Srl', 'legname',         '04321987650', 'Roberto Verdi',   'r.verdi@legnamidelnord.it', '0322 456789', 'IT12 A036 0901 6001 0000 0246 810', 'Via Boschi 12, Novara'),
(uuidv7(), 'NolMacchine Srl',      'nolo_macchinari', '07654321098', 'Dir. Elena Costa','noleggio@nolmacchine.it',   '02 6543210',  'IT58 D050 4111 1010 0000 0135 790', 'Via Macchinari 7, Sesto San Giovanni');

-- ════════════════════════════════════════════════════════════
-- CANTIERI
-- ════════════════════════════════════════════════════════════
INSERT INTO cantieri (id, nome, id_cliente, id_responsabile, indirizzo,
                      data_inizio, data_fine_prevista, stato, importo_contratto, tipo_lavori) VALUES
(uuidv7(), 'Villa Rossi',
 (SELECT id FROM clienti WHERE ragione_sociale='Famiglia Rossi'),
 (SELECT id FROM utenti  WHERE username='g.russo'),
 'Via Roma 12, Torino',
 '2025-01-06', '2025-12-31', 'in_corso', 280000.00, 'Ristrutturazione completa'),

(uuidv7(), 'Condominio Verde',
 (SELECT id FROM clienti WHERE ragione_sociale='Condominio Verde Srl'),
 (SELECT id FROM utenti  WHERE username='g.russo'),
 'Viale Po 45, Milano',
 '2025-01-06', '2026-06-30', 'in_corso', 380000.00, 'Nuova costruzione residenziale'),

(uuidv7(), 'FabbricaTech',
 (SELECT id FROM clienti WHERE ragione_sociale='FabbricaTech SpA'),
 (SELECT id FROM utenti  WHERE username='a.conti'),
 'Zona Industriale Est, Brescia',
 '2025-01-06', '2026-06-30', 'in_corso', 260000.00, 'Capannone industriale'),

(uuidv7(), 'Ristrutturazione Banca',
 (SELECT id FROM clienti WHERE ragione_sociale='Banca Territoriale SpA'),
 (SELECT id FROM utenti  WHERE username='a.conti'),
 'Corso Italia 3, Roma',
 '2026-09-01', '2027-03-31', 'pianificato', 150000.00, 'Ristrutturazione uffici'),

(uuidv7(), 'Palazzina Esposito',
 (SELECT id FROM clienti WHERE ragione_sociale='Mario Esposito'),
 (SELECT id FROM utenti  WHERE username='g.russo'),
 'Via Napoli 7, Napoli',
 '2024-03-01', '2025-02-28', 'completato', 95000.00, 'Nuova costruzione residenziale');

-- ════════════════════════════════════════════════════════════
-- OPERAI
-- ════════════════════════════════════════════════════════════
INSERT INTO operai (id, id_utente, nome, cognome, codice_fiscale, data_nascita, telefono, email, data_assunzione) VALUES
(uuidv7(), (SELECT id FROM utenti WHERE username='m.ferrari'),
 'Marco',    'Ferrari', 'FRRM RC80A01L219X', '1980-01-01', '333 1112233', 'm.ferrari@email.it',  '2018-03-01'),
(uuidv7(), (SELECT id FROM utenti WHERE username='g.romano'),
 'Giuseppe', 'Romano',  'RMNGPP75B15H501Y', '1975-02-15', '333 2223344', 'g.romano@email.it',   '2019-06-01'),
(uuidv7(), NULL,
 'Carlo',    'Fontana', 'FNTCRL82C20F205Z', '1982-03-20', '333 3334455', 'c.fontana@email.it',  '2020-01-15'),
(uuidv7(), NULL,
 'Stefano',  'Mancini', 'MNCSFN78D10A944W', '1978-04-10', '333 4445566', 's.mancini@email.it',  '2017-09-01'),
(uuidv7(), NULL,
 'Roberto',  'Villa',   'VLLRRT85E25L781K', '1985-05-25', '333 5556677', 'r.villa@email.it',    '2021-04-01'),
(uuidv7(), NULL,
 'Davide',   'Serra',   'SRRDVD90F30H294M', '1990-06-30', '333 6667788', 'd.serra@email.it',    '2022-02-01'),
(uuidv7(), NULL,
 'Luca',     'Bianchi', 'BNCLCU88G12D969P', '1988-07-12', '333 7778899', 'l.bianchi@email.it',  '2020-07-01'),
(uuidv7(), NULL,
 'Antonio',  'Greco',   'GRCNTN77H20G273R', '1977-08-20', '333 8889900', 'a.greco@email.it',    '2016-05-01');

-- ════════════════════════════════════════════════════════════
-- OPERAI_QUALIFICHE
-- ════════════════════════════════════════════════════════════
INSERT INTO operai_qualifiche (id_operaio, id_qualifica) VALUES
-- Ferrari: Muratore + Carpentiere
((SELECT id FROM operai WHERE cognome='Ferrari'), (SELECT id FROM qualifiche WHERE nome='Muratore')),
((SELECT id FROM operai WHERE cognome='Ferrari'), (SELECT id FROM qualifiche WHERE nome='Carpentiere')),
-- Romano: Muratore + Ferraiolo
((SELECT id FROM operai WHERE cognome='Romano'),  (SELECT id FROM qualifiche WHERE nome='Muratore')),
((SELECT id FROM operai WHERE cognome='Romano'),  (SELECT id FROM qualifiche WHERE nome='Ferraiolo')),
-- Fontana: Elettricista + Pittore
((SELECT id FROM operai WHERE cognome='Fontana'), (SELECT id FROM qualifiche WHERE nome='Elettricista')),
((SELECT id FROM operai WHERE cognome='Fontana'), (SELECT id FROM qualifiche WHERE nome='Pittore')),
-- Mancini: Idraulico
((SELECT id FROM operai WHERE cognome='Mancini'), (SELECT id FROM qualifiche WHERE nome='Idraulico')),
-- Villa: Gruista + Carpentiere
((SELECT id FROM operai WHERE cognome='Villa'),   (SELECT id FROM qualifiche WHERE nome='Gruista')),
((SELECT id FROM operai WHERE cognome='Villa'),   (SELECT id FROM qualifiche WHERE nome='Carpentiere')),
-- Serra: Muratore
((SELECT id FROM operai WHERE cognome='Serra'),   (SELECT id FROM qualifiche WHERE nome='Muratore')),
-- Bianchi: Piastrellista + Decoratore
((SELECT id FROM operai WHERE cognome='Bianchi'), (SELECT id FROM qualifiche WHERE nome='Piastrellista')),
((SELECT id FROM operai WHERE cognome='Bianchi'), (SELECT id FROM qualifiche WHERE nome='Decoratore')),
-- Greco: Muratore + Saldatore
((SELECT id FROM operai WHERE cognome='Greco'),   (SELECT id FROM qualifiche WHERE nome='Muratore')),
((SELECT id FROM operai WHERE cognome='Greco'),   (SELECT id FROM qualifiche WHERE nome='Saldatore'));

-- ════════════════════════════════════════════════════════════
-- CANTIERI_OPERAI
-- ════════════════════════════════════════════════════════════
INSERT INTO cantieri_operai (id, id_cantiere, id_operaio, data_inizio) VALUES
-- Villa Rossi: 6 operai
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), (SELECT id FROM operai WHERE cognome='Ferrari'), '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), (SELECT id FROM operai WHERE cognome='Romano'),  '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), (SELECT id FROM operai WHERE cognome='Fontana'), '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), (SELECT id FROM operai WHERE cognome='Mancini'), '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), (SELECT id FROM operai WHERE cognome='Villa'),   '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), (SELECT id FROM operai WHERE cognome='Serra'),   '2025-03-01'),
-- Condominio Verde: 4 operai
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), (SELECT id FROM operai WHERE cognome='Ferrari'), '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), (SELECT id FROM operai WHERE cognome='Romano'),  '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), (SELECT id FROM operai WHERE cognome='Bianchi'), '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), (SELECT id FROM operai WHERE cognome='Greco'),   '2025-01-06'),
-- FabbricaTech: 4 operai
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), (SELECT id FROM operai WHERE cognome='Fontana'), '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), (SELECT id FROM operai WHERE cognome='Mancini'), '2025-01-06'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), (SELECT id FROM operai WHERE cognome='Bianchi'), '2025-07-01'),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), (SELECT id FROM operai WHERE cognome='Greco'),   '2025-01-06');

-- ════════════════════════════════════════════════════════════
-- MEZZI
-- ════════════════════════════════════════════════════════════
INSERT INTO mezzi (id, nome, tipo, targa, numero_seriale, data_revisione, data_scadenza_assicurazione) VALUES
(uuidv7(), 'Escavatore CAT 320',   'escavatore',  NULL,       'SN-CAT320-2019-0042', '2026-08-15', '2026-07-31'),
(uuidv7(), 'Autocarro Iveco 75E',  'autocarro',   'TO 512 AB', NULL,                  '2026-06-10', '2026-11-30'),
(uuidv7(), 'Gru Liebherr 120 EC',  'gru',         NULL,       'SN-LBH120-2021-0018', '2026-05-28', '2026-09-30'),
(uuidv7(), 'Betoniera Euromix 350','betoniera',   NULL,       'SN-EUR350-2020-0091', '2027-01-20', '2027-02-28'),
(uuidv7(), 'Compressore Atlas 45', 'compressore', NULL,       'SN-ATL045-2022-0054', '2026-11-05', '2026-12-31');

-- ════════════════════════════════════════════════════════════
-- ASSEGNAZIONI_MEZZI
-- ════════════════════════════════════════════════════════════
INSERT INTO assegnazioni_mezzi (id, id_mezzo, id_cantiere, data_inizio, data_fine) VALUES
(uuidv7(), (SELECT id FROM mezzi WHERE nome='Escavatore CAT 320'),
            (SELECT id FROM cantieri WHERE nome='Villa Rossi'),     '2025-01-06', NULL),
(uuidv7(), (SELECT id FROM mezzi WHERE nome='Autocarro Iveco 75E'),
            (SELECT id FROM cantieri WHERE nome='Villa Rossi'),     '2025-01-06', '2025-10-31'),
(uuidv7(), (SELECT id FROM mezzi WHERE nome='Autocarro Iveco 75E'),
            (SELECT id FROM cantieri WHERE nome='Condominio Verde'),'2025-11-01', NULL),
(uuidv7(), (SELECT id FROM mezzi WHERE nome='Gru Liebherr 120 EC'),
            (SELECT id FROM cantieri WHERE nome='Condominio Verde'),'2025-03-01', NULL),
(uuidv7(), (SELECT id FROM mezzi WHERE nome='Betoniera Euromix 350'),
            (SELECT id FROM cantieri WHERE nome='FabbricaTech'),    '2025-01-06', '2025-06-30'),
(uuidv7(), (SELECT id FROM mezzi WHERE nome='Compressore Atlas 45'),
            (SELECT id FROM cantieri WHERE nome='FabbricaTech'),    '2026-01-05', NULL);

-- ════════════════════════════════════════════════════════════
-- MATERIALI
-- ════════════════════════════════════════════════════════════
INSERT INTO materiali (id, id_cantiere, id_fornitore, id_categoria, descrizione,
                       quantita, unita_misura, costo_unitario, stato, data_ordine, data_consegna_effettiva) VALUES
-- Villa Rossi
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
 (SELECT id FROM fornitori WHERE ragione_sociale='Cementi Rossi Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Calcestruzzo e malte'),
 'Calcestruzzo C25/30', 45.000, 'm³', 118.00, 'fatturato', '2025-02-10', '2025-02-25'),

(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
 (SELECT id FROM fornitori WHERE ragione_sociale='ElettroImpianti Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Impianti elettrici'),
 'Cavi FG7OR 3×2.5', 320.000, 'm', 4.20, 'consegnato', '2025-05-15', '2025-06-01'),

(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
 (SELECT id FROM fornitori WHERE ragione_sociale='Cementi Rossi Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Laterizi e blocchi'),
 'Blocchi Ytong 25cm', 1200.000, 'pz', 3.80, 'fatturato', '2025-06-20', '2025-07-05'),

(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
 (SELECT id FROM fornitori WHERE ragione_sociale='Ferramenta Bianchi'),
 (SELECT id FROM categorie_materiali WHERE nome='Finiture e pavimenti'),
 'Piastrelle 60×60 gres porcellanato', 180.000, 'm²', 38.50, 'ordinato',  '2026-05-10', NULL),

-- Condominio Verde
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'),
 (SELECT id FROM fornitori WHERE ragione_sociale='Cementi Rossi Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Acciaio e ferro'),
 'Tondino Fe B450C ø16', 8200.000, 'kg', 1.15, 'fatturato', '2025-01-15', '2025-02-01'),

(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'),
 (SELECT id FROM fornitori WHERE ragione_sociale='IdroService SpA'),
 (SELECT id FROM categorie_materiali WHERE nome='Impianti idraulici'),
 'Tubi multicstrato 20mm', 540.000, 'm', 6.80, 'consegnato', '2025-10-01', '2025-10-20'),

(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'),
 (SELECT id FROM fornitori WHERE ragione_sociale='Legnami del Nord Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Legname'),
 'Tavole abete 25×200mm', 95.000, 'm²', 28.00, 'ordinato',  '2026-04-20', NULL),

-- FabbricaTech
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'),
 (SELECT id FROM fornitori WHERE ragione_sociale='Cementi Rossi Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Acciaio e ferro'),
 'Travi HEB 200', 12400.000, 'kg', 1.32, 'fatturato', '2025-04-01', '2025-04-25'),

(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'),
 (SELECT id FROM fornitori WHERE ragione_sociale='Cementi Rossi Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Calcestruzzo e malte'),
 'Calcestruzzo C30/37 pompato', 220.000, 'm³', 135.00, 'fatturato', '2025-04-05', '2025-04-20'),

(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'),
 (SELECT id FROM fornitori WHERE ragione_sociale='NolMacchine Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Altro'),
 'Noleggio ponteggio per 6 mesi', 1.000, 'corpo', 8400.00, 'fatturato', '2025-08-01', '2025-08-10'),

(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'),
 (SELECT id FROM fornitori WHERE ragione_sociale='ElettroImpianti Srl'),
 (SELECT id FROM categorie_materiali WHERE nome='Impianti elettrici'),
 'Quadro elettrico industriale BT', 3.000, 'pz', 4200.00, 'consegnato', '2025-11-10', '2025-12-01');

-- ════════════════════════════════════════════════════════════
-- DOCUMENTI
-- ════════════════════════════════════════════════════════════
INSERT INTO documenti (id, id_cantiere, id_tipo, id_caricato_da, nome, tipo_file, data_emissione, data_scadenza) VALUES
(uuidv7(),
 (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
 (SELECT id FROM tipi_documento WHERE nome='Permesso di costruire'),
 (SELECT id FROM utenti WHERE username='admin.bianchi'),
 'Permesso costruire Villa Rossi', 'pdf', '2024-11-15', '2027-11-15'),

(uuidv7(),
 (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
 (SELECT id FROM tipi_documento WHERE nome='DURC'),
 (SELECT id FROM utenti WHERE username='admin.bianchi'),
 'DURC maggio 2026', 'pdf', '2026-05-01', '2026-07-31'),

(uuidv7(),
 (SELECT id FROM cantieri WHERE nome='Condominio Verde'),
 (SELECT id FROM tipi_documento WHERE nome='Piano di sicurezza'),
 (SELECT id FROM utenti WHERE username='g.russo'),
 'PSC Condominio Verde rev.2', 'pdf', '2025-01-03', '2026-12-31'),

(uuidv7(),
 (SELECT id FROM cantieri WHERE nome='Condominio Verde'),
 (SELECT id FROM tipi_documento WHERE nome='DURC'),
 (SELECT id FROM utenti WHERE username='admin.bianchi'),
 'DURC aprile 2026', 'pdf', '2026-04-01', '2026-06-15'),

(uuidv7(),
 (SELECT id FROM cantieri WHERE nome='FabbricaTech'),
 (SELECT id FROM tipi_documento WHERE nome='Contratto'),
 (SELECT id FROM utenti WHERE username='admin.bianchi'),
 'Contratto FabbricaTech SpA', 'pdf', '2024-12-10', NULL),

(uuidv7(),
 (SELECT id FROM cantieri WHERE nome='FabbricaTech'),
 (SELECT id FROM tipi_documento WHERE nome='DVR'),
 (SELECT id FROM utenti WHERE username='a.conti'),
 'DVR FabbricaTech 2025', 'pdf', '2025-01-03', '2026-05-20'),

(uuidv7(), NULL,
 (SELECT id FROM tipi_documento WHERE nome='DURC'),
 (SELECT id FROM utenti WHERE username='admin.bianchi'),
 'DURC aziendale marzo 2026', 'pdf', '2026-03-01', '2026-05-10'),

(uuidv7(),
 (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
 (SELECT id FROM tipi_documento WHERE nome='Collaudo'),
 (SELECT id FROM utenti WHERE username='g.russo'),
 'Collaudo strutture portanti', 'pdf', '2025-07-10', NULL);

-- ════════════════════════════════════════════════════════════
-- ATTIVITA_GANTT
-- ════════════════════════════════════════════════════════════

-- Villa Rossi
INSERT INTO attivita_gantt (id, id_cantiere, id_padre, nome,
    data_inizio_prevista, data_fine_prevista,
    data_inizio_effettiva, data_fine_effettiva,
    percentuale_completamento, budget_previsto, costo_effettivo, ordine)
VALUES
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), NULL,
 'Demolizioni',
 '2025-01-06','2025-02-28','2025-01-06','2025-03-14', 100, 18000, 19200, 1),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), NULL,
 'Struttura portante',
 '2025-02-03','2025-05-30','2025-03-17','2025-07-04', 100, 72000, 74100, 2),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), NULL,
 'Impianti',
 '2025-03-03','2025-07-31','2025-04-07','2025-08-22', 100, 48000, 49600, 3),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), NULL,
 'Murature interne',
 '2025-06-02','2025-09-30','2025-07-07','2025-10-31', 100, 42000, 43100, 4),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), NULL,
 'Finiture interne',
 '2025-08-04','2025-11-28','2025-09-01', NULL,          82, 68000, 58700, 5),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Villa Rossi'), NULL,
 'Collaudo finale',
 '2025-11-03','2025-12-31', NULL, NULL,                  0, 32000,     0, 6);

-- Condominio Verde
INSERT INTO attivita_gantt (id, id_cantiere, id_padre, nome,
    data_inizio_prevista, data_fine_prevista,
    data_inizio_effettiva, data_fine_effettiva,
    percentuale_completamento, budget_previsto, costo_effettivo, ordine)
VALUES
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), NULL,
 'Fondazioni',
 '2025-01-06','2025-04-30','2025-01-06','2025-04-28', 100, 55000, 52800, 1),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), NULL,
 'Struttura in c.a.',
 '2025-03-03','2025-08-29','2025-03-03','2025-08-25', 100, 95000, 91200, 2),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), NULL,
 'Involucro e copertura',
 '2025-07-07','2025-12-31','2025-07-07','2025-12-28', 100, 62000, 59500, 3),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), NULL,
 'Impianti',
 '2025-09-01','2026-02-28','2025-09-01', NULL,          70, 74000, 50100, 4),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), NULL,
 'Finiture',
 '2025-11-03','2026-05-29','2025-11-03', NULL,          35, 58000, 20000, 5),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='Condominio Verde'), NULL,
 'Aree comuni e sistemazione esterna',
 '2026-03-02','2026-06-30', NULL, NULL,                  5, 36000,  1800, 6);

-- FabbricaTech
INSERT INTO attivita_gantt (id, id_cantiere, id_padre, nome,
    data_inizio_prevista, data_fine_prevista,
    data_inizio_effettiva, data_fine_effettiva,
    percentuale_completamento, budget_previsto, costo_effettivo, ordine)
VALUES
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), NULL,
 'Scavi e fondazioni',
 '2025-01-06','2025-05-30','2025-01-06','2025-05-09', 100, 38000, 40100, 1),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), NULL,
 'Struttura in acciaio',
 '2025-04-07','2025-09-30','2025-04-07','2025-09-05', 100, 62000, 66800, 2),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), NULL,
 'Tamponature e copertura',
 '2025-08-04','2025-12-31','2025-08-04','2025-12-19', 100, 34000, 36500, 3),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), NULL,
 'Impianti industriali',
 '2025-09-01','2026-03-31','2025-09-01','2026-02-28', 100, 55000, 59100, 4),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), NULL,
 'Pavimentazioni industriali',
 '2026-01-05','2026-05-29','2026-01-05', NULL,          90, 38000, 36200, 5),
(uuidv7(), (SELECT id FROM cantieri WHERE nome='FabbricaTech'), NULL,
 'Test e collaudi',
 '2026-04-06','2026-06-30','2026-04-06', NULL,          30, 33000, 10100, 6);

-- ════════════════════════════════════════════════════════════
-- AVANZAMENTO CANTIERI (EVM snapshots — trend ultimi 3 mesi)
-- ════════════════════════════════════════════════════════════

-- Villa Rossi  BAC=280k  SPI≈0.89  CPI≈0.96
INSERT INTO avanzamento_cantieri (id, id_cantiere, data_rilevazione, bac, pv, ev, ac) VALUES
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),'2026-02-28',280000,224000,196000,203800),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),'2026-03-31',280000,236000,210000,218500),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),'2026-04-30',280000,248000,221000,230100),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),'2026-05-16',280000,257970,229600,239200);

-- Condominio Verde  BAC=380k  SPI=1.00  CPI=1.04
INSERT INTO avanzamento_cantieri (id, id_cantiere, data_rilevazione, bac, pv, ev, ac) VALUES
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Condominio Verde'),'2026-02-28',380000,171000,171000,164400),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Condominio Verde'),'2026-03-31',380000,185000,185000,177900),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Condominio Verde'),'2026-04-30',380000,196000,196000,188400),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Condominio Verde'),'2026-05-16',380000,209000,209000,200960);

-- FabbricaTech  BAC=260k  SPI=1.20  CPI=0.93
INSERT INTO avanzamento_cantieri (id, id_cantiere, data_rilevazione, bac, pv, ev, ac) VALUES
(uuidv7(),(SELECT id FROM cantieri WHERE nome='FabbricaTech'),'2026-02-28',260000,130000,156000,167700),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='FabbricaTech'),'2026-03-31',260000,140000,168000,180600),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='FabbricaTech'),'2026-04-30',260000,146670,176000,189200),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='FabbricaTech'),'2026-05-16',260000,151670,182000,195700);

-- ════════════════════════════════════════════════════════════
-- SETTIMANE_PRESENZE (settimane 17-20 / 2026 per Villa Rossi)
-- ════════════════════════════════════════════════════════════
INSERT INTO settimane_presenze (id, id_cantiere, anno, settimana, stato, id_chiuso_da, chiuso_at) VALUES
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),2026,17,'chiuso',
 (SELECT id FROM utenti WHERE username='admin.bianchi'),'2026-04-27 18:00:00+02'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),2026,18,'chiuso',
 (SELECT id FROM utenti WHERE username='admin.bianchi'),'2026-05-04 18:00:00+02'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),2026,19,'chiuso',
 (SELECT id FROM utenti WHERE username='admin.bianchi'),'2026-05-11 18:00:00+02'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),2026,20,'bozza', NULL, NULL);

-- ════════════════════════════════════════════════════════════
-- PRESENZE — Settimane 17-19, Villa Rossi (lun–ven, chiuse)
-- Ferrari, Romano, Fontana, Mancini: presente 8h/gg
-- Villa: ferie tutta la settimana
-- Serra: presente lun-gio, assente ven
-- ════════════════════════════════════════════════════════════

-- Settimana 17 (20-24 apr): tutti presenti lun-ven
INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione)
SELECT uuidv7(),
       (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
       o.id,
       (SELECT id FROM settimane_presenze sp
        WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi')
          AND sp.settimana=17 AND sp.anno=2026),
       d.data::DATE,
       'presente', 8.00, 0.00, 'chiuso'
FROM   operai o
CROSS JOIN (SELECT generate_series('2026-04-20'::DATE,'2026-04-24'::DATE,'1 day'::INTERVAL) AS data) d
WHERE  o.cognome IN ('Ferrari','Romano','Fontana','Mancini');

INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione)
SELECT uuidv7(),
       (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
       (SELECT id FROM operai WHERE cognome='Villa'),
       (SELECT id FROM settimane_presenze sp
        WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi')
          AND sp.settimana=17 AND sp.anno=2026),
       d.data::DATE, 'ferie', 0, 0, 'chiuso'
FROM   generate_series('2026-04-20'::DATE,'2026-04-26'::DATE,'1 day'::INTERVAL) AS d(data);

INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione)
SELECT uuidv7(),
       (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
       (SELECT id FROM operai WHERE cognome='Serra'),
       (SELECT id FROM settimane_presenze sp
        WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi')
          AND sp.settimana=17 AND sp.anno=2026),
       d.data::DATE,
       CASE WHEN d.data = '2026-04-24' THEN 'assente' ELSE 'presente' END,
       CASE WHEN d.data = '2026-04-24' THEN 0 ELSE 8 END, 0, 'chiuso'
FROM   generate_series('2026-04-20'::DATE,'2026-04-24'::DATE,'1 day'::INTERVAL) AS d(data);

-- Settimana 18 (27 apr-1 mag): Fontana gio straordinario 10h, altrimenti 8h
INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione)
SELECT uuidv7(),
       (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
       o.id,
       (SELECT id FROM settimane_presenze sp
        WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi')
          AND sp.settimana=18 AND sp.anno=2026),
       d.data::DATE, 'presente',
       CASE WHEN o.cognome='Fontana' AND d.data='2026-04-30' THEN 8 ELSE 8 END,
       CASE WHEN o.cognome='Fontana' AND d.data='2026-04-30' THEN 2 ELSE 0 END,
       'chiuso'
FROM   operai o
CROSS JOIN (SELECT generate_series('2026-04-27'::DATE,'2026-05-01'::DATE,'1 day'::INTERVAL) AS data) d
WHERE  o.cognome IN ('Ferrari','Romano','Fontana','Mancini','Serra');

INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione)
SELECT uuidv7(),
       (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
       (SELECT id FROM operai WHERE cognome='Villa'),
       (SELECT id FROM settimane_presenze sp
        WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi')
          AND sp.settimana=18 AND sp.anno=2026),
       d.data::DATE, 'ferie', 0, 0, 'chiuso'
FROM   generate_series('2026-04-27'::DATE,'2026-05-03'::DATE,'1 day'::INTERVAL) AS d(data);

-- Settimana 19 (4-8 mag): Romano mer malattia, altrimenti presente
INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione)
SELECT uuidv7(),
       (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
       o.id,
       (SELECT id FROM settimane_presenze sp
        WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi')
          AND sp.settimana=19 AND sp.anno=2026),
       d.data::DATE,
       CASE WHEN o.cognome='Romano' AND d.data='2026-05-06' THEN 'malattia' ELSE 'presente' END,
       CASE WHEN o.cognome='Romano' AND d.data='2026-05-06' THEN 0 ELSE 8 END,
       0, 'chiuso'
FROM   operai o
CROSS JOIN (SELECT generate_series('2026-05-04'::DATE,'2026-05-08'::DATE,'1 day'::INTERVAL) AS data) d
WHERE  o.cognome IN ('Ferrari','Romano','Fontana','Mancini','Serra');

INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione)
SELECT uuidv7(),
       (SELECT id FROM cantieri WHERE nome='Villa Rossi'),
       (SELECT id FROM operai WHERE cognome='Villa'),
       (SELECT id FROM settimane_presenze sp
        WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi')
          AND sp.settimana=19 AND sp.anno=2026),
       d.data::DATE, 'ferie', 0, 0, 'chiuso'
FROM   generate_series('2026-05-04'::DATE,'2026-05-10'::DATE,'1 day'::INTERVAL) AS d(data);

-- ════════════════════════════════════════════════════════════
-- PRESENZE — Settimana 20 (11-16 mag), Villa Rossi — bozza
-- Corrisponde esattamente al mockup di presenze.html
-- ════════════════════════════════════════════════════════════
INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione) VALUES
-- Ferrari: lun-ven presente 8h
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Ferrari'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-11','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Ferrari'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-12','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Ferrari'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-13','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Ferrari'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-14','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Ferrari'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-15','presente',8,0,'bozza'),
-- Romano: lun presente, mar presente, mer ferie, gio presente, ven presente
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Romano'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-11','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Romano'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-12','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Romano'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-13','ferie',0,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Romano'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-14','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Romano'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-15','presente',8,0,'bozza'),
-- Fontana: lun-mer 8h, gio 10h str, ven 8h
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Fontana'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-11','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Fontana'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-12','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Fontana'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-13','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Fontana'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-14','presente',8,2,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Fontana'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-15','presente',8,0,'bozza'),
-- Mancini: lun 8h, mar assente, mer-ven 8h
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Mancini'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-11','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Mancini'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-12','assente',0,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Mancini'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-13','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Mancini'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-14','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Mancini'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-15','presente',8,0,'bozza'),
-- Villa: ferie lun-sab
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Villa'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-11','ferie',0,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Villa'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-12','ferie',0,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Villa'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-13','ferie',0,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Villa'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-14','ferie',0,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Villa'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-15','ferie',0,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Villa'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-16','ferie',0,0,'bozza'),
-- Serra: lun-mar 8h, mer malattia, gio 8h (ven e sab mancanti = da registrare oggi)
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Serra'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-11','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Serra'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-12','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Serra'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-13','malattia',0,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Serra'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-14','presente',8,0,'bozza');

-- ── Registrazione oggi (sab 16 mag) da foglio giornaliero ────
INSERT INTO presenze (id, id_cantiere, id_operaio, id_settimana, data,
                      stato, ore_ordinarie, ore_straordinarie, stato_approvazione) VALUES
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Ferrari'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-16','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Romano'), (SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-16','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Fontana'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-16','presente',8,0,'bozza'),
(uuidv7(),(SELECT id FROM cantieri WHERE nome='Villa Rossi'),(SELECT id FROM operai WHERE cognome='Mancini'),(SELECT id FROM settimane_presenze sp WHERE sp.id_cantiere=(SELECT id FROM cantieri WHERE nome='Villa Rossi') AND sp.settimana=20 AND sp.anno=2026),'2026-05-16','presente',8,0,'bozza');
-- Serra sab 16: ancora mancante (da registrare nel mockup)

COMMIT;
