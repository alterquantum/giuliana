<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class SettimanaChiudiModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function chiudi(string $idCantiere, int $anno, int $settimana, string $idUtente): array {
        return $this->db->callOne('chiudi_settimana', [$idCantiere, $anno, $settimana, $idUtente]);
    }
}
