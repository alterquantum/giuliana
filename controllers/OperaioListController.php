<?php
namespace controllers;

require_once __DIR__ . '/../models/OperaioListModel.php';
require_once __DIR__ . '/../views/OperaioListView.php';

use models\OperaioListModel;
use views\OperaioListView;

class OperaioListController {

    public function render(?bool $attivo = null): string {
        $rows = (new OperaioListModel())->list($attivo);
        return (new OperaioListView())->display($rows);
    }
}
