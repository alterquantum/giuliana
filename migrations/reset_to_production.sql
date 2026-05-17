-- Reset DB a produzione: svuota tutti i dati operativi, lascia solo tabelle di lookup
-- e crea l'unico utente admin

BEGIN;

-- Dati operativi (CASCADE gestisce le FK)
TRUNCATE TABLE
    presenze,
    settimane_presenze,
    cantieri_operai,
    assegnazioni_mezzi,
    avanzamento_cantieri,
    attivita_gantt,
    computo_voci,
    computi,
    documenti,
    materiali,
    mezzi,
    operai_qualifiche,
    operai,
    cantieri,
    clienti,
    fornitori,
    utenti
CASCADE;

-- Inserisce admin
INSERT INTO utenti (id_ruolo, username, email, password_hash, nome, cognome, attivo)
SELECT
    r.id,
    'giuliana.arch',
    'giuliana.arch@gmail.com',
    '$2y$10$85KV50LL.TKiX93Brzagwegzrytz7sg41TDMI.2z/RZ3jOyeywOKi',
    'Giuliana',
    'Arch',
    true
FROM ruoli r WHERE r.nome = 'admin';

COMMIT;
