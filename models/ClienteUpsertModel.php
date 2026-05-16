<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class ClienteUpsertModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function upsert(array $p): array {
        return $this->db->callOne('upsert_cliente', [
            $p['id']              ?? null,
            $p['ragione_sociale'] ?? null,
            $p['tipo']            ?? null,
            $p['piva']            ?? null,
            $p['codice_fiscale']  ?? null,
            $p['referente']       ?? null,
            $p['email']           ?? null,
            $p['telefono']        ?? null,
            $p['pec']             ?? null,
            $p['codice_sdi']      ?? null,
            $p['indirizzo']       ?? null,
            $p['note']            ?? null,
        ]);
    }
}
