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
        MAX(v.n_operai)                                     AS n_operai,
        d.squadra_tipo                                      AS specializzazioni,
        SUM(v.quantita * COALESCE(d.incidenza_materiali,0)) AS costo_materiali,
        SUM(v.quantita * COALESCE(d.incidenza_noli,0))      AS costo_noli,
        d.attrezzature
    FROM   computo_voci   v
    LEFT JOIN prezziario_dei d ON d.codice = v.codice_dei
    WHERE  v.id_computo = p_id_computo
    -- voci con lo stesso codice DEI aggregate; voci senza codice ognuna per sé
    GROUP BY COALESCE(v.codice_dei, v.id::text),
             v.codice_dei, d.descrizione, d.squadra_tipo, d.attrezzature
    ORDER BY durata_giorni DESC NULLS LAST;
END;
$$;
