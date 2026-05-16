-- ============================================================
-- GestioneCantieri — Schema completo
-- PostgreSQL 18.3 — uuidv7 nativo
-- ============================================================

BEGIN;

-- ── RUOLI ────────────────────────────────────────────────────
CREATE TABLE ruoli (
    id          UUID        DEFAULT uuidv7() PRIMARY KEY,
    nome        TEXT        NOT NULL,
    descrizione TEXT,
    CONSTRAINT uq_ruoli_nome UNIQUE (nome)
);

-- ── UTENTI ───────────────────────────────────────────────────
CREATE TABLE utenti (
    id            UUID        DEFAULT uuidv7() PRIMARY KEY,
    id_ruolo      UUID        NOT NULL REFERENCES ruoli(id) ON DELETE RESTRICT,
    username      TEXT        NOT NULL,
    email         TEXT        NOT NULL,
    password_hash TEXT        NOT NULL,
    nome          TEXT        NOT NULL,
    cognome       TEXT        NOT NULL,
    attivo        BOOLEAN     NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- unicità case-insensitive via indice (UNIQUE inline non supporta espressioni)
CREATE UNIQUE INDEX uq_utenti_username ON utenti (LOWER(username));
CREATE UNIQUE INDEX uq_utenti_email    ON utenti (LOWER(email));

-- ── QUALIFICHE ───────────────────────────────────────────────
CREATE TABLE qualifiche (
    id          UUID DEFAULT uuidv7() PRIMARY KEY,
    nome        TEXT NOT NULL,
    descrizione TEXT,
    CONSTRAINT uq_qualifiche_nome UNIQUE (nome)
);

-- ── CLIENTI ──────────────────────────────────────────────────
CREATE TABLE clienti (
    id              UUID        DEFAULT uuidv7() PRIMARY KEY,
    ragione_sociale TEXT        NOT NULL,
    tipo            TEXT        NOT NULL CHECK (tipo IN ('privato','azienda','ente_pubblico')),
    piva            TEXT,
    codice_fiscale  TEXT,
    referente       TEXT,
    email           TEXT,
    telefono        TEXT,
    pec             TEXT,
    codice_sdi      TEXT,
    indirizzo       TEXT,
    note            TEXT,
    attivo          BOOLEAN     NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── FORNITORI ────────────────────────────────────────────────
CREATE TABLE fornitori (
    id              UUID        DEFAULT uuidv7() PRIMARY KEY,
    ragione_sociale TEXT        NOT NULL,
    categoria       TEXT        NOT NULL CHECK (categoria IN ('mat_edili','elettrico','idraulico','ferramenta','legname','nolo_macchinari','altro')),
    piva            TEXT,
    codice_fiscale  TEXT,
    referente       TEXT,
    email           TEXT,
    telefono        TEXT,
    iban            TEXT,
    indirizzo       TEXT,
    note            TEXT,
    attivo          BOOLEAN     NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── CANTIERI ─────────────────────────────────────────────────
CREATE TABLE cantieri (
    id                  UUID        DEFAULT uuidv7() PRIMARY KEY,
    id_cliente          UUID        NOT NULL REFERENCES clienti(id) ON DELETE RESTRICT,
    id_responsabile     UUID        REFERENCES utenti(id) ON DELETE SET NULL,
    nome                TEXT        NOT NULL,
    indirizzo           TEXT,
    data_inizio         DATE,
    data_fine_prevista  DATE,
    data_fine_effettiva DATE,
    stato               TEXT        NOT NULL DEFAULT 'pianificato'
                                    CHECK (stato IN ('pianificato','in_corso','sospeso','completato')),
    importo_contratto   NUMERIC(12,2),
    tipo_lavori         TEXT,
    note                TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── OPERAI ───────────────────────────────────────────────────
CREATE TABLE operai (
    id              UUID        DEFAULT uuidv7() PRIMARY KEY,
    id_utente       UUID        REFERENCES utenti(id) ON DELETE SET NULL,
    nome            TEXT        NOT NULL,
    cognome         TEXT        NOT NULL,
    codice_fiscale  TEXT,
    data_nascita    DATE,
    telefono        TEXT,
    email           TEXT,
    data_assunzione DATE,
    attivo          BOOLEAN     NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_operai_cf UNIQUE (codice_fiscale)
);

-- ── OPERAI_QUALIFICHE (junction) ─────────────────────────────
CREATE TABLE operai_qualifiche (
    id_operaio        UUID NOT NULL REFERENCES operai(id) ON DELETE CASCADE,
    id_qualifica      UUID NOT NULL REFERENCES qualifiche(id) ON DELETE CASCADE,
    data_acquisizione DATE,
    data_scadenza     DATE,
    PRIMARY KEY (id_operaio, id_qualifica)
);

-- ── CANTIERI_OPERAI (junction) ───────────────────────────────
CREATE TABLE cantieri_operai (
    id          UUID DEFAULT uuidv7() PRIMARY KEY,
    id_cantiere UUID NOT NULL REFERENCES cantieri(id) ON DELETE CASCADE,
    id_operaio  UUID NOT NULL REFERENCES operai(id)  ON DELETE CASCADE,
    data_inizio DATE NOT NULL,
    data_fine   DATE,
    CONSTRAINT uq_cantieri_operai UNIQUE (id_cantiere, id_operaio, data_inizio)
);

-- ── SETTIMANE_PRESENZE ────────────────────────────────────────
CREATE TABLE settimane_presenze (
    id           UUID        DEFAULT uuidv7() PRIMARY KEY,
    id_cantiere  UUID        NOT NULL REFERENCES cantieri(id) ON DELETE CASCADE,
    anno         INTEGER     NOT NULL,
    settimana    INTEGER     NOT NULL CHECK (settimana BETWEEN 1 AND 53),
    stato        TEXT        NOT NULL DEFAULT 'bozza'
                             CHECK (stato IN ('bozza','confermato','chiuso')),
    id_chiuso_da UUID        REFERENCES utenti(id) ON DELETE SET NULL,
    chiuso_at    TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_settimane UNIQUE (id_cantiere, anno, settimana)
);

-- ── PRESENZE ─────────────────────────────────────────────────
CREATE TABLE presenze (
    id                 UUID          DEFAULT uuidv7() PRIMARY KEY,
    id_cantiere        UUID          NOT NULL REFERENCES cantieri(id)          ON DELETE CASCADE,
    id_operaio         UUID          NOT NULL REFERENCES operai(id)            ON DELETE CASCADE,
    id_settimana       UUID          REFERENCES settimane_presenze(id)         ON DELETE SET NULL,
    id_registrato_da   UUID          REFERENCES utenti(id)                     ON DELETE SET NULL,
    id_approvato_da    UUID          REFERENCES utenti(id)                     ON DELETE SET NULL,
    data               DATE          NOT NULL,
    stato              TEXT          NOT NULL DEFAULT 'presente'
                                     CHECK (stato IN ('presente','assente','ferie','malattia','permesso')),
    ore_ordinarie      NUMERIC(4,2)  NOT NULL DEFAULT 0 CHECK (ore_ordinarie    >= 0),
    ore_straordinarie  NUMERIC(4,2)  NOT NULL DEFAULT 0 CHECK (ore_straordinarie >= 0),
    stato_approvazione TEXT          NOT NULL DEFAULT 'bozza'
                                     CHECK (stato_approvazione IN ('bozza','confermato','chiuso')),
    note               TEXT,
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT uq_presenze UNIQUE (id_cantiere, id_operaio, data)
);

-- ── MEZZI ────────────────────────────────────────────────────
CREATE TABLE mezzi (
    id                          UUID        DEFAULT uuidv7() PRIMARY KEY,
    nome                        TEXT        NOT NULL,
    tipo                        TEXT        NOT NULL CHECK (tipo IN ('autocarro','escavatore','gru','betoniera','compressore','sollevatore','altro')),
    targa                       TEXT,
    numero_seriale              TEXT,
    data_revisione              DATE,
    data_scadenza_assicurazione DATE,
    note                        TEXT,
    attivo                      BOOLEAN     NOT NULL DEFAULT true,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── ASSEGNAZIONI_MEZZI ────────────────────────────────────────
CREATE TABLE assegnazioni_mezzi (
    id          UUID        DEFAULT uuidv7() PRIMARY KEY,
    id_mezzo    UUID        NOT NULL REFERENCES mezzi(id)    ON DELETE CASCADE,
    id_cantiere UUID        NOT NULL REFERENCES cantieri(id) ON DELETE CASCADE,
    data_inizio DATE        NOT NULL,
    data_fine   DATE,
    note        TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── CATEGORIE_MATERIALI ───────────────────────────────────────
CREATE TABLE categorie_materiali (
    id   UUID DEFAULT uuidv7() PRIMARY KEY,
    nome TEXT NOT NULL,
    CONSTRAINT uq_categorie_materiali UNIQUE (nome)
);

-- ── MATERIALI ────────────────────────────────────────────────
CREATE TABLE materiali (
    id                      UUID          DEFAULT uuidv7() PRIMARY KEY,
    id_cantiere             UUID          NOT NULL REFERENCES cantieri(id)           ON DELETE CASCADE,
    id_fornitore            UUID          REFERENCES fornitori(id)                   ON DELETE SET NULL,
    id_categoria            UUID          REFERENCES categorie_materiali(id)         ON DELETE SET NULL,
    descrizione             TEXT          NOT NULL,
    quantita                NUMERIC(10,3) NOT NULL CHECK (quantita > 0),
    unita_misura            TEXT          NOT NULL,
    costo_unitario          NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0),
    stato                   TEXT          NOT NULL DEFAULT 'ordinato'
                                          CHECK (stato IN ('ordinato','consegnato','fatturato','annullato')),
    data_ordine             DATE,
    data_consegna_prevista  DATE,
    data_consegna_effettiva DATE,
    note                    TEXT,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ── TIPI_DOCUMENTO ───────────────────────────────────────────
CREATE TABLE tipi_documento (
    id   UUID DEFAULT uuidv7() PRIMARY KEY,
    nome TEXT NOT NULL,
    CONSTRAINT uq_tipi_documento UNIQUE (nome)
);

-- ── DOCUMENTI ────────────────────────────────────────────────
CREATE TABLE documenti (
    id             UUID        DEFAULT uuidv7() PRIMARY KEY,
    id_cantiere    UUID        REFERENCES cantieri(id)    ON DELETE SET NULL,
    id_tipo        UUID        NOT NULL REFERENCES tipi_documento(id) ON DELETE RESTRICT,
    id_caricato_da UUID        REFERENCES utenti(id)      ON DELETE SET NULL,
    nome           TEXT        NOT NULL,
    descrizione    TEXT,
    percorso_file  TEXT,
    tipo_file      TEXT,
    data_emissione DATE,
    data_scadenza  DATE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── ATTIVITA_GANTT ────────────────────────────────────────────
CREATE TABLE attivita_gantt (
    id                        UUID          DEFAULT uuidv7() PRIMARY KEY,
    id_cantiere               UUID          NOT NULL REFERENCES cantieri(id)     ON DELETE CASCADE,
    id_padre                  UUID          REFERENCES attivita_gantt(id)        ON DELETE CASCADE,
    nome                      TEXT          NOT NULL,
    data_inizio_prevista      DATE          NOT NULL,
    data_fine_prevista        DATE          NOT NULL,
    data_inizio_effettiva     DATE,
    data_fine_effettiva       DATE,
    percentuale_completamento INTEGER       NOT NULL DEFAULT 0
                                            CHECK (percentuale_completamento BETWEEN 0 AND 100),
    budget_previsto           NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (budget_previsto  >= 0),
    costo_effettivo           NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (costo_effettivo  >= 0),
    ordine                    INTEGER       NOT NULL DEFAULT 0,
    created_at                TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_date_gantt CHECK (data_fine_prevista >= data_inizio_prevista)
);

-- ── AVANZAMENTO_CANTIERI (EVM snapshots) ─────────────────────
CREATE TABLE avanzamento_cantieri (
    id               UUID          DEFAULT uuidv7() PRIMARY KEY,
    id_cantiere      UUID          NOT NULL REFERENCES cantieri(id) ON DELETE CASCADE,
    data_rilevazione DATE          NOT NULL,
    bac              NUMERIC(12,2) NOT NULL CHECK (bac > 0),  -- Budget at Completion
    pv               NUMERIC(12,2) NOT NULL CHECK (pv  >= 0), -- Planned Value
    ev               NUMERIC(12,2) NOT NULL CHECK (ev  >= 0), -- Earned Value
    ac               NUMERIC(12,2) NOT NULL CHECK (ac  >= 0), -- Actual Cost
    note             TEXT,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT uq_avanzamento UNIQUE (id_cantiere, data_rilevazione)
);

-- ════════════════════════════════════════════════════════════
-- TRIGGER updated_at
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'utenti','clienti','fornitori','cantieri','operai',
        'settimane_presenze','presenze','mezzi','materiali',
        'documenti','attivita_gantt'
    ] LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%I_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at()',
            t, t
        );
    END LOOP;
END;
$$;

-- ════════════════════════════════════════════════════════════
-- RUOLI APPLICAZIONE (CIS: mai privilegi diretti agli utenti)
-- ════════════════════════════════════════════════════════════

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_owner') THEN
        CREATE ROLE app_owner NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user NOLOGIN;
    END IF;
END;
$$;

GRANT ALL ON ALL TABLES IN SCHEMA public TO app_owner;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO app_owner;

GRANT SELECT, INSERT, UPDATE, DELETE ON
    utenti, clienti, fornitori, cantieri, operai,
    operai_qualifiche, cantieri_operai,
    settimane_presenze, presenze,
    mezzi, assegnazioni_mezzi,
    categorie_materiali, materiali,
    tipi_documento, documenti,
    attivita_gantt, avanzamento_cantieri
TO app_user;

GRANT SELECT ON ruoli, qualifiche TO app_user;

-- ════════════════════════════════════════════════════════════
-- RLS
-- ════════════════════════════════════════════════════════════

ALTER TABLE presenze           ENABLE ROW LEVEL SECURITY;
ALTER TABLE settimane_presenze ENABLE ROW LEVEL SECURITY;
ALTER TABLE documenti          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cantieri           ENABLE ROW LEVEL SECURITY;

-- Accesso completo per app_owner (DDL role)
CREATE POLICY pol_presenze_owner           ON presenze           TO app_owner USING (true) WITH CHECK (true);
CREATE POLICY pol_settimane_owner          ON settimane_presenze TO app_owner USING (true) WITH CHECK (true);
CREATE POLICY pol_documenti_owner          ON documenti          TO app_owner USING (true) WITH CHECK (true);
CREATE POLICY pol_cantieri_owner           ON cantieri           TO app_owner USING (true) WITH CHECK (true);

-- app_user: vede tutto (l'applicazione gestisce la logica di ruolo a livello PHP)
-- Queste policy verranno raffinate quando si implementa l'autenticazione JWT/session
CREATE POLICY pol_presenze_app    ON presenze           TO app_user USING (true) WITH CHECK (true);
CREATE POLICY pol_settimane_app   ON settimane_presenze TO app_user USING (true) WITH CHECK (true);
CREATE POLICY pol_documenti_app   ON documenti          TO app_user USING (true) WITH CHECK (true);
CREATE POLICY pol_cantieri_app    ON cantieri           TO app_user USING (true) WITH CHECK (true);

-- ════════════════════════════════════════════════════════════
-- SEED DATA — lookup tables
-- ════════════════════════════════════════════════════════════

INSERT INTO ruoli (nome, descrizione) VALUES
    ('admin',          'Accesso completo a tutto il gestionale'),
    ('capo_cantiere',  'Gestione operativa cantieri assegnati, registrazione presenze'),
    ('operaio',        'Visualizzazione proprie presenze e documenti personali');

INSERT INTO qualifiche (nome) VALUES
    ('Muratore'),('Elettricista'),('Idraulico'),('Carpentiere'),
    ('Gruista'),('Saldatore'),('Piastrellista'),('Pittore'),
    ('Ferraiolo'),('Decoratore');

INSERT INTO categorie_materiali (nome) VALUES
    ('Calcestruzzo e malte'),('Laterizi e blocchi'),('Acciaio e ferro'),
    ('Legname'),('Impianti elettrici'),('Impianti idraulici'),
    ('Isolanti'),('Finiture e pavimenti'),('Ferramenta'),('Altro');

INSERT INTO tipi_documento (nome) VALUES
    ('Contratto'),('Permesso di costruire'),('DURC'),('DVR'),
    ('Piano di sicurezza'),('Collaudo'),('Fattura'),('DDT'),
    ('Certificazione materiale'),('Altro');

COMMIT;
