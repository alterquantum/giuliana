<?php
namespace controllers;

require_once __DIR__ . '/../models/GrigliaSettimanaleModel.php';
require_once __DIR__ . '/../views/GrigliaSettimanaleView.php';

use models\GrigliaSettimanaleModel;
use views\GrigliaSettimanaleView;

class GrigliaSettimanaleController {
    private array $data;

    public function __construct(array $data) {
        $this->data = $data;
    }

    public function render(): string {
        $idCantiere = $this->data['id_cantiere'] ?? '';
        $anno       = (int) ($this->data['anno']      ?? date('Y'));
        $settimana  = (int) ($this->data['settimana'] ?? date('W'));
        $rows       = (new GrigliaSettimanaleModel())->get($idCantiere, $anno, $settimana);
        return (new GrigliaSettimanaleView())->display($rows, $anno, $settimana);
    }
}
