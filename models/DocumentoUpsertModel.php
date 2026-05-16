<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class DocumentoUpsertModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function upsert(array $p): array {
        return $this->db->callOne('upsert_documento', [
            ($p['id']             ?? null) ?: null,
            ($p['id_tipo']        ?? null) ?: null,
            $p['nome']            ?? null,
            ($p['id_cantiere']    ?? null) ?: null,
            ($p['descrizione']    ?? null) ?: null,
            ($p['percorso_file']  ?? null) ?: null,
            ($p['tipo_file']      ?? null) ?: null,
            ($p['data_emissione'] ?? null) ?: null,
            ($p['data_scadenza']  ?? null) ?: null,
            ($p['id_caricato_da'] ?? null) ?: null,
        ]);
    }
}
