-- Update list functions to include FK IDs and additional fields for modal pre-population

DROP FUNCTION IF EXISTS list_operai(boolean, uuid, text);
CREATE FUNCTION public.list_operai(p_attivo boolean DEFAULT NULL::boolean, p_id_qualifica uuid DEFAULT NULL::uuid, p_search text DEFAULT NULL::text)
RETURNS TABLE(id uuid, nome text, cognome text, codice_fiscale text, data_nascita date, telefono text, email text, data_assunzione date, attivo boolean, qualifiche text[])
LANGUAGE plpgsql AS $$
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

DROP FUNCTION IF EXISTS list_cantieri(text, uuid, text);
CREATE FUNCTION public.list_cantieri(p_stato text DEFAULT NULL::text, p_id_cliente uuid DEFAULT NULL::uuid, p_search text DEFAULT NULL::text)
RETURNS TABLE(id uuid, id_cliente uuid, nome text, stato text, cliente text, responsabile text, indirizzo text, data_inizio date, data_fine_prevista date, importo_contratto numeric, pct_completamento numeric, tipo_lavori text, note text)
LANGUAGE plpgsql AS $$
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

DROP FUNCTION IF EXISTS list_clienti(text, text);
CREATE FUNCTION public.list_clienti(p_tipo text DEFAULT NULL::text, p_search text DEFAULT NULL::text)
RETURNS TABLE(id uuid, ragione_sociale text, tipo text, piva text, codice_fiscale text, referente text, email text, telefono text, indirizzo text, note text, n_cantieri bigint, attivo boolean)
LANGUAGE plpgsql AS $$
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

DROP FUNCTION IF EXISTS list_fornitori(text, text);
CREATE FUNCTION public.list_fornitori(p_categoria text DEFAULT NULL::text, p_search text DEFAULT NULL::text)
RETURNS TABLE(id uuid, ragione_sociale text, categoria text, piva text, referente text, email text, telefono text, iban text, indirizzo text, note text, attivo boolean)
LANGUAGE plpgsql AS $$
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

DROP FUNCTION IF EXISTS list_materiali(uuid, text);
CREATE FUNCTION public.list_materiali(p_id_cantiere uuid DEFAULT NULL::uuid, p_stato text DEFAULT NULL::text)
RETURNS TABLE(id uuid, id_cantiere uuid, id_fornitore uuid, id_categoria uuid, cantiere text, fornitore text, categoria text, descrizione text, quantita numeric, unita_misura text, costo_unitario numeric, totale numeric, stato text, data_ordine date, data_consegna_prevista date, data_consegna_effettiva date, note text)
LANGUAGE plpgsql AS $$
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

DROP FUNCTION IF EXISTS list_documenti(uuid, uuid);
CREATE FUNCTION public.list_documenti(p_id_cantiere uuid DEFAULT NULL::uuid, p_id_tipo uuid DEFAULT NULL::uuid)
RETURNS TABLE(id uuid, id_tipo uuid, id_cantiere uuid, nome text, tipo text, cantiere text, caricato_da text, tipo_file text, data_emissione date, data_scadenza date, gg_scadenza integer)
LANGUAGE plpgsql AS $$
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
