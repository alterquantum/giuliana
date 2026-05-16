<?php
namespace controllers;

require_once __DIR__ . '/../models/FoglioGiornalieroModel.php';
require_once __DIR__ . '/../views/FoglioGiornalieroView.php';

use models\FoglioGiornalieroModel;
use views\FoglioGiornalieroView;

class FoglioGiornalieroController {
    private array $data;

    public function __construct(array $data) {
        $this->data = $data;
    }

    public function render(): string {
        $idCantiere = $this->data['id_cantiere'] ?? '';
        $data       = $this->data['data']        ?? date('Y-m-d');
        $rows       = (new FoglioGiornalieroModel())->get($idCantiere, $data);
        return (new FoglioGiornalieroView())->display($rows);
    }
}
