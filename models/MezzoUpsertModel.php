<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class MezzoUpsertModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function upsert(array $p): array {
        return $this->db->callOne('upsert_mezzo', [
            ($p['id']                          ?? null) ?: null,
            $p['nome']                         ?? null,
            $p['tipo']                         ?? null,
            ($p['targa']                       ?? null) ?: null,
            ($p['numero_seriale']              ?? null) ?: null,
            ($p['data_revisione']              ?? null) ?: null,
            ($p['data_scadenza_assicurazione'] ?? null) ?: null,
            ($p['note']                        ?? null) ?: null,
        ]);
    }
}
