<?php
namespace controllers;

require_once __DIR__ . '/../models/ClienteUpsertModel.php';
require_once __DIR__ . '/../services/Response.php';

use models\ClienteUpsertModel;
use services\Response;

class ClienteUpsertController {
    private array $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function upsert(): array {
        try {
            $row = (new ClienteUpsertModel())->upsert($this->data);
            $this->response->setRes('ok');
            $this->response->setDbRes($row);
            $this->response->setMsg('Cliente salvato con successo.');
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore nel salvataggio: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
