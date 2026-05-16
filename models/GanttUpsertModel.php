<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class GanttUpsertModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function upsert(array $p): array {
        return $this->db->callOne('upsert_attivita_gantt', [
            ($p['id']                       ?? null) ?: null,
            ($p['id_cantiere']              ?? null) ?: null,
            $p['nome']                      ?? null,
            ($p['data_inizio_prevista']     ?? null) ?: null,
            ($p['data_fine_prevista']       ?? null) ?: null,
            ($p['id_padre']                 ?? null) ?: null,
            ($p['percentuale_completamento'] ?? null) ?: null,
            ($p['budget_previsto']          ?? null) ?: null,
            ($p['costo_effettivo']          ?? null) ?: null,
            ($p['data_inizio_effettiva']    ?? null) ?: null,
            ($p['data_fine_effettiva']      ?? null) ?: null,
            ($p['ordine']                   ?? null) ?: null,
        ]);
    }
}
