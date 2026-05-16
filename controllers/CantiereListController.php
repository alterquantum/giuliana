<?php
namespace controllers;

require_once __DIR__ . '/../models/CantiereListModel.php';
require_once __DIR__ . '/../models/ClienteListModel.php';
require_once __DIR__ . '/../views/CantiereListView.php';

use models\CantiereListModel;
use models\ClienteListModel;
use views\CantiereListView;

class CantiereListController {

    public function render(?string $stato = null): string {
        $rows    = (new CantiereListModel())->list($stato);
        $clienti = (new ClienteListModel())->list();
        return (new CantiereListView())->display($rows, $clienti);
    }
}
