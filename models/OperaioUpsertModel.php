<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class OperaioUpsertModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function upsert(array $p): array {
        return $this->db->callOne('upsert_operaio', [
            ($p['id']              ?? null) ?: null,
            $p['nome']             ?? null,
            $p['cognome']          ?? null,
            ($p['codice_fiscale']  ?? null) ?: null,
            ($p['data_nascita']    ?? null) ?: null,
            ($p['telefono']        ?? null) ?: null,
            ($p['email']           ?? null) ?: null,
            ($p['data_assunzione'] ?? null) ?: null,
        ]);
    }
}
