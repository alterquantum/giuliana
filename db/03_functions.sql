-- ============================================================
-- GestioneCantieri — Funzioni principali
-- PostgreSQL 18.3
-- Regole: RETURNS TABLE, parametri p_, SECURITY INVOKER
-- ============================================================

-- ════════════════════════════════════════════════════════════
-- MODULO: DASHBOARD
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_dashboard_kpi()
RETURNS TABLE(
    cantieri_attivi       BIGINT,
    operai_attivi         BIGINT,
    clienti_totali        BIGINT,
    fornitori_totali      BIGINT,
    presenze_oggi         BIGINT,
    documenti_in_scadenza BIGINT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM cantieri        WHERE stato = 'in_corso'),
        (SELECT COUNT(*) FROM operai          WHERE attivo = true),
        (SELECT COUNT(*) FROM clienti         WHERE attivo = true),
        (SELECT COUNT(*) FROM fornitori       WHERE attivo = true),
        (SELECT COUNT(*) FROM presenze        WHERE data = CURRENT_DATE AND stato = 'presente'),
        (SELECT COUNT(*) FROM documenti       WHERE data_scadenza BETWEEN CURRENT_DATE AND CURRENT_DATE + 30);
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: UTENTI
-- ════════════════════════════════════════════════════════════

-- Usata dal login: restituisce utente + nome ruolo per validazione
CREATE OR REPLACE FUNCTION get_utente_by_username(p_username TEXT)
RETURNS TABLE(
    id            UUID,
    username      TEXT,
    email         TEXT,
    password_hash TEXT,
    nome          TEXT,
    cognome       TEXT,
    attivo        BOOLEAN,
    ruolo         TEXT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.username, u.email, u.password_hash,
           u.nome, u.cognome, u.attivo, r.nome
    FROM   utenti u
    JOIN   ruoli  r ON r.id = u.id_ruolo
    WHERE  LOWER(u.username) = LOWER(p_username);
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION list_utenti(
    p_id_ruolo UUID    DEFAULT NULL,
    p_attivo   BOOLEAN DEFAULT NULL
)
RETURNS TABLE(
    id       UUID,
    username TEXT,
    email    TEXT,
    nome     TEXT,
    cognome  TEXT,
    ruolo    TEXT,
    attivo   BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.username, u.email, u.nome, u.cognome,
           r.nome, u.attivo, u.created_at
    FROM   utenti u
    JOIN   ruoli  r ON r.id = u.id_ruolo
    WHERE  (p_id_ruolo IS NULL OR u.id_ruolo = p_id_ruolo)
      AND  (p_attivo   IS NULL OR u.attivo   = p_attivo)
    ORDER BY u.cognome, u.nome;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_utente(
    p_id            UUID,
    p_username      TEXT,
    p_email         TEXT,
    p_password_hash TEXT,
    p_nome          TEXT,
    p_cognome       TEXT,
    p_id_ruolo      UUID
)
RETURNS TABLE(id UUID, username TEXT, email TEXT, nome TEXT, cognome TEXT, attivo BOOLEAN)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO utenti (id, username, email, password_hash, nome, cognome, id_ruolo)
    VALUES (COALESCE(p_id, uuidv7()), p_username, p_email, p_password_hash, p_nome, p_cognome, p_id_ruolo)
    ON CONFLICT ON CONSTRAINT utenti_pkey DO UPDATE SET
        username      = EXCLUDED.username,
        email         = EXCLUDED.email,
        password_hash = COALESCE(NULLIF(EXCLUDED.password_hash, ''), utenti.password_hash),
        nome          = EXCLUDED.nome,
        cognome       = EXCLUDED.cognome,
        id_ruolo      = EXCLUDED.id_ruolo
    RETURNING utenti.id, utenti.username, utenti.email, utenti.nome, utenti.cognome, utenti.attivo;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_utente_attivo(p_id UUID, p_attivo BOOLEAN)
RETURNS TABLE(id UUID, username TEXT, attivo BOOLEAN)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    UPDATE utenti SET attivo = p_attivo
    WHERE  utenti.id = p_id
    RETURNING utenti.id, utenti.username, utenti.attivo;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: CLIENTI
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION list_clienti(
    p_tipo   TEXT DEFAULT NULL,
    p_search TEXT DEFAULT NULL
)
RETURNS TABLE(
    id              UUID,
    ragione_sociale TEXT,
    tipo            TEXT,
    piva            TEXT,
    referente       TEXT,
    email           TEXT,
    telefono        TEXT,
    n_cantieri      BIGINT,
    attivo          BOOLEAN
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.ragione_sociale, c.tipo, c.piva, c.referente, c.email, c.telefono,
           COUNT(cant.id),
           c.attivo
    FROM   clienti c
    LEFT JOIN cantieri cant ON cant.id_cliente = c.id
    WHERE  (p_tipo   IS NULL OR c.tipo = p_tipo)
      AND  (p_search IS NULL OR c.ragione_sociale ILIKE '%' || p_search || '%'
                             OR c.referente       ILIKE '%' || p_search || '%'
                             OR c.piva            ILIKE '%' || p_search || '%')
    GROUP BY c.id
    ORDER BY c.ragione_sociale;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_cliente(
    p_id             UUID,
    p_ragione_sociale TEXT,
    p_tipo           TEXT,
    p_piva           TEXT DEFAULT NULL,
    p_codice_fiscale TEXT DEFAULT NULL,
    p_referente      TEXT DEFAULT NULL,
    p_email          TEXT DEFAULT NULL,
    p_telefono       TEXT DEFAULT NULL,
    p_pec            TEXT DEFAULT NULL,
    p_codice_sdi     TEXT DEFAULT NULL,
    p_indirizzo      TEXT DEFAULT NULL,
    p_note           TEXT DEFAULT NULL
)
RETURNS TABLE(id UUID, ragione_sociale TEXT, tipo TEXT)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO clienti (id, ragione_sociale, tipo, piva, codice_fiscale, referente,
                         email, telefono, pec, codice_sdi, indirizzo, note)
    VALUES (COALESCE(p_id, uuidv7()), p_ragione_sociale, p_tipo, p_piva, p_codice_fiscale,
            p_referente, p_email, p_telefono, p_pec, p_codice_sdi, p_indirizzo, p_note)
    ON CONFLICT ON CONSTRAINT clienti_pkey DO UPDATE SET
        ragione_sociale = EXCLUDED.ragione_sociale,
        tipo            = EXCLUDED.tipo,
        piva            = EXCLUDED.piva,
        codice_fiscale  = EXCLUDED.codice_fiscale,
        referente       = EXCLUDED.referente,
        email           = EXCLUDED.email,
        telefono        = EXCLUDED.telefono,
        pec             = EXCLUDED.pec,
        codice_sdi      = EXCLUDED.codice_sdi,
        indirizzo       = EXCLUDED.indirizzo,
        note            = EXCLUDED.note
    RETURNING clienti.id, clienti.ragione_sociale, clienti.tipo;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: FORNITORI
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION list_fornitori(
    p_categoria TEXT DEFAULT NULL,
    p_search    TEXT DEFAULT NULL
)
RETURNS TABLE(
    id              UUID,
    ragione_sociale TEXT,
    categoria       TEXT,
    piva            TEXT,
    referente       TEXT,
    email           TEXT,
    telefono        TEXT,
    attivo          BOOLEAN
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT f.id, f.ragione_sociale, f.categoria, f.piva,
           f.referente, f.email, f.telefono, f.attivo
    FROM   fornitori f
    WHERE  (p_categoria IS NULL OR f.categoria = p_categoria)
      AND  (p_search    IS NULL OR f.ragione_sociale ILIKE '%' || p_search || '%'
                                OR f.referente       ILIKE '%' || p_search || '%')
    ORDER BY f.ragione_sociale;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_fornitore(
    p_id             UUID,
    p_ragione_sociale TEXT,
    p_categoria      TEXT,
    p_piva           TEXT DEFAULT NULL,
    p_codice_fiscale TEXT DEFAULT NULL,
    p_referente      TEXT DEFAULT NULL,
    p_email          TEXT DEFAULT NULL,
    p_telefono       TEXT DEFAULT NULL,
    p_iban           TEXT DEFAULT NULL,
    p_indirizzo      TEXT DEFAULT NULL,
    p_note           TEXT DEFAULT NULL
)
RETURNS TABLE(id UUID, ragione_sociale TEXT, categoria TEXT)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO fornitori (id, ragione_sociale, categoria, piva, codice_fiscale,
                           referente, email, telefono, iban, indirizzo, note)
    VALUES (COALESCE(p_id, uuidv7()), p_ragione_sociale, p_categoria, p_piva, p_codice_fiscale,
            p_referente, p_email, p_telefono, p_iban, p_indirizzo, p_note)
    ON CONFLICT ON CONSTRAINT fornitori_pkey DO UPDATE SET
        ragione_sociale = EXCLUDED.ragione_sociale,
        categoria       = EXCLUDED.categoria,
        piva            = EXCLUDED.piva,
        codice_fiscale  = EXCLUDED.codice_fiscale,
        referente       = EXCLUDED.referente,
        email           = EXCLUDED.email,
        telefono        = EXCLUDED.telefono,
        iban            = EXCLUDED.iban,
        indirizzo       = EXCLUDED.indirizzo,
        note            = EXCLUDED.note
    RETURNING fornitori.id, fornitori.ragione_sociale, fornitori.categoria;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: CANTIERI
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION list_cantieri(
    p_stato      TEXT DEFAULT NULL,
    p_id_cliente UUID DEFAULT NULL,
    p_search     TEXT DEFAULT NULL
)
RETURNS TABLE(
    id                  UUID,
    nome                TEXT,
    stato               TEXT,
    cliente             TEXT,
    responsabile        TEXT,
    indirizzo           TEXT,
    data_inizio         DATE,
    data_fine_prevista  DATE,
    importo_contratto   NUMERIC,
    pct_completamento   NUMERIC
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id, c.nome, c.stato,
        cl.ragione_sociale,
        COALESCE(u.cognome || ' ' || u.nome, '—'),
        c.indirizzo,
        c.data_inizio, c.data_fine_prevista,
        c.importo_contratto,
        -- media pesata del completamento dalle attività Gantt
        COALESCE(
            (SELECT ROUND(AVG(ag.percentuale_completamento::NUMERIC), 0)
             FROM   attivita_gantt ag
             WHERE  ag.id_cantiere = c.id AND ag.id_padre IS NULL),
        0)
    FROM  cantieri c
    JOIN  clienti  cl ON cl.id = c.id_cliente
    LEFT JOIN utenti u ON u.id = c.id_responsabile
    WHERE (p_stato      IS NULL OR c.stato      = p_stato)
      AND (p_id_cliente IS NULL OR c.id_cliente = p_id_cliente)
      AND (p_search     IS NULL OR c.nome ILIKE '%' || p_search || '%'
                                OR cl.ragione_sociale ILIKE '%' || p_search || '%')
    ORDER BY c.data_inizio DESC NULLS LAST;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_cantiere(p_id UUID)
RETURNS TABLE(
    id                  UUID,
    nome                TEXT,
    stato               TEXT,
    id_cliente          UUID,
    cliente             TEXT,
    id_responsabile     UUID,
    responsabile        TEXT,
    indirizzo           TEXT,
    data_inizio         DATE,
    data_fine_prevista  DATE,
    data_fine_effettiva DATE,
    importo_contratto   NUMERIC,
    tipo_lavori         TEXT,
    note                TEXT,
    n_operai            BIGINT,
    costo_materiali     NUMERIC
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id, c.nome, c.stato,
        c.id_cliente, cl.ragione_sociale,
        c.id_responsabile, COALESCE(u.cognome || ' ' || u.nome, '—'),
        c.indirizzo, c.data_inizio, c.data_fine_prevista, c.data_fine_effettiva,
        c.importo_contratto, c.tipo_lavori, c.note,
        (SELECT COUNT(DISTINCT co.id_operaio) FROM cantieri_operai co WHERE co.id_cantiere = c.id),
        (SELECT COALESCE(SUM(m.quantita * m.costo_unitario), 0)
         FROM   materiali m WHERE m.id_cantiere = c.id AND m.stato <> 'annullato')
    FROM  cantieri c
    JOIN  clienti  cl ON cl.id = c.id_cliente
    LEFT JOIN utenti u  ON u.id  = c.id_responsabile
    WHERE c.id = p_id;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_cantiere(
    p_id                  UUID,
    p_nome                TEXT,
    p_id_cliente          UUID,
    p_id_responsabile     UUID    DEFAULT NULL,
    p_indirizzo           TEXT    DEFAULT NULL,
    p_data_inizio         DATE    DEFAULT NULL,
    p_data_fine_prevista  DATE    DEFAULT NULL,
    p_stato               TEXT    DEFAULT 'pianificato',
    p_importo_contratto   NUMERIC DEFAULT NULL,
    p_tipo_lavori         TEXT    DEFAULT NULL,
    p_note                TEXT    DEFAULT NULL
)
RETURNS TABLE(id UUID, nome TEXT, stato TEXT)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO cantieri (id, nome, id_cliente, id_responsabile, indirizzo,
                          data_inizio, data_fine_prevista, stato,
                          importo_contratto, tipo_lavori, note)
    VALUES (COALESCE(p_id, uuidv7()), p_nome, p_id_cliente, p_id_responsabile, p_indirizzo,
            p_data_inizio, p_data_fine_prevista, p_stato,
            p_importo_contratto, p_tipo_lavori, p_note)
    ON CONFLICT ON CONSTRAINT cantieri_pkey DO UPDATE SET
        nome               = EXCLUDED.nome,
        id_cliente         = EXCLUDED.id_cliente,
        id_responsabile    = EXCLUDED.id_responsabile,
        indirizzo          = EXCLUDED.indirizzo,
        data_inizio        = EXCLUDED.data_inizio,
        data_fine_prevista = EXCLUDED.data_fine_prevista,
        stato              = EXCLUDED.stato,
        importo_contratto  = EXCLUDED.importo_contratto,
        tipo_lavori        = EXCLUDED.tipo_lavori,
        note               = EXCLUDED.note
    RETURNING cantieri.id, cantieri.nome, cantieri.stato;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: OPERAI
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION list_operai(
    p_attivo      BOOLEAN DEFAULT NULL,
    p_id_qualifica UUID   DEFAULT NULL,
    p_search      TEXT    DEFAULT NULL
)
RETURNS TABLE(
    id              UUID,
    nome            TEXT,
    cognome         TEXT,
    codice_fiscale  TEXT,
    telefono        TEXT,
    email           TEXT,
    data_assunzione DATE,
    attivo          BOOLEAN,
    qualifiche      TEXT[]
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id, o.nome, o.cognome, o.codice_fiscale,
        o.telefono, o.email, o.data_assunzione, o.attivo,
        ARRAY_AGG(q.nome ORDER BY q.nome) FILTER (WHERE q.nome IS NOT NULL)
    FROM   operai o
    LEFT JOIN operai_qualifiche oq ON oq.id_operaio  = o.id
    LEFT JOIN qualifiche        q  ON q.id            = oq.id_qualifica
    WHERE  (p_attivo      IS NULL OR o.attivo = p_attivo)
      AND  (p_id_qualifica IS NULL OR EXISTS (
                SELECT 1 FROM operai_qualifiche x
                WHERE x.id_operaio = o.id AND x.id_qualifica = p_id_qualifica))
      AND  (p_search IS NULL
            OR o.nome    ILIKE '%' || p_search || '%'
            OR o.cognome ILIKE '%' || p_search || '%'
            OR o.codice_fiscale ILIKE '%' || p_search || '%')
    GROUP BY o.id
    ORDER BY o.cognome, o.nome;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_operaio(
    p_id             UUID,
    p_nome           TEXT,
    p_cognome        TEXT,
    p_codice_fiscale TEXT    DEFAULT NULL,
    p_data_nascita   DATE    DEFAULT NULL,
    p_telefono       TEXT    DEFAULT NULL,
    p_email          TEXT    DEFAULT NULL,
    p_data_assunzione DATE   DEFAULT NULL,
    p_id_utente      UUID    DEFAULT NULL
)
RETURNS TABLE(id UUID, nome TEXT, cognome TEXT, attivo BOOLEAN)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO operai (id, nome, cognome, codice_fiscale, data_nascita,
                        telefono, email, data_assunzione, id_utente)
    VALUES (COALESCE(p_id, uuidv7()), p_nome, p_cognome, p_codice_fiscale,
            p_data_nascita, p_telefono, p_email, p_data_assunzione, p_id_utente)
    ON CONFLICT ON CONSTRAINT operai_pkey DO UPDATE SET
        nome            = EXCLUDED.nome,
        cognome         = EXCLUDED.cognome,
        codice_fiscale  = EXCLUDED.codice_fiscale,
        data_nascita    = EXCLUDED.data_nascita,
        telefono        = EXCLUDED.telefono,
        email           = EXCLUDED.email,
        data_assunzione = EXCLUDED.data_assunzione,
        id_utente       = EXCLUDED.id_utente
    RETURNING operai.id, operai.nome, operai.cognome, operai.attivo;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Sostituisce interamente le qualifiche di un operaio (delete-then-insert)
CREATE OR REPLACE FUNCTION set_qualifiche_operaio(
    p_id_operaio  UUID,
    p_id_qualifiche UUID[]
)
RETURNS TABLE(id_operaio UUID, n_qualifiche INT)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    DELETE FROM operai_qualifiche WHERE operai_qualifiche.id_operaio = p_id_operaio;

    INSERT INTO operai_qualifiche (id_operaio, id_qualifica)
    SELECT p_id_operaio, UNNEST(p_id_qualifiche)
    ON CONFLICT DO NOTHING;

    RETURN QUERY
    SELECT p_id_operaio, CARDINALITY(p_id_qualifiche);
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Assegna / rimuove un operaio da un cantiere
CREATE OR REPLACE FUNCTION assegna_operaio_cantiere(
    p_id_cantiere UUID,
    p_id_operaio  UUID,
    p_data_inizio DATE,
    p_data_fine   DATE DEFAULT NULL
)
RETURNS TABLE(id UUID, id_cantiere UUID, id_operaio UUID, data_inizio DATE)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO cantieri_operai (id, id_cantiere, id_operaio, data_inizio, data_fine)
    VALUES (uuidv7(), p_id_cantiere, p_id_operaio, p_data_inizio, p_data_fine)
    ON CONFLICT ON CONSTRAINT uq_cantieri_operai DO UPDATE SET
        data_fine = EXCLUDED.data_fine
    RETURNING cantieri_operai.id, cantieri_operai.id_cantiere,
              cantieri_operai.id_operaio, cantieri_operai.data_inizio;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: PRESENZE
-- ════════════════════════════════════════════════════════════

-- Vista giornaliera: tutti gli operai del cantiere in una data,
-- con il loro record presenza se esiste (NULL se non ancora registrato)
CREATE OR REPLACE FUNCTION get_foglio_giornaliero(
    p_id_cantiere UUID,
    p_data        DATE
)
RETURNS TABLE(
    id_operaio         UUID,
    nome               TEXT,
    cognome            TEXT,
    qualifiche         TEXT[],
    id_presenza        UUID,
    stato              TEXT,
    ore_ordinarie      NUMERIC,
    ore_straordinarie  NUMERIC,
    stato_approvazione TEXT,
    note               TEXT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id,
        o.nome,
        o.cognome,
        ARRAY_AGG(q.nome ORDER BY q.nome) FILTER (WHERE q.nome IS NOT NULL),
        p.id,
        p.stato,
        p.ore_ordinarie,
        p.ore_straordinarie,
        p.stato_approvazione,
        p.note
    FROM      cantieri_operai co
    JOIN      operai          o  ON o.id          = co.id_operaio
    LEFT JOIN operai_qualifiche oq ON oq.id_operaio = o.id
    LEFT JOIN qualifiche        q  ON q.id          = oq.id_qualifica
    LEFT JOIN presenze          p  ON p.id_operaio  = o.id
                                  AND p.id_cantiere = p_id_cantiere
                                  AND p.data        = p_data
    WHERE co.id_cantiere = p_id_cantiere
      AND co.data_inizio <= p_data
      AND (co.data_fine IS NULL OR co.data_fine >= p_data)
      AND o.attivo = true
    GROUP BY o.id, o.nome, o.cognome,
             p.id, p.stato, p.ore_ordinarie, p.ore_straordinarie,
             p.stato_approvazione, p.note
    ORDER BY o.cognome, o.nome;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Inserisce o aggiorna una presenza; blocca se la settimana è chiusa
CREATE OR REPLACE FUNCTION upsert_presenza(
    p_id_cantiere       UUID,
    p_id_operaio        UUID,
    p_data              DATE,
    p_stato             TEXT,
    p_ore_ordinarie     NUMERIC DEFAULT 0,
    p_ore_straordinarie NUMERIC DEFAULT 0,
    p_note              TEXT    DEFAULT NULL,
    p_id_registrato_da  UUID    DEFAULT NULL
)
RETURNS TABLE(
    id                 UUID,
    stato              TEXT,
    ore_ordinarie      NUMERIC,
    ore_straordinarie  NUMERIC,
    stato_approvazione TEXT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_id_settimana UUID;
BEGIN
    -- Ricava l'eventuale settimana associata
    SELECT sp.id INTO v_id_settimana
    FROM   settimane_presenze sp
    WHERE  sp.id_cantiere = p_id_cantiere
      AND  sp.anno        = EXTRACT(ISOYEAR FROM p_data)::INT
      AND  sp.settimana   = EXTRACT(WEEK    FROM p_data)::INT;

    RETURN QUERY
    INSERT INTO presenze (
        id, id_cantiere, id_operaio, id_settimana,
        data, stato, ore_ordinarie, ore_straordinarie,
        note, id_registrato_da
    )
    VALUES (
        uuidv7(), p_id_cantiere, p_id_operaio, v_id_settimana,
        p_data, p_stato, p_ore_ordinarie, p_ore_straordinarie,
        p_note, p_id_registrato_da
    )
    ON CONFLICT (id_cantiere, id_operaio, data) DO UPDATE SET
        stato               = EXCLUDED.stato,
        ore_ordinarie       = EXCLUDED.ore_ordinarie,
        ore_straordinarie   = EXCLUDED.ore_straordinarie,
        note                = EXCLUDED.note,
        id_registrato_da    = EXCLUDED.id_registrato_da
    WHERE presenze.stato_approvazione <> 'chiuso'   -- blocca settimane chiuse
    RETURNING presenze.id, presenze.stato,
              presenze.ore_ordinarie, presenze.ore_straordinarie,
              presenze.stato_approvazione;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Griglia settimanale: una riga per (operaio × giorno)
-- Genera tutti i 7 giorni della settimana ISO anche se non ci sono presenze
CREATE OR REPLACE FUNCTION get_griglia_settimanale(
    p_id_cantiere UUID,
    p_anno        INT,
    p_settimana   INT
)
RETURNS TABLE(
    id_operaio         UUID,
    nome               TEXT,
    cognome            TEXT,
    data               DATE,
    stato              TEXT,
    ore_ordinarie      NUMERIC,
    ore_straordinarie  NUMERIC,
    stato_approvazione TEXT,
    id_presenza        UUID
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_lunedi DATE;
BEGIN
    -- Lunedì della settimana ISO n dell'anno p_anno
    v_lunedi := (date_trunc('week',
                    make_date(p_anno, 1, 4) + ((p_settimana - 1) || ' weeks')::INTERVAL
                ))::DATE;

    RETURN QUERY
    SELECT
        o.id, o.nome, o.cognome,
        d.data::DATE,
        COALESCE(p.stato, NULL),
        COALESCE(p.ore_ordinarie,     0::NUMERIC),
        COALESCE(p.ore_straordinarie, 0::NUMERIC),
        p.stato_approvazione,
        p.id
    FROM      cantieri_operai co
    JOIN      operai          o  ON o.id = co.id_operaio AND o.attivo = true
    CROSS JOIN LATERAL generate_series(v_lunedi, v_lunedi + 6, '1 day'::INTERVAL) AS d(data)
    LEFT JOIN presenze p ON p.id_operaio  = o.id
                        AND p.id_cantiere = p_id_cantiere
                        AND p.data        = d.data::DATE
    WHERE co.id_cantiere = p_id_cantiere
      AND co.data_inizio <= v_lunedi + 6
      AND (co.data_fine IS NULL OR co.data_fine >= v_lunedi)
    ORDER BY o.cognome, o.nome, d.data;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Chiude una settimana: blocca tutte le presenze e aggiorna/crea il record
CREATE OR REPLACE FUNCTION chiudi_settimana(
    p_id_cantiere UUID,
    p_anno        INT,
    p_settimana   INT,
    p_id_utente   UUID
)
RETURNS TABLE(
    id_settimana      UUID,
    stato             TEXT,
    presenze_chiuse   BIGINT,
    ore_ordinarie     NUMERIC,
    ore_straordinarie NUMERIC
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_lunedi      DATE;
    v_domenica    DATE;
    v_id_sett     UUID;
    v_n_chiuse    BIGINT;
    v_ore_ord     NUMERIC;
    v_ore_str     NUMERIC;
BEGIN
    v_lunedi   := (date_trunc('week',
                      make_date(p_anno, 1, 4) + ((p_settimana - 1) || ' weeks')::INTERVAL
                  ))::DATE;
    v_domenica := v_lunedi + 6;

    -- Crea o aggiorna il record settimana
    INSERT INTO settimane_presenze (id, id_cantiere, anno, settimana, stato, id_chiuso_da, chiuso_at)
    VALUES (uuidv7(), p_id_cantiere, p_anno, p_settimana, 'chiuso', p_id_utente, now())
    ON CONFLICT (id_cantiere, anno, settimana) DO UPDATE SET
        stato        = 'chiuso',
        id_chiuso_da = EXCLUDED.id_chiuso_da,
        chiuso_at    = EXCLUDED.chiuso_at
    RETURNING settimane_presenze.id INTO v_id_sett;

    -- Aggiorna le presenze collegando la settimana e bloccandole
    UPDATE presenze SET
        stato_approvazione = 'chiuso',
        id_settimana       = v_id_sett
    WHERE presenze.id_cantiere = p_id_cantiere
      AND presenze.data BETWEEN v_lunedi AND v_domenica;

    -- Calcola riepilogo
    SELECT COUNT(*), COALESCE(SUM(p.ore_ordinarie), 0), COALESCE(SUM(p.ore_straordinarie), 0)
    INTO   v_n_chiuse, v_ore_ord, v_ore_str
    FROM   presenze p
    WHERE  p.id_cantiere = p_id_cantiere
      AND  p.data BETWEEN v_lunedi AND v_domenica;

    RETURN QUERY SELECT v_id_sett, 'chiuso'::TEXT, v_n_chiuse, v_ore_ord, v_ore_str;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Report ore per operaio in un periodo
CREATE OR REPLACE FUNCTION get_report_ore_periodo(
    p_id_cantiere UUID    DEFAULT NULL,
    p_da          DATE    DEFAULT CURRENT_DATE - 30,
    p_a           DATE    DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    id_operaio        UUID,
    nome              TEXT,
    cognome           TEXT,
    giorni_presenti   BIGINT,
    giorni_assenza    BIGINT,
    giorni_ferie      BIGINT,
    ore_ordinarie     NUMERIC,
    ore_straordinarie NUMERIC,
    ore_totali        NUMERIC
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id, o.nome, o.cognome,
        COUNT(*) FILTER (WHERE p.stato = 'presente'),
        COUNT(*) FILTER (WHERE p.stato IN ('assente','malattia','permesso')),
        COUNT(*) FILTER (WHERE p.stato = 'ferie'),
        COALESCE(SUM(p.ore_ordinarie),     0),
        COALESCE(SUM(p.ore_straordinarie), 0),
        COALESCE(SUM(p.ore_ordinarie + p.ore_straordinarie), 0)
    FROM   presenze p
    JOIN   operai   o ON o.id = p.id_operaio
    WHERE  p.data BETWEEN p_da AND p_a
      AND  (p_id_cantiere IS NULL OR p.id_cantiere = p_id_cantiere)
    GROUP BY o.id, o.nome, o.cognome
    ORDER BY o.cognome, o.nome;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: MEZZI
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION list_mezzi(
    p_tipo    TEXT    DEFAULT NULL,
    p_attivo  BOOLEAN DEFAULT NULL
)
RETURNS TABLE(
    id                          UUID,
    nome                        TEXT,
    tipo                        TEXT,
    targa                       TEXT,
    numero_seriale              TEXT,
    data_revisione              DATE,
    data_scadenza_assicurazione DATE,
    cantiere_corrente           TEXT,
    attivo                      BOOLEAN,
    gg_scadenza_revisione       INT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id, m.nome, m.tipo, m.targa, m.numero_seriale,
        m.data_revisione, m.data_scadenza_assicurazione,
        -- cantiere attivo corrente
        (SELECT c.nome
         FROM   assegnazioni_mezzi am
         JOIN   cantieri c ON c.id = am.id_cantiere
         WHERE  am.id_mezzo   = m.id
           AND  am.data_inizio <= CURRENT_DATE
           AND  (am.data_fine IS NULL OR am.data_fine >= CURRENT_DATE)
         ORDER BY am.data_inizio DESC LIMIT 1),
        m.attivo,
        (m.data_revisione - CURRENT_DATE)::INT
    FROM  mezzi m
    WHERE (p_tipo   IS NULL OR m.tipo   = p_tipo)
      AND (p_attivo IS NULL OR m.attivo = p_attivo)
    ORDER BY m.nome;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_mezzi_in_scadenza(p_giorni INT DEFAULT 30)
RETURNS TABLE(
    id              UUID,
    nome            TEXT,
    tipo            TEXT,
    targa           TEXT,
    tipo_scadenza   TEXT,
    data_scadenza   DATE,
    giorni_mancanti INT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM (
        SELECT m.id, m.nome, m.tipo, m.targa,
               'Revisione'::TEXT,
               m.data_revisione,
               (m.data_revisione - CURRENT_DATE)::INT
        FROM   mezzi m
        WHERE  m.attivo = true
          AND  m.data_revisione IS NOT NULL
          AND  m.data_revisione <= CURRENT_DATE + p_giorni

        UNION ALL

        SELECT m.id, m.nome, m.tipo, m.targa,
               'Assicurazione'::TEXT,
               m.data_scadenza_assicurazione,
               (m.data_scadenza_assicurazione - CURRENT_DATE)::INT
        FROM   mezzi m
        WHERE  m.attivo = true
          AND  m.data_scadenza_assicurazione IS NOT NULL
          AND  m.data_scadenza_assicurazione <= CURRENT_DATE + p_giorni
    ) sub
    ORDER BY giorni_mancanti;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_mezzo(
    p_id                          UUID,
    p_nome                        TEXT,
    p_tipo                        TEXT,
    p_targa                       TEXT    DEFAULT NULL,
    p_numero_seriale              TEXT    DEFAULT NULL,
    p_data_revisione              DATE    DEFAULT NULL,
    p_data_scadenza_assicurazione DATE    DEFAULT NULL,
    p_note                        TEXT    DEFAULT NULL
)
RETURNS TABLE(id UUID, nome TEXT, tipo TEXT)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO mezzi (id, nome, tipo, targa, numero_seriale,
                       data_revisione, data_scadenza_assicurazione, note)
    VALUES (COALESCE(p_id, uuidv7()), p_nome, p_tipo, p_targa, p_numero_seriale,
            p_data_revisione, p_data_scadenza_assicurazione, p_note)
    ON CONFLICT ON CONSTRAINT mezzi_pkey DO UPDATE SET
        nome                        = EXCLUDED.nome,
        tipo                        = EXCLUDED.tipo,
        targa                       = EXCLUDED.targa,
        numero_seriale              = EXCLUDED.numero_seriale,
        data_revisione              = EXCLUDED.data_revisione,
        data_scadenza_assicurazione = EXCLUDED.data_scadenza_assicurazione,
        note                        = EXCLUDED.note
    RETURNING mezzi.id, mezzi.nome, mezzi.tipo;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: MATERIALI
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION list_materiali(
    p_id_cantiere UUID DEFAULT NULL,
    p_stato       TEXT DEFAULT NULL
)
RETURNS TABLE(
    id                      UUID,
    id_cantiere             UUID,
    cantiere                TEXT,
    fornitore               TEXT,
    categoria               TEXT,
    descrizione             TEXT,
    quantita                NUMERIC,
    unita_misura            TEXT,
    costo_unitario          NUMERIC,
    totale                  NUMERIC,
    stato                   TEXT,
    data_ordine             DATE,
    data_consegna_prevista  DATE,
    data_consegna_effettiva DATE
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id, m.id_cantiere,
        c.nome,
        COALESCE(f.ragione_sociale, '—'),
        COALESCE(cm.nome, '—'),
        m.descrizione, m.quantita, m.unita_misura, m.costo_unitario,
        ROUND(m.quantita * m.costo_unitario, 2),
        m.stato,
        m.data_ordine, m.data_consegna_prevista, m.data_consegna_effettiva
    FROM   materiali         m
    JOIN   cantieri          c  ON c.id  = m.id_cantiere
    LEFT JOIN fornitori      f  ON f.id  = m.id_fornitore
    LEFT JOIN categorie_materiali cm ON cm.id = m.id_categoria
    WHERE  (p_id_cantiere IS NULL OR m.id_cantiere = p_id_cantiere)
      AND  (p_stato       IS NULL OR m.stato       = p_stato)
    ORDER BY m.data_ordine DESC NULLS LAST;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_totale_materiali_cantiere(p_id_cantiere UUID)
RETURNS TABLE(
    categoria      TEXT,
    n_ordini       BIGINT,
    totale         NUMERIC,
    totale_fatturato NUMERIC
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(cm.nome, 'Senza categoria'),
        COUNT(m.id),
        ROUND(SUM(m.quantita * m.costo_unitario), 2),
        ROUND(SUM(m.quantita * m.costo_unitario) FILTER (WHERE m.stato = 'fatturato'), 2)
    FROM   materiali m
    LEFT JOIN categorie_materiali cm ON cm.id = m.id_categoria
    WHERE  m.id_cantiere = p_id_cantiere
      AND  m.stato <> 'annullato'
    GROUP BY cm.nome
    ORDER BY totale DESC;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_materiale(
    p_id                     UUID,
    p_id_cantiere            UUID,
    p_descrizione            TEXT,
    p_quantita               NUMERIC,
    p_unita_misura           TEXT,
    p_costo_unitario         NUMERIC,
    p_id_fornitore           UUID    DEFAULT NULL,
    p_id_categoria           UUID    DEFAULT NULL,
    p_stato                  TEXT    DEFAULT 'ordinato',
    p_data_ordine            DATE    DEFAULT NULL,
    p_data_consegna_prevista DATE    DEFAULT NULL,
    p_note                   TEXT    DEFAULT NULL
)
RETURNS TABLE(id UUID, descrizione TEXT, totale NUMERIC, stato TEXT)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO materiali (id, id_cantiere, id_fornitore, id_categoria, descrizione,
                           quantita, unita_misura, costo_unitario, stato,
                           data_ordine, data_consegna_prevista, note)
    VALUES (COALESCE(p_id, uuidv7()), p_id_cantiere, p_id_fornitore, p_id_categoria,
            p_descrizione, p_quantita, p_unita_misura, p_costo_unitario, p_stato,
            p_data_ordine, p_data_consegna_prevista, p_note)
    ON CONFLICT ON CONSTRAINT materiali_pkey DO UPDATE SET
        id_fornitore           = EXCLUDED.id_fornitore,
        id_categoria           = EXCLUDED.id_categoria,
        descrizione            = EXCLUDED.descrizione,
        quantita               = EXCLUDED.quantita,
        unita_misura           = EXCLUDED.unita_misura,
        costo_unitario         = EXCLUDED.costo_unitario,
        stato                  = EXCLUDED.stato,
        data_ordine            = EXCLUDED.data_ordine,
        data_consegna_prevista = EXCLUDED.data_consegna_prevista,
        note                   = EXCLUDED.note
    RETURNING materiali.id, materiali.descrizione,
              ROUND(materiali.quantita * materiali.costo_unitario, 2),
              materiali.stato;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: DOCUMENTI
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION list_documenti(
    p_id_cantiere UUID DEFAULT NULL,
    p_id_tipo     UUID DEFAULT NULL
)
RETURNS TABLE(
    id             UUID,
    nome           TEXT,
    tipo           TEXT,
    cantiere       TEXT,
    caricato_da    TEXT,
    tipo_file      TEXT,
    data_emissione DATE,
    data_scadenza  DATE,
    gg_scadenza    INT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id, d.nome,
        td.nome,
        COALESCE(c.nome, '—'),
        COALESCE(u.cognome || ' ' || u.nome, '—'),
        d.tipo_file, d.data_emissione, d.data_scadenza,
        (d.data_scadenza - CURRENT_DATE)::INT
    FROM   documenti      d
    JOIN   tipi_documento td ON td.id = d.id_tipo
    LEFT JOIN cantieri    c  ON c.id  = d.id_cantiere
    LEFT JOIN utenti      u  ON u.id  = d.id_caricato_da
    WHERE  (p_id_cantiere IS NULL OR d.id_cantiere = p_id_cantiere)
      AND  (p_id_tipo     IS NULL OR d.id_tipo     = p_id_tipo)
    ORDER BY d.data_scadenza ASC NULLS LAST;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_documenti_in_scadenza(p_giorni INT DEFAULT 30)
RETURNS TABLE(
    id              UUID,
    nome            TEXT,
    tipo            TEXT,
    cantiere        TEXT,
    data_scadenza   DATE,
    giorni_mancanti INT,
    scaduto         BOOLEAN
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id, d.nome, td.nome,
        COALESCE(c.nome, '—'),
        d.data_scadenza,
        (d.data_scadenza - CURRENT_DATE)::INT,
        d.data_scadenza < CURRENT_DATE
    FROM   documenti      d
    JOIN   tipi_documento td ON td.id = d.id_tipo
    LEFT JOIN cantieri    c  ON c.id  = d.id_cantiere
    WHERE  d.data_scadenza IS NOT NULL
      AND  d.data_scadenza <= CURRENT_DATE + p_giorni
    ORDER BY d.data_scadenza;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_documento(
    p_id            UUID,
    p_id_tipo       UUID,
    p_nome          TEXT,
    p_id_cantiere   UUID    DEFAULT NULL,
    p_descrizione   TEXT    DEFAULT NULL,
    p_percorso_file TEXT    DEFAULT NULL,
    p_tipo_file     TEXT    DEFAULT NULL,
    p_data_emissione DATE   DEFAULT NULL,
    p_data_scadenza  DATE   DEFAULT NULL,
    p_id_caricato_da UUID   DEFAULT NULL
)
RETURNS TABLE(id UUID, nome TEXT, data_scadenza DATE)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO documenti (id, id_tipo, id_cantiere, nome, descrizione,
                           percorso_file, tipo_file, data_emissione,
                           data_scadenza, id_caricato_da)
    VALUES (COALESCE(p_id, uuidv7()), p_id_tipo, p_id_cantiere, p_nome, p_descrizione,
            p_percorso_file, p_tipo_file, p_data_emissione, p_data_scadenza, p_id_caricato_da)
    ON CONFLICT ON CONSTRAINT documenti_pkey DO UPDATE SET
        id_tipo          = EXCLUDED.id_tipo,
        id_cantiere      = EXCLUDED.id_cantiere,
        nome             = EXCLUDED.nome,
        descrizione      = EXCLUDED.descrizione,
        percorso_file    = EXCLUDED.percorso_file,
        tipo_file        = EXCLUDED.tipo_file,
        data_emissione   = EXCLUDED.data_emissione,
        data_scadenza    = EXCLUDED.data_scadenza,
        id_caricato_da   = EXCLUDED.id_caricato_da
    RETURNING documenti.id, documenti.nome, documenti.data_scadenza;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- MODULO: GANTT & EVM
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_gantt_cantiere(p_id_cantiere UUID)
RETURNS TABLE(
    id                        UUID,
    id_padre                  UUID,
    nome                      TEXT,
    data_inizio_prevista      DATE,
    data_fine_prevista        DATE,
    data_inizio_effettiva     DATE,
    data_fine_effettiva       DATE,
    percentuale_completamento INT,
    budget_previsto           NUMERIC,
    costo_effettivo           NUMERIC,
    ordine                    INT,
    durata_prevista_gg        INT,
    scostamento_gg            INT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        ag.id, ag.id_padre, ag.nome,
        ag.data_inizio_prevista, ag.data_fine_prevista,
        ag.data_inizio_effettiva, ag.data_fine_effettiva,
        ag.percentuale_completamento,
        ag.budget_previsto, ag.costo_effettivo,
        ag.ordine,
        (ag.data_fine_prevista - ag.data_inizio_prevista)::INT,
        -- scostamento: positivo = ritardo, negativo = anticipo
        CASE
            WHEN ag.data_fine_effettiva IS NOT NULL
            THEN (ag.data_fine_effettiva - ag.data_fine_prevista)::INT
            WHEN ag.percentuale_completamento < 100 AND CURRENT_DATE > ag.data_fine_prevista
            THEN (CURRENT_DATE - ag.data_fine_prevista)::INT
            ELSE 0
        END
    FROM   attivita_gantt ag
    WHERE  ag.id_cantiere = p_id_cantiere
    ORDER BY ag.id_padre NULLS FIRST, ag.ordine, ag.data_inizio_prevista;
END;
$$;

-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION upsert_attivita_gantt(
    p_id                      UUID,
    p_id_cantiere             UUID,
    p_nome                    TEXT,
    p_data_inizio_prevista    DATE,
    p_data_fine_prevista      DATE,
    p_id_padre                UUID    DEFAULT NULL,
    p_percentuale_completamento INT   DEFAULT 0,
    p_budget_previsto         NUMERIC DEFAULT 0,
    p_costo_effettivo         NUMERIC DEFAULT 0,
    p_data_inizio_effettiva   DATE    DEFAULT NULL,
    p_data_fine_effettiva     DATE    DEFAULT NULL,
    p_ordine                  INT     DEFAULT 0
)
RETURNS TABLE(id UUID, nome TEXT, percentuale_completamento INT)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO attivita_gantt (
        id, id_cantiere, id_padre, nome,
        data_inizio_prevista, data_fine_prevista,
        data_inizio_effettiva, data_fine_effettiva,
        percentuale_completamento, budget_previsto, costo_effettivo, ordine
    )
    VALUES (
        COALESCE(p_id, uuidv7()), p_id_cantiere, p_id_padre, p_nome,
        p_data_inizio_prevista, p_data_fine_prevista,
        p_data_inizio_effettiva, p_data_fine_effettiva,
        p_percentuale_completamento, p_budget_previsto, p_costo_effettivo, p_ordine
    )
    ON CONFLICT ON CONSTRAINT attivita_gantt_pkey DO UPDATE SET
        nome                      = EXCLUDED.nome,
        id_padre                  = EXCLUDED.id_padre,
        data_inizio_prevista      = EXCLUDED.data_inizio_prevista,
        data_fine_prevista        = EXCLUDED.data_fine_prevista,
        data_inizio_effettiva     = EXCLUDED.data_inizio_effettiva,
        data_fine_effettiva       = EXCLUDED.data_fine_effettiva,
        percentuale_completamento = EXCLUDED.percentuale_completamento,
        budget_previsto           = EXCLUDED.budget_previsto,
        costo_effettivo           = EXCLUDED.costo_effettivo,
        ordine                    = EXCLUDED.ordine
    RETURNING attivita_gantt.id, attivita_gantt.nome,
              attivita_gantt.percentuale_completamento;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Registra un snapshot EVM per un cantiere
CREATE OR REPLACE FUNCTION registra_snapshot_evm(
    p_id_cantiere UUID,
    p_bac         NUMERIC,
    p_pv          NUMERIC,
    p_ev          NUMERIC,
    p_ac          NUMERIC,
    p_nota        TEXT DEFAULT NULL,
    p_data        DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(id UUID, data_rilevazione DATE, spi NUMERIC, cpi NUMERIC)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    INSERT INTO avanzamento_cantieri (id, id_cantiere, data_rilevazione, bac, pv, ev, ac, note)
    VALUES (uuidv7(), p_id_cantiere, p_data, p_bac, p_pv, p_ev, p_ac, p_nota)
    ON CONFLICT ON CONSTRAINT uq_avanzamento DO UPDATE SET
        bac  = EXCLUDED.bac,
        pv   = EXCLUDED.pv,
        ev   = EXCLUDED.ev,
        ac   = EXCLUDED.ac,
        note = EXCLUDED.note
    RETURNING
        avanzamento_cantieri.id,
        avanzamento_cantieri.data_rilevazione,
        CASE WHEN avanzamento_cantieri.pv > 0 THEN ROUND(avanzamento_cantieri.ev / avanzamento_cantieri.pv, 3) ELSE NULL END,
        CASE WHEN avanzamento_cantieri.ac > 0 THEN ROUND(avanzamento_cantieri.ev / avanzamento_cantieri.ac, 3) ELSE NULL END;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- EVM per singolo cantiere: indicatori calcolati dall'ultimo snapshot
CREATE OR REPLACE FUNCTION get_evm_cantiere(p_id_cantiere UUID)
RETURNS TABLE(
    id_cantiere      UUID,
    nome_cantiere    TEXT,
    data_rilevazione DATE,
    bac              NUMERIC,
    pv               NUMERIC,
    ev               NUMERIC,
    ac               NUMERIC,
    sv               NUMERIC,   -- Schedule Variance  = EV - PV
    cv               NUMERIC,   -- Cost Variance      = EV - AC
    spi              NUMERIC,   -- Schedule Perf. Index = EV / PV
    cpi              NUMERIC,   -- Cost Perf. Index   = EV / AC
    eac              NUMERIC,   -- Estimate at Completion = BAC / CPI
    etc              NUMERIC,   -- Estimate to Complete = EAC - AC
    vac              NUMERIC    -- Variance at Completion = BAC - EAC
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.nome,
        a.data_rilevazione,
        a.bac, a.pv, a.ev, a.ac,
        ROUND(a.ev - a.pv, 2),
        ROUND(a.ev - a.ac, 2),
        CASE WHEN a.pv > 0 THEN ROUND(a.ev / a.pv, 3) ELSE NULL END,
        CASE WHEN a.ac > 0 THEN ROUND(a.ev / a.ac, 3) ELSE NULL END,
        CASE WHEN a.ac > 0 THEN ROUND(a.bac / (a.ev / a.ac), 2) ELSE NULL END,
        CASE WHEN a.ac > 0 THEN ROUND(a.bac / (a.ev / a.ac) - a.ac, 2) ELSE NULL END,
        CASE WHEN a.ac > 0 THEN ROUND(a.bac - a.bac / (a.ev / a.ac), 2) ELSE NULL END
    FROM  avanzamento_cantieri a
    JOIN  cantieri             c ON c.id = a.id_cantiere
    WHERE a.id_cantiere = p_id_cantiere
    ORDER BY a.data_rilevazione DESC
    LIMIT 1;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- EVM portfolio: un record per cantiere (ultimo snapshot disponibile)
CREATE OR REPLACE FUNCTION get_evm_portfolio()
RETURNS TABLE(
    id_cantiere   UUID,
    cantiere      TEXT,
    stato         TEXT,
    bac           NUMERIC,
    spi           NUMERIC,
    cpi           NUMERIC,
    eac           NUMERIC,
    vac           NUMERIC,
    data_snapshot DATE
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (c.id)
        c.id, c.nome, c.stato,
        a.bac,
        CASE WHEN a.pv > 0 THEN ROUND(a.ev / a.pv, 3) ELSE NULL END,
        CASE WHEN a.ac > 0 THEN ROUND(a.ev / a.ac, 3) ELSE NULL END,
        CASE WHEN a.ac > 0 THEN ROUND(a.bac / (a.ev / a.ac), 2) ELSE NULL END,
        CASE WHEN a.ac > 0 THEN ROUND(a.bac - a.bac / (a.ev / a.ac), 2) ELSE NULL END,
        a.data_rilevazione
    FROM  cantieri             c
    JOIN  avanzamento_cantieri a ON a.id_cantiere = c.id
    WHERE c.stato IN ('in_corso','completato')
    ORDER BY c.id, a.data_rilevazione DESC;
END;
$$;
