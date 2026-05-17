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
        CASE
            WHEN d.rendimento_giornaliero > 0
            THEN ROUND(COALESCE((v->>'quantita')::NUMERIC, 0) / d.rendimento_giornaliero, 2)
        END,
        CASE
            WHEN d.squadra_tipo IS NOT NULL
            THEN (SELECT SUM(val::int) FROM jsonb_each_text(d.squadra_tipo) AS t(key, val))
        END
    FROM jsonb_array_elements(p_voci) AS v
    LEFT JOIN prezziario_dei d ON d.codice = NULLIF(v->>'codice_dei', '');

    GET DIAGNOSTICS v_n = ROW_COUNT;
    RETURN QUERY SELECT v_id, v_n;
END;
$$;
