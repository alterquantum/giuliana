<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class CantiereUpsertModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function upsert(array $p): array {
        return $this->db->callOne('upsert_cantiere', [
            ($p['id']                 ?? null) ?: null,
            $p['nome']                ?? null,
            ($p['id_cliente']         ?? null) ?: null,
            ($p['id_responsabile']    ?? null) ?: null,
            ($p['indirizzo']          ?? null) ?: null,
            ($p['data_inizio']        ?? null) ?: null,
            ($p['data_fine_prevista'] ?? null) ?: null,
            $p['stato']               ?? null,
            ($p['importo_contratto']  ?? null) ?: null,
            ($p['tipo_lavori']        ?? null) ?: null,
            ($p['note']               ?? null) ?: null,
        ]);
    }
}
