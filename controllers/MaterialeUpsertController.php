<?php
namespace controllers;

require_once __DIR__ . '/../models/MaterialeUpsertModel.php';
require_once __DIR__ . '/../services/Response.php';

use models\MaterialeUpsertModel;
use services\Response;

class MaterialeUpsertController {
    private array $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function upsert(): array {
        try {
            $row = (new MaterialeUpsertModel())->upsert($this->data);
            $this->response->setRes('ok');
            $this->response->setDbRes($row);
            $this->response->setMsg('Materiale salvato con successo.');
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
