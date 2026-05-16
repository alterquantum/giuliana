<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class MaterialeUpsertModel {
    private Database $db;

    public function __construct() {
        $config = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db = new Database($connection->getPDO());
    }

    public function upsert(array $p): array {
        return $this->db->callOne('upsert_materiale', [
            ($p['id']                    ?? null) ?: null,
            ($p['id_cantiere']           ?? null) ?: null,
            $p['descrizione']            ?? null,
            ($p['quantita']              ?? null) ?: null,
            ($p['unita_misura']          ?? null) ?: null,
            ($p['costo_unitario']        ?? null) ?: null,
            ($p['id_fornitore']          ?? null) ?: null,
            ($p['id_categoria']          ?? null) ?: null,
            $p['stato']                  ?? null,
            ($p['data_ordine']           ?? null) ?: null,
            ($p['data_consegna_prevista'] ?? null) ?: null,
            ($p['note']                  ?? null) ?: null,
        ]);
    }
}
