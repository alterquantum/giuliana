-- ============================================================
-- GestioneCantieri — Indici (CONCURRENTLY, fuori transazione)
-- ============================================================

-- utenti
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_utenti_id_ruolo         ON utenti (id_ruolo);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_utenti_username_lower    ON utenti (LOWER(username));
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_utenti_email_lower       ON utenti (LOWER(email));

-- cantieri
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cantieri_id_cliente      ON cantieri (id_cliente);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cantieri_id_responsabile ON cantieri (id_responsabile);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cantieri_stato           ON cantieri (stato);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cantieri_date            ON cantieri (data_inizio, data_fine_prevista);

-- operai
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_operai_id_utente         ON operai (id_utente);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_operai_attivo            ON operai (attivo);

-- operai_qualifiche
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_oq_id_qualifica          ON operai_qualifiche (id_qualifica);

-- cantieri_operai
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_co_id_cantiere           ON cantieri_operai (id_cantiere);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_co_id_operaio            ON cantieri_operai (id_operaio);

-- presenze — accesso frequente per data e cantiere
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_presenze_id_cantiere     ON presenze (id_cantiere);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_presenze_id_operaio      ON presenze (id_operaio);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_presenze_data            ON presenze (data);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_presenze_cantiere_data   ON presenze (id_cantiere, data);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_presenze_stato_appr      ON presenze (stato_approvazione);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_presenze_id_settimana    ON presenze (id_settimana);

-- settimane_presenze
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_settimane_id_cantiere    ON settimane_presenze (id_cantiere);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_settimane_anno_sett      ON settimane_presenze (anno, settimana);

-- mezzi
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mezzi_tipo               ON mezzi (tipo);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mezzi_scadenze           ON mezzi (data_revisione, data_scadenza_assicurazione);

-- assegnazioni_mezzi
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ass_mezzi_id_mezzo       ON assegnazioni_mezzi (id_mezzo);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ass_mezzi_id_cantiere    ON assegnazioni_mezzi (id_cantiere);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ass_mezzi_date           ON assegnazioni_mezzi (data_inizio, data_fine);

-- materiali
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materiali_id_cantiere    ON materiali (id_cantiere);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materiali_id_fornitore   ON materiali (id_fornitore);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materiali_id_categoria   ON materiali (id_categoria);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materiali_stato          ON materiali (stato);

-- documenti
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documenti_id_cantiere    ON documenti (id_cantiere);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documenti_id_tipo        ON documenti (id_tipo);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documenti_scadenza       ON documenti (data_scadenza);

-- attivita_gantt
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_gantt_id_cantiere        ON attivita_gantt (id_cantiere);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_gantt_id_padre           ON attivita_gantt (id_padre);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_gantt_ordine             ON attivita_gantt (id_cantiere, ordine);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_gantt_date               ON attivita_gantt (data_inizio_prevista, data_fine_prevista);

-- avanzamento_cantieri — BRIN su data_rilevazione (dati temporali ordinati)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_avanz_id_cantiere        ON avanzamento_cantieri (id_cantiere);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_avanz_data_brin          ON avanzamento_cantieri USING BRIN (data_rilevazione);
