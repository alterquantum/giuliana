<?php
namespace controllers;

require_once __DIR__ . '/../models/OperaioToggleModel.php';
require_once __DIR__ . '/../services/Response.php';

use models\OperaioToggleModel;
use services\Response;

class OperaioToggleController {
    private array $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function toggle(): array {
        try {
            $id  = $this->data['id'] ?? '';
            $row = (new OperaioToggleModel())->toggle($id);
            $this->response->setRes('ok');
            $this->response->setDbRes($row);
            $this->response->setMsg('Stato operaio aggiornato.');
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
