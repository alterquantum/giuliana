<?php
namespace controllers;

require_once __DIR__ . '/../models/EvmSnapshotModel.php';
require_once __DIR__ . '/../services/Response.php';

use models\EvmSnapshotModel;
use services\Response;

class EvmSnapshotController {
    private array $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function snapshot(): array {
        try {
            $row = (new EvmSnapshotModel())->snapshot($this->data);
            $this->response->setRes('ok');
            $this->response->setDbRes($row);
            $this->response->setMsg('Snapshot EVM registrato con successo.');
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
