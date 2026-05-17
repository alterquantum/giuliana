<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class PrezziarioDeiListModel {
    private Database $db;

    public function __construct() {
        $config         = require __DIR__ . '/../config/Database.php';
        $connection     = new Connection($config);
        $this->db       = new Database($connection->getPDO());
    }

    public function list(?string $search = null, ?string $categoria = null): array {
        return $this->db->call('list_prezziario_dei', [$search, $categoria]);
    }

    public function getByCodice(string $codice): array {
        return $this->db->callOne('get_prezziario_dei_by_codice', [$codice]);
    }
}
