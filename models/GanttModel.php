<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class GanttModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function getGantt(string $idCantiere): array {
        return $this->db->call('get_gantt_cantiere', [$idCantiere]);
    }

    public function getEvmPortfolio(): array {
        return $this->db->call('get_evm_portfolio', []);
    }

    public function getEvm(string $idCantiere): array {
        return $this->db->callOne('get_evm_cantiere', [$idCantiere]);
    }
}
