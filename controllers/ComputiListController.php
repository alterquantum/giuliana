<?php
namespace controllers;

require_once __DIR__ . '/../models/ComputiListModel.php';
require_once __DIR__ . '/../models/CantiereListModel.php';
require_once __DIR__ . '/../views/ComputiListView.php';

use models\ComputiListModel;
use models\CantiereListModel;
use views\ComputiListView;

class ComputiListController {
    private string $idCantiere;

    public function __construct(string $idCantiere = '') {
        $this->idCantiere = $idCantiere;
    }

    public function render(): string {
        $cantieri = (new CantiereListModel())->list();
        $computi  = $this->idCantiere !== ''
            ? (new ComputiListModel())->list($this->idCantiere)
            : [];
        return (new ComputiListView())->display($computi, $cantieri, $this->idCantiere);
    }
}
