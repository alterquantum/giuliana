CREATE OR REPLACE FUNCTION public.get_utente_by_username(p_username text)
RETURNS TABLE(id uuid, username text, email text, password_hash text, nome text, cognome text, attivo boolean, ruolo text)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.username, u.email, u.password_hash,
           u.nome, u.cognome, u.attivo, r.nome
    FROM   utenti u
    JOIN   ruoli  r ON r.id = u.id_ruolo
    WHERE  LOWER(u.email)    = LOWER(p_username)
       OR  LOWER(u.username) = LOWER(p_username);
END;
$$;
