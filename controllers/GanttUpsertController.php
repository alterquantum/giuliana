<?php
namespace controllers;

require_once __DIR__ . '/../models/GanttUpsertModel.php';
require_once __DIR__ . '/../services/Response.php';

use models\GanttUpsertModel;
use services\Response;

class GanttUpsertController {
    private array $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function upsert(): array {
        try {
            $row = (new GanttUpsertModel())->upsert($this->data);
            $this->response->setRes('ok');
            $this->response->setDbRes($row);
            $this->response->setMsg('Attività salvata con successo.');
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
