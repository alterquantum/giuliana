-- ════════════════════════════════════════════════════════════
-- MIGRATION: Prezziario DEI / Prezzari Regionali
-- ════════════════════════════════════════════════════════════

-- ── TABELLA ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS prezziario_dei (
    id                      UUID        DEFAULT uuidv7() PRIMARY KEY,
    codice                  TEXT        NOT NULL UNIQUE,
    descrizione             TEXT,
    unita_misura            TEXT,
    prezzo_unitario         NUMERIC(12,4),
    incidenza_manodopera    NUMERIC(12,4),
    incidenza_materiali     NUMERIC(12,4),
    incidenza_noli          NUMERIC(12,4),
    rendimento_giornaliero  NUMERIC(12,6),
    squadra_tipo            JSONB,
    attrezzature            TEXT[],
    categoria               TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_prezziario_dei_codice    ON prezziario_dei (codice);
CREATE INDEX IF NOT EXISTS idx_prezziario_dei_categoria ON prezziario_dei (categoria);
CREATE INDEX IF NOT EXISTS idx_prezziario_dei_fts
    ON prezziario_dei USING gin(to_tsvector('italian', coalesce(descrizione,'')));

-- Trigger updated_at (riusa la funzione già presente nel DB)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_prezziario_dei_updated_at'
    ) THEN
        CREATE TRIGGER trg_prezziario_dei_updated_at
        BEFORE UPDATE ON prezziario_dei
        FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
    END IF;
END $$;

-- ── GRANT ────────────────────────────────────────────────────
GRANT ALL                            ON prezziario_dei TO app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON prezziario_dei TO app_user;

-- ── FUNZIONI ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION upsert_prezziario_dei(
    p_codice                 TEXT,
    p_descrizione            TEXT    DEFAULT NULL,
    p_unita_misura           TEXT    DEFAULT NULL,
    p_prezzo_unitario        NUMERIC DEFAULT NULL,
    p_incidenza_manodopera   NUMERIC DEFAULT NULL,
    p_incidenza_materiali    NUMERIC DEFAULT NULL,
    p_incidenza_noli         NUMERIC DEFAULT NULL,
    p_rendimento_giornaliero NUMERIC DEFAULT NULL,
    p_squadra_tipo           JSONB   DEFAULT NULL,
    p_attrezzature           TEXT[]  DEFAULT NULL,
    p_categoria              TEXT    DEFAULT NULL
)
RETURNS TABLE(id UUID, codice TEXT)
LANGUAGE plpgsql SECURITY INVOKER AS $$
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

GRANT EXECUTE ON FUNCTION upsert_prezziario_dei TO app_owner, app_user;


CREATE OR REPLACE FUNCTION list_prezziario_dei(
    p_search    TEXT DEFAULT NULL,
    p_categoria TEXT DEFAULT NULL
)
RETURNS TABLE(
    id                      UUID,
    codice                  TEXT,
    descrizione             TEXT,
    unita_misura            TEXT,
    prezzo_unitario         NUMERIC,
    incidenza_manodopera    NUMERIC,
    incidenza_materiali     NUMERIC,
    incidenza_noli          NUMERIC,
    rendimento_giornaliero  NUMERIC,
    categoria               TEXT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
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

GRANT EXECUTE ON FUNCTION list_prezziario_dei TO app_owner, app_user;


CREATE OR REPLACE FUNCTION get_prezziario_dei_by_codice(p_codice TEXT)
RETURNS TABLE(
    id                      UUID,
    codice                  TEXT,
    descrizione             TEXT,
    unita_misura            TEXT,
    prezzo_unitario         NUMERIC,
    incidenza_manodopera    NUMERIC,
    incidenza_materiali     NUMERIC,
    incidenza_noli          NUMERIC,
    rendimento_giornaliero  NUMERIC,
    categoria               TEXT
)
LANGUAGE plpgsql SECURITY INVOKER AS $$
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

GRANT EXECUTE ON FUNCTION get_prezziario_dei_by_codice TO app_owner, app_user;


CREATE OR REPLACE FUNCTION delete_prezziario_dei()
RETURNS void
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    DELETE FROM prezziario_dei;
END;
$$;

GRANT EXECUTE ON FUNCTION delete_prezziario_dei TO app_owner, app_user;
