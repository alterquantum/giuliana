<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class ComputiImportModel {
    private Database $db;

    public function __construct() {
        $config     = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db   = new Database($connection->getPDO());
    }

    public function importa(string $idCantiere, string $nomeFile, float $importoTotale, array $voci): array {
        return $this->db->callOne('import_computo', [
            $idCantiere,
            $nomeFile,
            $importoTotale ?: null,
            json_encode($voci),
        ]);
    }

    public function elimina(string $id): void {
        $this->db->callOne('delete_computo', [$id]);
    }

    public function getDeiRendimento(string $codice): array {
        return $this->db->callOne('get_prezziario_dei_by_codice', [$codice]);
    }
}
