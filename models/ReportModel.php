<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class ReportModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function getData(): array {
        return [
            'evm'            => $this->db->call('get_evm_portfolio', []),
            'doc_scadenza'   => $this->db->call('get_documenti_in_scadenza', [30]),
            'mezzi_scadenza' => $this->db->call('get_mezzi_in_scadenza', [30]),
        ];
    }
}
