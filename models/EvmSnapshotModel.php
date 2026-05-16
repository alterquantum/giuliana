<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class EvmSnapshotModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function snapshot(array $p): array {
        return $this->db->callOne('registra_snapshot_evm', [
            $p['id_cantiere'] ?? null,
            $p['bac']         ?? null,
            $p['pv']          ?? null,
            $p['ev']          ?? null,
            $p['ac']          ?? null,
            $p['nota']        ?? null,
            $p['data']        ?? null,
        ]);
    }
}
