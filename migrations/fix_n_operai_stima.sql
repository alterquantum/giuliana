-- Tariffa giornaliera media CCNL edilizia Campania 2024
-- (operaio qualificato ~58 €/giornata)
-- n_operai = ROUND( (prezzo * incidenza% / 100) / (rendimento * 58) )

CREATE OR REPLACE FUNCTION public.import_computo(
    p_id_cantiere uuid,
    p_nome_file   text,
    p_importo     numeric,
    p_voci        jsonb
)
RETURNS TABLE(id_computo uuid, n_voci integer)
LANGUAGE plpgsql AS $$
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


CREATE OR REPLACE FUNCTION public.analisi_computo(p_id_computo uuid)
RETURNS TABLE(
    codice_dei              text,
    descrizione_lavorazione text,
    unita_misura            text,
    quantita_totale         numeric,
    importo_totale          numeric,
    durata_giorni           numeric,
    n_operai                integer,
    specializzazioni        jsonb,
    costo_materiali         numeric,
    costo_noli              numeric,
    attrezzature            text[]
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
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
