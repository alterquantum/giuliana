--
-- PostgreSQL database dump
--

\restrict heLeq8uzfsekg95XfLSXqXZkXtP3grLTcFr3LWKZtfqF18PGKA3cDDxTb94MDv7

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: analisi_computo(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.analisi_computo(p_id_computo uuid) RETURNS TABLE(codice_dei text, descrizione_lavorazione text, unita_misura text, quantita_totale numeric, importo_totale numeric, durata_giorni numeric, n_operai integer, specializzazioni jsonb, costo_materiali numeric, costo_noli numeric, attrezzature text[])
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.codice_dei,
        COALESCE(d.descrizione, MIN(v.descrizione))         AS descrizione_lavorazione,
        MIN(v.unita_misura)                                 AS unita_misura,
        SUM(v.quantita)                                     AS quantita_totale,
        SUM(v.importo)                                      AS importo_totale,
        SUM(v.durata_giorni)                                AS durata_giorni,
        -- usa n_operai salvato (già stimato in import), oppure ricalcola
        COALESCE(
            MAX(v.n_operai),
            CASE
                WHEN d.rendimento_giornaliero > 0 AND d.incidenza_manodopera > 0
                     AND d.prezzo_unitario > 0
                THEN GREATEST(1, ROUND(
                        (d.prezzo_unitario * d.incidenza_manodopera / 100.0)
                        / (d.rendimento_giornaliero * 58.0)
                     ))::int
            END
        )                                                   AS n_operai,
        d.squadra_tipo                                      AS specializzazioni,
        SUM(v.quantita * COALESCE(d.incidenza_materiali,0)) AS costo_materiali,
        SUM(v.quantita * COALESCE(d.incidenza_noli,0))      AS costo_noli,
        d.attrezzature
    FROM   computo_voci   v
    LEFT JOIN prezziario_dei d ON d.codice = v.codice_dei
    WHERE  v.id_computo = p_id_computo
    GROUP BY COALESCE(v.codice_dei, v.id::text),
             v.codice_dei, d.descrizione, d.squadra_tipo,
             d.attrezzature, d.rendimento_giornaliero,
             d.incidenza_manodopera, d.prezzo_unitario
    ORDER BY durata_giorni DESC NULLS LAST;
END;
$$;


--
-- Name: assegna_operaio_cantiere(uuid, uuid, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assegna_operaio_cantiere(p_id_cantiere uuid, p_id_operaio uuid, p_data_inizio date, p_data_fine date DEFAULT NULL::date) RETURNS TABLE(id uuid, id_cantiere uuid, id_operaio uuid, data_inizio date)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: chiudi_settimana(uuid, integer, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.chiudi_settimana(p_id_cantiere uuid, p_anno integer, p_settimana integer, p_id_utente uuid) RETURNS TABLE(id_settimana uuid, stato text, presenze_chiuse bigint, ore_ordinarie numeric, ore_straordinarie numeric)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: delete_computo(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_computo(p_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM computi WHERE id = p_id;
END;
$$;


--
-- Name: delete_prezziario_dei(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_prezziario_dei() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM prezziario_dei;
END;
$$;


--
-- Name: fn_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


--
-- Name: get_cantiere(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_cantiere(p_id uuid) RETURNS TABLE(id uuid, nome text, stato text, id_cliente uuid, cliente text, id_responsabile uuid, responsabile text, indirizzo text, data_inizio date, data_fine_prevista date, data_fine_effettiva date, importo_contratto numeric, tipo_lavori text, note text, n_operai bigint, costo_materiali numeric)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_dashboard_kpi(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_dashboard_kpi() RETURNS TABLE(cantieri_attivi bigint, operai_attivi bigint, clienti_totali bigint, fornitori_totali bigint, presenze_oggi bigint, documenti_in_scadenza bigint)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_documenti_in_scadenza(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_documenti_in_scadenza(p_giorni integer DEFAULT 30) RETURNS TABLE(id uuid, nome text, tipo text, cantiere text, data_scadenza date, giorni_mancanti integer, scaduto boolean)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_evm_cantiere(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_evm_cantiere(p_id_cantiere uuid) RETURNS TABLE(id_cantiere uuid, nome_cantiere text, data_rilevazione date, bac numeric, pv numeric, ev numeric, ac numeric, sv numeric, cv numeric, spi numeric, cpi numeric, eac numeric, etc numeric, vac numeric)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_evm_portfolio(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_evm_portfolio() RETURNS TABLE(id_cantiere uuid, cantiere text, stato text, bac numeric, spi numeric, cpi numeric, eac numeric, vac numeric, data_snapshot date)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_foglio_giornaliero(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_foglio_giornaliero(p_id_cantiere uuid, p_data date) RETURNS TABLE(id_operaio uuid, nome text, cognome text, qualifiche text[], id_presenza uuid, stato text, ore_ordinarie numeric, ore_straordinarie numeric, stato_approvazione text, note text)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_gantt_cantiere(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_gantt_cantiere(p_id_cantiere uuid) RETURNS TABLE(id uuid, id_padre uuid, nome text, data_inizio_prevista date, data_fine_prevista date, data_inizio_effettiva date, data_fine_effettiva date, percentuale_completamento integer, budget_previsto numeric, costo_effettivo numeric, ordine integer, durata_prevista_gg integer, scostamento_gg integer)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_griglia_settimanale(uuid, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_griglia_settimanale(p_id_cantiere uuid, p_anno integer, p_settimana integer) RETURNS TABLE(id_operaio uuid, nome text, cognome text, data date, stato text, ore_ordinarie numeric, ore_straordinarie numeric, stato_approvazione text, id_presenza uuid)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_mezzi_in_scadenza(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_mezzi_in_scadenza(p_giorni integer DEFAULT 30) RETURNS TABLE(id uuid, nome text, tipo text, targa text, tipo_scadenza text, data_scadenza date, giorni_mancanti integer)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_prezziario_dei_by_codice(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_prezziario_dei_by_codice(p_codice text) RETURNS TABLE(id uuid, codice text, descrizione text, unita_misura text, prezzo_unitario numeric, incidenza_manodopera numeric, incidenza_materiali numeric, incidenza_noli numeric, rendimento_giornaliero numeric, categoria text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id, d.codice, d.descrizione, d.unita_misura,
        d.prezzo_unitario, d.incidenza_manodopera, d.incidenza_materiali,
        d.incidenza_noli, d.rendimento_giornaliero, d.categoria
    FROM prezziario_dei d
    WHERE d.codice = p_codice;
END;
$$;


--
-- Name: get_report_ore_periodo(uuid, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_report_ore_periodo(p_id_cantiere uuid DEFAULT NULL::uuid, p_da date DEFAULT (CURRENT_DATE - 30), p_a date DEFAULT CURRENT_DATE) RETURNS TABLE(id_operaio uuid, nome text, cognome text, giorni_presenti bigint, giorni_assenza bigint, giorni_ferie bigint, ore_ordinarie numeric, ore_straordinarie numeric, ore_totali numeric)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_totale_materiali_cantiere(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_totale_materiali_cantiere(p_id_cantiere uuid) RETURNS TABLE(categoria text, n_ordini bigint, totale numeric, totale_fatturato numeric)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: get_utente_by_username(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_utente_by_username(p_username text) RETURNS TABLE(id uuid, username text, email text, password_hash text, nome text, cognome text, attivo boolean, ruolo text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.username, u.email, u.password_hash,
           u.nome, u.cognome, u.attivo, r.nome
    FROM   utenti u
    JOIN   ruoli  r ON r.id = u.id_ruolo
    WHERE  LOWER(u.username) = LOWER(p_username);
END;
$$;


--
-- Name: import_computo(uuid, text, numeric, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.import_computo(p_id_cantiere uuid, p_nome_file text, p_importo numeric, p_voci jsonb) RETURNS TABLE(id_computo uuid, n_voci integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id UUID;
    v_n  INTEGER;
BEGIN
    INSERT INTO computi (id, id_cantiere, nome_file, importo_totale)
    VALUES (uuidv7(), p_id_cantiere, p_nome_file, p_importo)
    RETURNING id INTO v_id;

    INSERT INTO computo_voci (
        id, id_computo, numero_voce, codice_dei, descrizione,
        unita_misura, quantita, prezzo_unitario, importo,
        durata_giorni, n_operai
    )
    SELECT
        uuidv7(),
        v_id,
        v->>'numero_voce',
        NULLIF(v->>'codice_dei', ''),
        v->>'descrizione',
        v->>'unita_misura',
        COALESCE((v->>'quantita')::NUMERIC, 0),
        NULLIF(v->>'prezzo_unitario', '')::NUMERIC,
        NULLIF(v->>'importo', '')::NUMERIC,
        -- durata: rendimento Campania in giornate/unità → qty * rendimento
        CASE
            WHEN d.rendimento_giornaliero > 0
            THEN ROUND(COALESCE((v->>'quantita')::NUMERIC, 0) * d.rendimento_giornaliero, 2)
        END,
        -- n_operai: da squadra_tipo (DEI commerciale) oppure stimato da incidenza%
        CASE
            WHEN d.squadra_tipo IS NOT NULL
            THEN (SELECT SUM(val::int)
                  FROM jsonb_each_text(d.squadra_tipo) AS t(key, val))
            WHEN d.rendimento_giornaliero > 0 AND d.incidenza_manodopera > 0
                 AND d.prezzo_unitario > 0
            THEN GREATEST(1, ROUND(
                    (d.prezzo_unitario * d.incidenza_manodopera / 100.0)
                    / (d.rendimento_giornaliero * 58.0)
                 ))::int
        END
    FROM jsonb_array_elements(p_voci) AS v
    LEFT JOIN prezziario_dei d ON d.codice = NULLIF(v->>'codice_dei', '');

    GET DIAGNOSTICS v_n = ROW_COUNT;
    RETURN QUERY SELECT v_id, v_n;
END;
$$;


--
-- Name: list_cantieri(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_cantieri(p_stato text DEFAULT NULL::text, p_id_cliente uuid DEFAULT NULL::uuid, p_search text DEFAULT NULL::text) RETURNS TABLE(id uuid, id_cliente uuid, nome text, stato text, cliente text, responsabile text, indirizzo text, data_inizio date, data_fine_prevista date, importo_contratto numeric, pct_completamento numeric, tipo_lavori text, note text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.id_cliente, c.nome, c.stato, cl.ragione_sociale,
           COALESCE(u.cognome || ' ' || u.nome, '—'),
           c.indirizzo, c.data_inizio, c.data_fine_prevista, c.importo_contratto,
           COALESCE((SELECT ROUND(AVG(ag.percentuale_completamento::NUMERIC), 0) FROM attivita_gantt ag WHERE ag.id_cantiere = c.id AND ag.id_padre IS NULL), 0),
           c.tipo_lavori, c.note
    FROM cantieri c
    JOIN  clienti cl ON cl.id = c.id_cliente
    LEFT JOIN utenti u ON u.id = c.id_responsabile
    WHERE (p_stato IS NULL OR c.stato = p_stato)
      AND (p_id_cliente IS NULL OR c.id_cliente = p_id_cliente)
      AND (p_search IS NULL OR c.nome ILIKE '%' || p_search || '%' OR cl.ragione_sociale ILIKE '%' || p_search || '%')
    ORDER BY c.data_inizio DESC NULLS LAST;
END;
$$;


--
-- Name: list_clienti(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_clienti(p_tipo text DEFAULT NULL::text, p_search text DEFAULT NULL::text) RETURNS TABLE(id uuid, ragione_sociale text, tipo text, piva text, codice_fiscale text, referente text, email text, telefono text, indirizzo text, note text, n_cantieri bigint, attivo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.ragione_sociale, c.tipo, c.piva, c.codice_fiscale,
           c.referente, c.email, c.telefono, c.indirizzo, c.note,
           COUNT(cant.id), c.attivo
    FROM clienti c
    LEFT JOIN cantieri cant ON cant.id_cliente = c.id
    WHERE (p_tipo IS NULL OR c.tipo = p_tipo)
      AND (p_search IS NULL OR c.ragione_sociale ILIKE '%' || p_search || '%'
                            OR c.referente ILIKE '%' || p_search || '%'
                            OR c.piva ILIKE '%' || p_search || '%')
    GROUP BY c.id
    ORDER BY c.ragione_sociale;
END;
$$;


--
-- Name: list_computi(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_computi(p_id_cantiere uuid) RETURNS TABLE(id uuid, nome_file text, importo_totale numeric, n_voci bigint, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.nome_file, c.importo_totale,
           COUNT(v.id), c.created_at
    FROM   computi c
    LEFT JOIN computo_voci v ON v.id_computo = c.id
    WHERE  c.id_cantiere = p_id_cantiere
    GROUP BY c.id
    ORDER BY c.created_at DESC;
END;
$$;


--
-- Name: list_documenti(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_documenti(p_id_cantiere uuid DEFAULT NULL::uuid, p_id_tipo uuid DEFAULT NULL::uuid) RETURNS TABLE(id uuid, id_tipo uuid, id_cantiere uuid, nome text, tipo text, cantiere text, caricato_da text, tipo_file text, data_emissione date, data_scadenza date, gg_scadenza integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT d.id, d.id_tipo, d.id_cantiere, d.nome, td.nome,
           COALESCE(c.nome, '—'), COALESCE(u.cognome || ' ' || u.nome, '—'),
           d.tipo_file, d.data_emissione, d.data_scadenza,
           (d.data_scadenza - CURRENT_DATE)::INT
    FROM documenti d
    JOIN tipi_documento td ON td.id = d.id_tipo
    LEFT JOIN cantieri c ON c.id = d.id_cantiere
    LEFT JOIN utenti u ON u.id = d.id_caricato_da
    WHERE (p_id_cantiere IS NULL OR d.id_cantiere = p_id_cantiere)
      AND (p_id_tipo IS NULL OR d.id_tipo = p_id_tipo)
    ORDER BY d.data_scadenza ASC NULLS LAST;
END;
$$;


--
-- Name: list_fornitori(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_fornitori(p_categoria text DEFAULT NULL::text, p_search text DEFAULT NULL::text) RETURNS TABLE(id uuid, ragione_sociale text, categoria text, piva text, referente text, email text, telefono text, iban text, indirizzo text, note text, attivo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT f.id, f.ragione_sociale, f.categoria, f.piva,
           f.referente, f.email, f.telefono, f.iban, f.indirizzo, f.note, f.attivo
    FROM fornitori f
    WHERE (p_categoria IS NULL OR f.categoria = p_categoria)
      AND (p_search IS NULL OR f.ragione_sociale ILIKE '%' || p_search || '%' OR f.referente ILIKE '%' || p_search || '%')
    ORDER BY f.ragione_sociale;
END;
$$;


--
-- Name: list_materiali(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_materiali(p_id_cantiere uuid DEFAULT NULL::uuid, p_stato text DEFAULT NULL::text) RETURNS TABLE(id uuid, id_cantiere uuid, id_fornitore uuid, id_categoria uuid, cantiere text, fornitore text, categoria text, descrizione text, quantita numeric, unita_misura text, costo_unitario numeric, totale numeric, stato text, data_ordine date, data_consegna_prevista date, data_consegna_effettiva date, note text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, m.id_cantiere, m.id_fornitore, m.id_categoria,
           c.nome, COALESCE(f.ragione_sociale, '—'), COALESCE(cm.nome, '—'),
           m.descrizione, m.quantita, m.unita_misura, m.costo_unitario,
           ROUND(m.quantita * m.costo_unitario, 2),
           m.stato, m.data_ordine, m.data_consegna_prevista, m.data_consegna_effettiva, m.note
    FROM materiali m
    JOIN cantieri c ON c.id = m.id_cantiere
    LEFT JOIN fornitori f ON f.id = m.id_fornitore
    LEFT JOIN categorie_materiali cm ON cm.id = m.id_categoria
    WHERE (p_id_cantiere IS NULL OR m.id_cantiere = p_id_cantiere)
      AND (p_stato IS NULL OR m.stato = p_stato)
    ORDER BY m.data_ordine DESC NULLS LAST;
END;
$$;


--
-- Name: list_mezzi(text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_mezzi(p_tipo text DEFAULT NULL::text, p_attivo boolean DEFAULT NULL::boolean) RETURNS TABLE(id uuid, nome text, tipo text, targa text, numero_seriale text, data_revisione date, data_scadenza_assicurazione date, cantiere_corrente text, attivo boolean, gg_scadenza_revisione integer)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: list_operai(boolean, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_operai(p_attivo boolean DEFAULT NULL::boolean, p_id_qualifica uuid DEFAULT NULL::uuid, p_search text DEFAULT NULL::text) RETURNS TABLE(id uuid, nome text, cognome text, codice_fiscale text, data_nascita date, telefono text, email text, data_assunzione date, attivo boolean, qualifiche text[])
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT o.id, o.nome, o.cognome, o.codice_fiscale, o.data_nascita,
           o.telefono, o.email, o.data_assunzione, o.attivo,
           ARRAY_AGG(q.nome ORDER BY q.nome) FILTER (WHERE q.nome IS NOT NULL)
    FROM   operai o
    LEFT JOIN operai_qualifiche oq ON oq.id_operaio = o.id
    LEFT JOIN qualifiche q ON q.id = oq.id_qualifica
    WHERE (p_attivo IS NULL OR o.attivo = p_attivo)
      AND (p_id_qualifica IS NULL OR EXISTS (SELECT 1 FROM operai_qualifiche x WHERE x.id_operaio = o.id AND x.id_qualifica = p_id_qualifica))
      AND (p_search IS NULL OR o.nome ILIKE '%' || p_search || '%' OR o.cognome ILIKE '%' || p_search || '%' OR o.codice_fiscale ILIKE '%' || p_search || '%')
    GROUP BY o.id
    ORDER BY o.cognome, o.nome;
END;
$$;


--
-- Name: list_prezziario_dei(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_prezziario_dei(p_search text DEFAULT NULL::text, p_categoria text DEFAULT NULL::text) RETURNS TABLE(id uuid, codice text, descrizione text, unita_misura text, prezzo_unitario numeric, incidenza_manodopera numeric, incidenza_materiali numeric, incidenza_noli numeric, rendimento_giornaliero numeric, categoria text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id,
        d.codice,
        d.descrizione,
        d.unita_misura,
        d.prezzo_unitario,
        d.incidenza_manodopera,
        d.incidenza_materiali,
        d.incidenza_noli,
        d.rendimento_giornaliero,
        d.categoria
    FROM prezziario_dei d
    WHERE
        (p_search IS NULL OR
            d.codice      ILIKE '%' || p_search || '%' OR
            d.descrizione ILIKE '%' || p_search || '%')
        AND
        (p_categoria IS NULL OR d.categoria ILIKE '%' || p_categoria || '%')
    ORDER BY d.codice;
END;
$$;


--
-- Name: list_utenti(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_utenti(p_id_ruolo uuid DEFAULT NULL::uuid, p_attivo boolean DEFAULT NULL::boolean) RETURNS TABLE(id uuid, username text, email text, nome text, cognome text, ruolo text, attivo boolean, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: registra_snapshot_evm(uuid, numeric, numeric, numeric, numeric, text, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registra_snapshot_evm(p_id_cantiere uuid, p_bac numeric, p_pv numeric, p_ev numeric, p_ac numeric, p_nota text DEFAULT NULL::text, p_data date DEFAULT CURRENT_DATE) RETURNS TABLE(id uuid, data_rilevazione date, spi numeric, cpi numeric)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: set_qualifiche_operaio(uuid, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_qualifiche_operaio(p_id_operaio uuid, p_id_qualifiche uuid[]) RETURNS TABLE(id_operaio uuid, n_qualifiche integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM operai_qualifiche WHERE operai_qualifiche.id_operaio = p_id_operaio;

    INSERT INTO operai_qualifiche (id_operaio, id_qualifica)
    SELECT p_id_operaio, UNNEST(p_id_qualifiche)
    ON CONFLICT DO NOTHING;

    RETURN QUERY
    SELECT p_id_operaio, CARDINALITY(p_id_qualifiche);
END;
$$;


--
-- Name: set_utente_attivo(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_utente_attivo(p_id uuid, p_attivo boolean) RETURNS TABLE(id uuid, username text, attivo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    UPDATE utenti SET attivo = p_attivo
    WHERE  utenti.id = p_id
    RETURNING utenti.id, utenti.username, utenti.attivo;
END;
$$;


--
-- Name: toggle_operaio_attivo(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.toggle_operaio_attivo(p_id uuid) RETURNS TABLE(id uuid, nome text, cognome text, attivo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    UPDATE operai SET attivo = NOT attivo
    WHERE  operai.id = p_id
    RETURNING operai.id, operai.nome, operai.cognome, operai.attivo;
END;
$$;


--
-- Name: upsert_attivita_gantt(uuid, uuid, text, date, date, uuid, integer, numeric, numeric, date, date, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_attivita_gantt(p_id uuid, p_id_cantiere uuid, p_nome text, p_data_inizio_prevista date, p_data_fine_prevista date, p_id_padre uuid DEFAULT NULL::uuid, p_percentuale_completamento integer DEFAULT 0, p_budget_previsto numeric DEFAULT 0, p_costo_effettivo numeric DEFAULT 0, p_data_inizio_effettiva date DEFAULT NULL::date, p_data_fine_effettiva date DEFAULT NULL::date, p_ordine integer DEFAULT 0) RETURNS TABLE(id uuid, nome text, percentuale_completamento integer)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_cantiere(uuid, text, uuid, uuid, text, date, date, text, numeric, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_cantiere(p_id uuid, p_nome text, p_id_cliente uuid, p_id_responsabile uuid DEFAULT NULL::uuid, p_indirizzo text DEFAULT NULL::text, p_data_inizio date DEFAULT NULL::date, p_data_fine_prevista date DEFAULT NULL::date, p_stato text DEFAULT 'pianificato'::text, p_importo_contratto numeric DEFAULT NULL::numeric, p_tipo_lavori text DEFAULT NULL::text, p_note text DEFAULT NULL::text) RETURNS TABLE(id uuid, nome text, stato text)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_cliente(uuid, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_cliente(p_id uuid, p_ragione_sociale text, p_tipo text, p_piva text DEFAULT NULL::text, p_codice_fiscale text DEFAULT NULL::text, p_referente text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_telefono text DEFAULT NULL::text, p_pec text DEFAULT NULL::text, p_codice_sdi text DEFAULT NULL::text, p_indirizzo text DEFAULT NULL::text, p_note text DEFAULT NULL::text) RETURNS TABLE(id uuid, ragione_sociale text, tipo text)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_documento(uuid, uuid, text, uuid, text, text, text, date, date, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_documento(p_id uuid, p_id_tipo uuid, p_nome text, p_id_cantiere uuid DEFAULT NULL::uuid, p_descrizione text DEFAULT NULL::text, p_percorso_file text DEFAULT NULL::text, p_tipo_file text DEFAULT NULL::text, p_data_emissione date DEFAULT NULL::date, p_data_scadenza date DEFAULT NULL::date, p_id_caricato_da uuid DEFAULT NULL::uuid) RETURNS TABLE(id uuid, nome text, data_scadenza date)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_fornitore(uuid, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_fornitore(p_id uuid, p_ragione_sociale text, p_categoria text, p_piva text DEFAULT NULL::text, p_codice_fiscale text DEFAULT NULL::text, p_referente text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_telefono text DEFAULT NULL::text, p_iban text DEFAULT NULL::text, p_indirizzo text DEFAULT NULL::text, p_note text DEFAULT NULL::text) RETURNS TABLE(id uuid, ragione_sociale text, categoria text)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_materiale(uuid, uuid, text, numeric, text, numeric, uuid, uuid, text, date, date, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_materiale(p_id uuid, p_id_cantiere uuid, p_descrizione text, p_quantita numeric, p_unita_misura text, p_costo_unitario numeric, p_id_fornitore uuid DEFAULT NULL::uuid, p_id_categoria uuid DEFAULT NULL::uuid, p_stato text DEFAULT 'ordinato'::text, p_data_ordine date DEFAULT NULL::date, p_data_consegna_prevista date DEFAULT NULL::date, p_note text DEFAULT NULL::text) RETURNS TABLE(id uuid, descrizione text, totale numeric, stato text)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_mezzo(uuid, text, text, text, text, date, date, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_mezzo(p_id uuid, p_nome text, p_tipo text, p_targa text DEFAULT NULL::text, p_numero_seriale text DEFAULT NULL::text, p_data_revisione date DEFAULT NULL::date, p_data_scadenza_assicurazione date DEFAULT NULL::date, p_note text DEFAULT NULL::text) RETURNS TABLE(id uuid, nome text, tipo text)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_operaio(uuid, text, text, text, date, text, text, date, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_operaio(p_id uuid, p_nome text, p_cognome text, p_codice_fiscale text DEFAULT NULL::text, p_data_nascita date DEFAULT NULL::date, p_telefono text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_data_assunzione date DEFAULT NULL::date, p_id_utente uuid DEFAULT NULL::uuid) RETURNS TABLE(id uuid, nome text, cognome text, attivo boolean)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_presenza(uuid, uuid, date, text, numeric, numeric, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_presenza(p_id_cantiere uuid, p_id_operaio uuid, p_data date, p_stato text, p_ore_ordinarie numeric DEFAULT 0, p_ore_straordinarie numeric DEFAULT 0, p_note text DEFAULT NULL::text, p_id_registrato_da uuid DEFAULT NULL::uuid) RETURNS TABLE(id uuid, stato text, ore_ordinarie numeric, ore_straordinarie numeric, stato_approvazione text)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: upsert_prezziario_dei(text, text, text, numeric, numeric, numeric, numeric, numeric, jsonb, text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_prezziario_dei(p_codice text, p_descrizione text DEFAULT NULL::text, p_unita_misura text DEFAULT NULL::text, p_prezzo_unitario numeric DEFAULT NULL::numeric, p_incidenza_manodopera numeric DEFAULT NULL::numeric, p_incidenza_materiali numeric DEFAULT NULL::numeric, p_incidenza_noli numeric DEFAULT NULL::numeric, p_rendimento_giornaliero numeric DEFAULT NULL::numeric, p_squadra_tipo jsonb DEFAULT NULL::jsonb, p_attrezzature text[] DEFAULT NULL::text[], p_categoria text DEFAULT NULL::text) RETURNS TABLE(id uuid, codice text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    INSERT INTO prezziario_dei (
        codice, descrizione, unita_misura,
        prezzo_unitario, incidenza_manodopera, incidenza_materiali,
        incidenza_noli, rendimento_giornaliero,
        squadra_tipo, attrezzature, categoria
    )
    VALUES (
        p_codice, p_descrizione, p_unita_misura,
        p_prezzo_unitario, p_incidenza_manodopera, p_incidenza_materiali,
        p_incidenza_noli, p_rendimento_giornaliero,
        p_squadra_tipo, p_attrezzature, p_categoria
    )
    ON CONFLICT (codice) DO UPDATE SET
        descrizione             = EXCLUDED.descrizione,
        unita_misura            = EXCLUDED.unita_misura,
        prezzo_unitario         = EXCLUDED.prezzo_unitario,
        incidenza_manodopera    = EXCLUDED.incidenza_manodopera,
        incidenza_materiali     = EXCLUDED.incidenza_materiali,
        incidenza_noli          = EXCLUDED.incidenza_noli,
        rendimento_giornaliero  = EXCLUDED.rendimento_giornaliero,
        squadra_tipo            = EXCLUDED.squadra_tipo,
        attrezzature            = EXCLUDED.attrezzature,
        categoria               = EXCLUDED.categoria
    RETURNING prezziario_dei.id, prezziario_dei.codice;
END;
$$;


--
-- Name: upsert_utente(uuid, text, text, text, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_utente(p_id uuid, p_username text, p_email text, p_password_hash text, p_nome text, p_cognome text, p_id_ruolo uuid) RETURNS TABLE(id uuid, username text, email text, nome text, cognome text, attivo boolean)
    LANGUAGE plpgsql
    AS $$
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: assegnazioni_mezzi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assegnazioni_mezzi (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_mezzo uuid NOT NULL,
    id_cantiere uuid NOT NULL,
    data_inizio date NOT NULL,
    data_fine date,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: attivita_gantt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attivita_gantt (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cantiere uuid NOT NULL,
    id_padre uuid,
    nome text NOT NULL,
    data_inizio_prevista date NOT NULL,
    data_fine_prevista date NOT NULL,
    data_inizio_effettiva date,
    data_fine_effettiva date,
    percentuale_completamento integer DEFAULT 0 NOT NULL,
    budget_previsto numeric(12,2) DEFAULT 0 NOT NULL,
    costo_effettivo numeric(12,2) DEFAULT 0 NOT NULL,
    ordine integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attivita_gantt_budget_previsto_check CHECK ((budget_previsto >= (0)::numeric)),
    CONSTRAINT attivita_gantt_costo_effettivo_check CHECK ((costo_effettivo >= (0)::numeric)),
    CONSTRAINT attivita_gantt_percentuale_completamento_check CHECK (((percentuale_completamento >= 0) AND (percentuale_completamento <= 100))),
    CONSTRAINT chk_date_gantt CHECK ((data_fine_prevista >= data_inizio_prevista))
);


--
-- Name: avanzamento_cantieri; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.avanzamento_cantieri (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cantiere uuid NOT NULL,
    data_rilevazione date NOT NULL,
    bac numeric(12,2) NOT NULL,
    pv numeric(12,2) NOT NULL,
    ev numeric(12,2) NOT NULL,
    ac numeric(12,2) NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT avanzamento_cantieri_ac_check CHECK ((ac >= (0)::numeric)),
    CONSTRAINT avanzamento_cantieri_bac_check CHECK ((bac > (0)::numeric)),
    CONSTRAINT avanzamento_cantieri_ev_check CHECK ((ev >= (0)::numeric)),
    CONSTRAINT avanzamento_cantieri_pv_check CHECK ((pv >= (0)::numeric))
);


--
-- Name: cantieri; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cantieri (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cliente uuid NOT NULL,
    id_responsabile uuid,
    nome text NOT NULL,
    indirizzo text,
    data_inizio date,
    data_fine_prevista date,
    data_fine_effettiva date,
    stato text DEFAULT 'pianificato'::text NOT NULL,
    importo_contratto numeric(12,2),
    tipo_lavori text,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cantieri_stato_check CHECK ((stato = ANY (ARRAY['pianificato'::text, 'in_corso'::text, 'sospeso'::text, 'completato'::text])))
);


--
-- Name: cantieri_operai; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cantieri_operai (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cantiere uuid NOT NULL,
    id_operaio uuid NOT NULL,
    data_inizio date NOT NULL,
    data_fine date
);


--
-- Name: categorie_materiali; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categorie_materiali (
    id uuid DEFAULT uuidv7() NOT NULL,
    nome text NOT NULL
);


--
-- Name: clienti; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clienti (
    id uuid DEFAULT uuidv7() NOT NULL,
    ragione_sociale text NOT NULL,
    tipo text NOT NULL,
    piva text,
    codice_fiscale text,
    referente text,
    email text,
    telefono text,
    pec text,
    codice_sdi text,
    indirizzo text,
    note text,
    attivo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT clienti_tipo_check CHECK ((tipo = ANY (ARRAY['privato'::text, 'azienda'::text, 'ente_pubblico'::text])))
);


--
-- Name: computi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.computi (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cantiere uuid NOT NULL,
    nome_file text NOT NULL,
    importo_totale numeric(14,2),
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: computo_voci; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.computo_voci (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_computo uuid NOT NULL,
    numero_voce text,
    codice_dei text,
    descrizione text NOT NULL,
    unita_misura text,
    quantita numeric(14,4) DEFAULT 0 NOT NULL,
    prezzo_unitario numeric(12,4),
    importo numeric(14,2),
    durata_giorni numeric(8,2),
    n_operai integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: documenti; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documenti (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cantiere uuid,
    id_tipo uuid NOT NULL,
    id_caricato_da uuid,
    nome text NOT NULL,
    descrizione text,
    percorso_file text,
    tipo_file text,
    data_emissione date,
    data_scadenza date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: fornitori; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fornitori (
    id uuid DEFAULT uuidv7() NOT NULL,
    ragione_sociale text NOT NULL,
    categoria text NOT NULL,
    piva text,
    codice_fiscale text,
    referente text,
    email text,
    telefono text,
    iban text,
    indirizzo text,
    note text,
    attivo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fornitori_categoria_check CHECK ((categoria = ANY (ARRAY['mat_edili'::text, 'elettrico'::text, 'idraulico'::text, 'ferramenta'::text, 'legname'::text, 'nolo_macchinari'::text, 'altro'::text])))
);


--
-- Name: materiali; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materiali (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cantiere uuid NOT NULL,
    id_fornitore uuid,
    id_categoria uuid,
    descrizione text NOT NULL,
    quantita numeric(10,3) NOT NULL,
    unita_misura text NOT NULL,
    costo_unitario numeric(10,2) NOT NULL,
    stato text DEFAULT 'ordinato'::text NOT NULL,
    data_ordine date,
    data_consegna_prevista date,
    data_consegna_effettiva date,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT materiali_costo_unitario_check CHECK ((costo_unitario >= (0)::numeric)),
    CONSTRAINT materiali_quantita_check CHECK ((quantita > (0)::numeric)),
    CONSTRAINT materiali_stato_check CHECK ((stato = ANY (ARRAY['ordinato'::text, 'consegnato'::text, 'fatturato'::text, 'annullato'::text])))
);


--
-- Name: mezzi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mezzi (
    id uuid DEFAULT uuidv7() NOT NULL,
    nome text NOT NULL,
    tipo text NOT NULL,
    targa text,
    numero_seriale text,
    data_revisione date,
    data_scadenza_assicurazione date,
    note text,
    attivo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mezzi_tipo_check CHECK ((tipo = ANY (ARRAY['autocarro'::text, 'escavatore'::text, 'gru'::text, 'betoniera'::text, 'compressore'::text, 'sollevatore'::text, 'altro'::text])))
);


--
-- Name: operai; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operai (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_utente uuid,
    nome text NOT NULL,
    cognome text NOT NULL,
    codice_fiscale text,
    data_nascita date,
    telefono text,
    email text,
    data_assunzione date,
    attivo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: operai_qualifiche; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operai_qualifiche (
    id_operaio uuid NOT NULL,
    id_qualifica uuid NOT NULL,
    data_acquisizione date,
    data_scadenza date
);


--
-- Name: presenze; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.presenze (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cantiere uuid NOT NULL,
    id_operaio uuid NOT NULL,
    id_settimana uuid,
    id_registrato_da uuid,
    id_approvato_da uuid,
    data date NOT NULL,
    stato text DEFAULT 'presente'::text NOT NULL,
    ore_ordinarie numeric(4,2) DEFAULT 0 NOT NULL,
    ore_straordinarie numeric(4,2) DEFAULT 0 NOT NULL,
    stato_approvazione text DEFAULT 'bozza'::text NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT presenze_ore_ordinarie_check CHECK ((ore_ordinarie >= (0)::numeric)),
    CONSTRAINT presenze_ore_straordinarie_check CHECK ((ore_straordinarie >= (0)::numeric)),
    CONSTRAINT presenze_stato_approvazione_check CHECK ((stato_approvazione = ANY (ARRAY['bozza'::text, 'confermato'::text, 'chiuso'::text]))),
    CONSTRAINT presenze_stato_check CHECK ((stato = ANY (ARRAY['presente'::text, 'assente'::text, 'ferie'::text, 'malattia'::text, 'permesso'::text])))
);


--
-- Name: prezziario_dei; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prezziario_dei (
    id uuid DEFAULT uuidv7() NOT NULL,
    codice text NOT NULL,
    descrizione text NOT NULL,
    unita_misura text,
    prezzo_unitario numeric(12,4),
    incidenza_manodopera numeric(12,4),
    incidenza_materiali numeric(12,4),
    incidenza_noli numeric(12,4),
    rendimento_giornaliero numeric(10,4),
    squadra_tipo jsonb,
    attrezzature text[],
    categoria text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: qualifiche; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qualifiche (
    id uuid DEFAULT uuidv7() NOT NULL,
    nome text NOT NULL,
    descrizione text
);


--
-- Name: ruoli; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ruoli (
    id uuid DEFAULT uuidv7() NOT NULL,
    nome text NOT NULL,
    descrizione text
);


--
-- Name: settimane_presenze; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settimane_presenze (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_cantiere uuid NOT NULL,
    anno integer NOT NULL,
    settimana integer NOT NULL,
    stato text DEFAULT 'bozza'::text NOT NULL,
    id_chiuso_da uuid,
    chiuso_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT settimane_presenze_settimana_check CHECK (((settimana >= 1) AND (settimana <= 53))),
    CONSTRAINT settimane_presenze_stato_check CHECK ((stato = ANY (ARRAY['bozza'::text, 'confermato'::text, 'chiuso'::text])))
);


--
-- Name: tipi_documento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipi_documento (
    id uuid DEFAULT uuidv7() NOT NULL,
    nome text NOT NULL
);


--
-- Name: utenti; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.utenti (
    id uuid DEFAULT uuidv7() NOT NULL,
    id_ruolo uuid NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    nome text NOT NULL,
    cognome text NOT NULL,
    attivo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: assegnazioni_mezzi assegnazioni_mezzi_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assegnazioni_mezzi
    ADD CONSTRAINT assegnazioni_mezzi_pkey PRIMARY KEY (id);


--
-- Name: attivita_gantt attivita_gantt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attivita_gantt
    ADD CONSTRAINT attivita_gantt_pkey PRIMARY KEY (id);


--
-- Name: avanzamento_cantieri avanzamento_cantieri_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avanzamento_cantieri
    ADD CONSTRAINT avanzamento_cantieri_pkey PRIMARY KEY (id);


--
-- Name: cantieri_operai cantieri_operai_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantieri_operai
    ADD CONSTRAINT cantieri_operai_pkey PRIMARY KEY (id);


--
-- Name: cantieri cantieri_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantieri
    ADD CONSTRAINT cantieri_pkey PRIMARY KEY (id);


--
-- Name: categorie_materiali categorie_materiali_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorie_materiali
    ADD CONSTRAINT categorie_materiali_pkey PRIMARY KEY (id);


--
-- Name: clienti clienti_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clienti
    ADD CONSTRAINT clienti_pkey PRIMARY KEY (id);


--
-- Name: computi computi_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.computi
    ADD CONSTRAINT computi_pkey PRIMARY KEY (id);


--
-- Name: computo_voci computo_voci_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.computo_voci
    ADD CONSTRAINT computo_voci_pkey PRIMARY KEY (id);


--
-- Name: documenti documenti_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenti
    ADD CONSTRAINT documenti_pkey PRIMARY KEY (id);


--
-- Name: fornitori fornitori_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornitori
    ADD CONSTRAINT fornitori_pkey PRIMARY KEY (id);


--
-- Name: materiali materiali_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiali
    ADD CONSTRAINT materiali_pkey PRIMARY KEY (id);


--
-- Name: mezzi mezzi_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mezzi
    ADD CONSTRAINT mezzi_pkey PRIMARY KEY (id);


--
-- Name: operai operai_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operai
    ADD CONSTRAINT operai_pkey PRIMARY KEY (id);


--
-- Name: operai_qualifiche operai_qualifiche_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operai_qualifiche
    ADD CONSTRAINT operai_qualifiche_pkey PRIMARY KEY (id_operaio, id_qualifica);


--
-- Name: presenze presenze_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presenze
    ADD CONSTRAINT presenze_pkey PRIMARY KEY (id);


--
-- Name: prezziario_dei prezziario_dei_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prezziario_dei
    ADD CONSTRAINT prezziario_dei_pkey PRIMARY KEY (id);


--
-- Name: qualifiche qualifiche_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qualifiche
    ADD CONSTRAINT qualifiche_pkey PRIMARY KEY (id);


--
-- Name: ruoli ruoli_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ruoli
    ADD CONSTRAINT ruoli_pkey PRIMARY KEY (id);


--
-- Name: settimane_presenze settimane_presenze_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settimane_presenze
    ADD CONSTRAINT settimane_presenze_pkey PRIMARY KEY (id);


--
-- Name: tipi_documento tipi_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipi_documento
    ADD CONSTRAINT tipi_documento_pkey PRIMARY KEY (id);


--
-- Name: avanzamento_cantieri uq_avanzamento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avanzamento_cantieri
    ADD CONSTRAINT uq_avanzamento UNIQUE (id_cantiere, data_rilevazione);


--
-- Name: cantieri_operai uq_cantieri_operai; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantieri_operai
    ADD CONSTRAINT uq_cantieri_operai UNIQUE (id_cantiere, id_operaio, data_inizio);


--
-- Name: categorie_materiali uq_categorie_materiali; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorie_materiali
    ADD CONSTRAINT uq_categorie_materiali UNIQUE (nome);


--
-- Name: operai uq_operai_cf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operai
    ADD CONSTRAINT uq_operai_cf UNIQUE (codice_fiscale);


--
-- Name: presenze uq_presenze; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presenze
    ADD CONSTRAINT uq_presenze UNIQUE (id_cantiere, id_operaio, data);


--
-- Name: prezziario_dei uq_prezziario_dei_codice; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prezziario_dei
    ADD CONSTRAINT uq_prezziario_dei_codice UNIQUE (codice);


--
-- Name: qualifiche uq_qualifiche_nome; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qualifiche
    ADD CONSTRAINT uq_qualifiche_nome UNIQUE (nome);


--
-- Name: ruoli uq_ruoli_nome; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ruoli
    ADD CONSTRAINT uq_ruoli_nome UNIQUE (nome);


--
-- Name: settimane_presenze uq_settimane; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settimane_presenze
    ADD CONSTRAINT uq_settimane UNIQUE (id_cantiere, anno, settimana);


--
-- Name: tipi_documento uq_tipi_documento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipi_documento
    ADD CONSTRAINT uq_tipi_documento UNIQUE (nome);


--
-- Name: utenti utenti_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.utenti
    ADD CONSTRAINT utenti_pkey PRIMARY KEY (id);


--
-- Name: idx_ass_mezzi_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ass_mezzi_date ON public.assegnazioni_mezzi USING btree (data_inizio, data_fine);


--
-- Name: idx_ass_mezzi_id_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ass_mezzi_id_cantiere ON public.assegnazioni_mezzi USING btree (id_cantiere);


--
-- Name: idx_ass_mezzi_id_mezzo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ass_mezzi_id_mezzo ON public.assegnazioni_mezzi USING btree (id_mezzo);


--
-- Name: idx_avanz_data_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_avanz_data_brin ON public.avanzamento_cantieri USING brin (data_rilevazione);


--
-- Name: idx_avanz_id_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_avanz_id_cantiere ON public.avanzamento_cantieri USING btree (id_cantiere);


--
-- Name: idx_cantieri_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cantieri_date ON public.cantieri USING btree (data_inizio, data_fine_prevista);


--
-- Name: idx_cantieri_id_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cantieri_id_cliente ON public.cantieri USING btree (id_cliente);


--
-- Name: idx_cantieri_id_responsabile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cantieri_id_responsabile ON public.cantieri USING btree (id_responsabile);


--
-- Name: idx_cantieri_stato; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cantieri_stato ON public.cantieri USING btree (stato);


--
-- Name: idx_co_id_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_co_id_cantiere ON public.cantieri_operai USING btree (id_cantiere);


--
-- Name: idx_co_id_operaio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_co_id_operaio ON public.cantieri_operai USING btree (id_operaio);


--
-- Name: idx_computi_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_computi_cantiere ON public.computi USING btree (id_cantiere);


--
-- Name: idx_computo_voci_codice_dei; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_computo_voci_codice_dei ON public.computo_voci USING btree (codice_dei);


--
-- Name: idx_computo_voci_computo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_computo_voci_computo ON public.computo_voci USING btree (id_computo);


--
-- Name: idx_dei_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dei_categoria ON public.prezziario_dei USING btree (categoria);


--
-- Name: idx_dei_codice; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dei_codice ON public.prezziario_dei USING btree (codice);


--
-- Name: idx_documenti_id_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_documenti_id_cantiere ON public.documenti USING btree (id_cantiere);


--
-- Name: idx_documenti_id_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_documenti_id_tipo ON public.documenti USING btree (id_tipo);


--
-- Name: idx_documenti_scadenza; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_documenti_scadenza ON public.documenti USING btree (data_scadenza);


--
-- Name: idx_gantt_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gantt_date ON public.attivita_gantt USING btree (data_inizio_prevista, data_fine_prevista);


--
-- Name: idx_gantt_id_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gantt_id_cantiere ON public.attivita_gantt USING btree (id_cantiere);


--
-- Name: idx_gantt_id_padre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gantt_id_padre ON public.attivita_gantt USING btree (id_padre);


--
-- Name: idx_gantt_ordine; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gantt_ordine ON public.attivita_gantt USING btree (id_cantiere, ordine);


--
-- Name: idx_materiali_id_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materiali_id_cantiere ON public.materiali USING btree (id_cantiere);


--
-- Name: idx_materiali_id_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materiali_id_categoria ON public.materiali USING btree (id_categoria);


--
-- Name: idx_materiali_id_fornitore; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materiali_id_fornitore ON public.materiali USING btree (id_fornitore);


--
-- Name: idx_materiali_stato; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materiali_stato ON public.materiali USING btree (stato);


--
-- Name: idx_mezzi_scadenze; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mezzi_scadenze ON public.mezzi USING btree (data_revisione, data_scadenza_assicurazione);


--
-- Name: idx_mezzi_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mezzi_tipo ON public.mezzi USING btree (tipo);


--
-- Name: idx_operai_attivo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_operai_attivo ON public.operai USING btree (attivo);


--
-- Name: idx_operai_id_utente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_operai_id_utente ON public.operai USING btree (id_utente);


--
-- Name: idx_oq_id_qualifica; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oq_id_qualifica ON public.operai_qualifiche USING btree (id_qualifica);


--
-- Name: idx_presenze_cantiere_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_presenze_cantiere_data ON public.presenze USING btree (id_cantiere, data);


--
-- Name: idx_presenze_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_presenze_data ON public.presenze USING btree (data);


--
-- Name: idx_presenze_id_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_presenze_id_cantiere ON public.presenze USING btree (id_cantiere);


--
-- Name: idx_presenze_id_operaio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_presenze_id_operaio ON public.presenze USING btree (id_operaio);


--
-- Name: idx_presenze_id_settimana; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_presenze_id_settimana ON public.presenze USING btree (id_settimana);


--
-- Name: idx_presenze_stato_appr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_presenze_stato_appr ON public.presenze USING btree (stato_approvazione);


--
-- Name: idx_prezziario_dei_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prezziario_dei_categoria ON public.prezziario_dei USING btree (categoria);


--
-- Name: idx_prezziario_dei_codice; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prezziario_dei_codice ON public.prezziario_dei USING btree (codice);


--
-- Name: idx_prezziario_dei_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prezziario_dei_fts ON public.prezziario_dei USING gin (to_tsvector('italian'::regconfig, COALESCE(descrizione, ''::text)));


--
-- Name: idx_settimane_anno_sett; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settimane_anno_sett ON public.settimane_presenze USING btree (anno, settimana);


--
-- Name: idx_settimane_id_cantiere; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settimane_id_cantiere ON public.settimane_presenze USING btree (id_cantiere);


--
-- Name: idx_utenti_email_lower; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_utenti_email_lower ON public.utenti USING btree (lower(email));


--
-- Name: idx_utenti_id_ruolo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_utenti_id_ruolo ON public.utenti USING btree (id_ruolo);


--
-- Name: idx_utenti_username_lower; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_utenti_username_lower ON public.utenti USING btree (lower(username));


--
-- Name: uq_utenti_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_utenti_email ON public.utenti USING btree (lower(email));


--
-- Name: uq_utenti_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_utenti_username ON public.utenti USING btree (lower(username));


--
-- Name: attivita_gantt trg_attivita_gantt_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_attivita_gantt_updated_at BEFORE UPDATE ON public.attivita_gantt FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: cantieri trg_cantieri_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cantieri_updated_at BEFORE UPDATE ON public.cantieri FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: clienti trg_clienti_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_clienti_updated_at BEFORE UPDATE ON public.clienti FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: documenti trg_documenti_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_documenti_updated_at BEFORE UPDATE ON public.documenti FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: fornitori trg_fornitori_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_fornitori_updated_at BEFORE UPDATE ON public.fornitori FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: materiali trg_materiali_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_materiali_updated_at BEFORE UPDATE ON public.materiali FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: mezzi trg_mezzi_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_mezzi_updated_at BEFORE UPDATE ON public.mezzi FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: operai trg_operai_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_operai_updated_at BEFORE UPDATE ON public.operai FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: presenze trg_presenze_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_presenze_updated_at BEFORE UPDATE ON public.presenze FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: prezziario_dei trg_prezziario_dei_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_prezziario_dei_updated_at BEFORE UPDATE ON public.prezziario_dei FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: settimane_presenze trg_settimane_presenze_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_settimane_presenze_updated_at BEFORE UPDATE ON public.settimane_presenze FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: utenti trg_utenti_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_utenti_updated_at BEFORE UPDATE ON public.utenti FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: assegnazioni_mezzi assegnazioni_mezzi_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assegnazioni_mezzi
    ADD CONSTRAINT assegnazioni_mezzi_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE CASCADE;


--
-- Name: assegnazioni_mezzi assegnazioni_mezzi_id_mezzo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assegnazioni_mezzi
    ADD CONSTRAINT assegnazioni_mezzi_id_mezzo_fkey FOREIGN KEY (id_mezzo) REFERENCES public.mezzi(id) ON DELETE CASCADE;


--
-- Name: attivita_gantt attivita_gantt_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attivita_gantt
    ADD CONSTRAINT attivita_gantt_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE CASCADE;


--
-- Name: attivita_gantt attivita_gantt_id_padre_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attivita_gantt
    ADD CONSTRAINT attivita_gantt_id_padre_fkey FOREIGN KEY (id_padre) REFERENCES public.attivita_gantt(id) ON DELETE CASCADE;


--
-- Name: avanzamento_cantieri avanzamento_cantieri_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avanzamento_cantieri
    ADD CONSTRAINT avanzamento_cantieri_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE CASCADE;


--
-- Name: cantieri cantieri_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantieri
    ADD CONSTRAINT cantieri_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clienti(id) ON DELETE RESTRICT;


--
-- Name: cantieri cantieri_id_responsabile_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantieri
    ADD CONSTRAINT cantieri_id_responsabile_fkey FOREIGN KEY (id_responsabile) REFERENCES public.utenti(id) ON DELETE SET NULL;


--
-- Name: cantieri_operai cantieri_operai_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantieri_operai
    ADD CONSTRAINT cantieri_operai_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE CASCADE;


--
-- Name: cantieri_operai cantieri_operai_id_operaio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantieri_operai
    ADD CONSTRAINT cantieri_operai_id_operaio_fkey FOREIGN KEY (id_operaio) REFERENCES public.operai(id) ON DELETE CASCADE;


--
-- Name: computi computi_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.computi
    ADD CONSTRAINT computi_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE CASCADE;


--
-- Name: computo_voci computo_voci_id_computo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.computo_voci
    ADD CONSTRAINT computo_voci_id_computo_fkey FOREIGN KEY (id_computo) REFERENCES public.computi(id) ON DELETE CASCADE;


--
-- Name: documenti documenti_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenti
    ADD CONSTRAINT documenti_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE SET NULL;


--
-- Name: documenti documenti_id_caricato_da_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenti
    ADD CONSTRAINT documenti_id_caricato_da_fkey FOREIGN KEY (id_caricato_da) REFERENCES public.utenti(id) ON DELETE SET NULL;


--
-- Name: documenti documenti_id_tipo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenti
    ADD CONSTRAINT documenti_id_tipo_fkey FOREIGN KEY (id_tipo) REFERENCES public.tipi_documento(id) ON DELETE RESTRICT;


--
-- Name: materiali materiali_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiali
    ADD CONSTRAINT materiali_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE CASCADE;


--
-- Name: materiali materiali_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiali
    ADD CONSTRAINT materiali_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categorie_materiali(id) ON DELETE SET NULL;


--
-- Name: materiali materiali_id_fornitore_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiali
    ADD CONSTRAINT materiali_id_fornitore_fkey FOREIGN KEY (id_fornitore) REFERENCES public.fornitori(id) ON DELETE SET NULL;


--
-- Name: operai operai_id_utente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operai
    ADD CONSTRAINT operai_id_utente_fkey FOREIGN KEY (id_utente) REFERENCES public.utenti(id) ON DELETE SET NULL;


--
-- Name: operai_qualifiche operai_qualifiche_id_operaio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operai_qualifiche
    ADD CONSTRAINT operai_qualifiche_id_operaio_fkey FOREIGN KEY (id_operaio) REFERENCES public.operai(id) ON DELETE CASCADE;


--
-- Name: operai_qualifiche operai_qualifiche_id_qualifica_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operai_qualifiche
    ADD CONSTRAINT operai_qualifiche_id_qualifica_fkey FOREIGN KEY (id_qualifica) REFERENCES public.qualifiche(id) ON DELETE CASCADE;


--
-- Name: presenze presenze_id_approvato_da_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presenze
    ADD CONSTRAINT presenze_id_approvato_da_fkey FOREIGN KEY (id_approvato_da) REFERENCES public.utenti(id) ON DELETE SET NULL;


--
-- Name: presenze presenze_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presenze
    ADD CONSTRAINT presenze_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE CASCADE;


--
-- Name: presenze presenze_id_operaio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presenze
    ADD CONSTRAINT presenze_id_operaio_fkey FOREIGN KEY (id_operaio) REFERENCES public.operai(id) ON DELETE CASCADE;


--
-- Name: presenze presenze_id_registrato_da_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presenze
    ADD CONSTRAINT presenze_id_registrato_da_fkey FOREIGN KEY (id_registrato_da) REFERENCES public.utenti(id) ON DELETE SET NULL;


--
-- Name: presenze presenze_id_settimana_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presenze
    ADD CONSTRAINT presenze_id_settimana_fkey FOREIGN KEY (id_settimana) REFERENCES public.settimane_presenze(id) ON DELETE SET NULL;


--
-- Name: settimane_presenze settimane_presenze_id_cantiere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settimane_presenze
    ADD CONSTRAINT settimane_presenze_id_cantiere_fkey FOREIGN KEY (id_cantiere) REFERENCES public.cantieri(id) ON DELETE CASCADE;


--
-- Name: settimane_presenze settimane_presenze_id_chiuso_da_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settimane_presenze
    ADD CONSTRAINT settimane_presenze_id_chiuso_da_fkey FOREIGN KEY (id_chiuso_da) REFERENCES public.utenti(id) ON DELETE SET NULL;


--
-- Name: utenti utenti_id_ruolo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.utenti
    ADD CONSTRAINT utenti_id_ruolo_fkey FOREIGN KEY (id_ruolo) REFERENCES public.ruoli(id) ON DELETE RESTRICT;


--
-- Name: cantieri; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cantieri ENABLE ROW LEVEL SECURITY;

--
-- Name: documenti; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.documenti ENABLE ROW LEVEL SECURITY;

--
-- Name: cantieri pol_cantieri_app; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pol_cantieri_app ON public.cantieri TO app_user USING (true) WITH CHECK (true);


--
-- Name: cantieri pol_cantieri_owner; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pol_cantieri_owner ON public.cantieri TO app_owner USING (true) WITH CHECK (true);


--
-- Name: documenti pol_documenti_app; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pol_documenti_app ON public.documenti TO app_user USING (true) WITH CHECK (true);


--
-- Name: documenti pol_documenti_owner; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pol_documenti_owner ON public.documenti TO app_owner USING (true) WITH CHECK (true);


--
-- Name: presenze pol_presenze_app; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pol_presenze_app ON public.presenze TO app_user USING (true) WITH CHECK (true);


--
-- Name: presenze pol_presenze_owner; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pol_presenze_owner ON public.presenze TO app_owner USING (true) WITH CHECK (true);


--
-- Name: settimane_presenze pol_settimane_app; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pol_settimane_app ON public.settimane_presenze TO app_user USING (true) WITH CHECK (true);


--
-- Name: settimane_presenze pol_settimane_owner; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pol_settimane_owner ON public.settimane_presenze TO app_owner USING (true) WITH CHECK (true);


--
-- Name: presenze; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.presenze ENABLE ROW LEVEL SECURITY;

--
-- Name: settimane_presenze; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.settimane_presenze ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict heLeq8uzfsekg95XfLSXqXZkXtP3grLTcFr3LWKZtfqF18PGKA3cDDxTb94MDv7

