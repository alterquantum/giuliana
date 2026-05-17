<?php
namespace models;

require_once __DIR__ . '/../database/Database.php';
require_once __DIR__ . '/../database/Connection.php';

use database\Connection;
use database\Database;

class PrezziarioDeiImportModel {
    private Database $db;

    public function __construct() {
        $config     = require __DIR__ . '/../config/Database.php';
        $connection = new Connection($config);
        $this->db   = new Database($connection->getPDO());
    }

    public function upsertVoce(array $v): array {
        return $this->db->callOne('upsert_prezziario_dei', [
            $v['codice']                 ?? null,
            $v['descrizione']            ?? null,
            $v['unita_misura']           ?? null,
            ($v['prezzo_unitario']       ?? null) ?: null,
            ($v['incidenza_manodopera']  ?? null) ?: null,
            ($v['incidenza_materiali']   ?? null) ?: null,
            ($v['incidenza_noli']        ?? null) ?: null,
            ($v['rendimento_giornaliero'] ?? null) ?: null,
            isset($v['squadra_tipo']) && $v['squadra_tipo']
                ? json_encode($v['squadra_tipo']) : null,
            isset($v['attrezzature']) && $v['attrezzature']
                ? '{' . implode(',', array_map(fn($a) => '"' . addslashes($a) . '"', $v['attrezzature'])) . '}'
                : null,
            $v['categoria']              ?? null,
        ]);
    }

    public function truncate(): void {
        $this->db->callOne('delete_prezziario_dei', []);
    }
}
