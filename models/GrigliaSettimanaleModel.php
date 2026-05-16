<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class GrigliaSettimanaleModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function get(string $idCantiere, int $anno, int $settimana): array {
        return $this->db->call('get_griglia_settimanale', [$idCantiere, $anno, $settimana]);
    }
}
