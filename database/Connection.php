<?php
namespace database;

use PDO;

class Connection {
    private PDO $pdo;

    public function __construct(array $config) {
        $dsn = sprintf(
            '%s:host=%s;dbname=%s;port=%s',
            $config['driver'],
            $config['host'],
            $config['database'],
            $config['port']
        );
        $this->pdo = new PDO($dsn, $config['username'], $config['password'], $config['options'] ?? []);
    }

    public function getPDO(): PDO {
        return $this->pdo;
    }
}
