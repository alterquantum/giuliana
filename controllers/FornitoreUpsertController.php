<?php
namespace controllers;

require_once __DIR__ . '/../models/FornitoreUpsertModel.php';
require_once __DIR__ . '/../services/Response.php';

use models\FornitoreUpsertModel;
use services\Response;

class FornitoreUpsertController {
    private array $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function upsert(): array {
        try {
            $row = (new FornitoreUpsertModel())->upsert($this->data);
            $this->response->setRes('ok');
            $this->response->setDbRes($row);
            $this->response->setMsg('Fornitore salvato con successo.');
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore nel salvataggio: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
