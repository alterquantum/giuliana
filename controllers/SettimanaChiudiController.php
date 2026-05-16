<?php
namespace controllers;

require_once __DIR__ . '/../models/SettimanaChiudiModel.php';
require_once __DIR__ . '/../services/Response.php';

use models\SettimanaChiudiModel;
use services\Response;

class SettimanaChiudiController {
    private array $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function chiudi(): array {
        try {
            $idCantiere = $this->data['id_cantiere'] ?? '';
            $anno       = (int) ($this->data['anno']      ?? date('Y'));
            $settimana  = (int) ($this->data['settimana'] ?? date('W'));
            $idUtente   = $this->data['id_utente'] ?? '';

            $row = (new SettimanaChiudiModel())->chiudi($idCantiere, $anno, $settimana, $idUtente);
            $this->response->setRes('ok');
            $this->response->setDbRes($row);
            $this->response->setMsg('Settimana chiusa con successo.');
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore nella chiusura: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
