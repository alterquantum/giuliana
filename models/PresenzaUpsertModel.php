<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class PresenzaUpsertModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function upsert(array $p): array {
        return $this->db->callOne('upsert_presenza', [
            $p['id_cantiere']        ?? null,
            $p['id_operaio']         ?? null,
            $p['data']               ?? null,
            $p['stato']              ?? null,
            $p['ore_ordinarie']      ?? null,
            $p['ore_straordinarie']  ?? null,
            $p['note']               ?? null,
            $p['id_registrato_da']   ?? null,
        ]);
    }
}
