# Migrations — GestioneCantieri

## Come ricreare il database da zero

```bash
# 1. Crea il DB (se non esiste)
createdb -h 127.0.0.1 -p 5433 -U postgres giuliana

# 2. Applica lo schema (tabelle, funzioni, trigger, indici)
psql -h 127.0.0.1 -p 5433 -U postgres -d giuliana -f schema.sql

# 3. Carica i dati di base (lookup tables + admin)
psql -h 127.0.0.1 -p 5433 -U postgres -d giuliana -f seed.sql
```

Dopo questi tre comandi il DB è pronto per la produzione con:
- Tabelle di lookup: `ruoli`, `qualifiche`, `tipi_documento`, `categorie_materiali`
- Admin: `giuliana.arch@gmail.com` / `Architetto1`

Il prezziario DEI va reimportato dall'interfaccia (Prezziario DEI → Importa PDF).

## File in questa cartella

| File | Scopo |
|------|-------|
| `schema.sql` | Schema completo generato da pg_dump (aggiornare ad ogni modifica strutturale) |
| `seed.sql` | Dati minimi di produzione |
| `reset_to_production.sql` | Svuota tutti i dati operativi e lascia solo l'admin |
| `add_prezziario_dei.sql` | Aggiunge tabella e funzioni prezziario DEI |
| `update_import_computo.sql` | Sposta join DEI in PostgreSQL |
| `fix_*.sql` | Fix incrementali alle funzioni SQL |
