<?php
namespace models;

require_once __DIR__ . '/../database/Connection.php';

use database\Connection;

class TipoDocumentoListModel {
    private \PDO $pdo;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $this->pdo = (new Connection($config))->getPDO();
    }

    public function list(): array {
        return $this->pdo->query('SELECT id::text, nome FROM tipi_documento ORDER BY nome')->fetchAll(\PDO::FETCH_ASSOC);
    }
}
