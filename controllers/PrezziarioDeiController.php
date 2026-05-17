<?php
namespace controllers;

require_once __DIR__ . '/../models/PrezziarioDeiListModel.php';
require_once __DIR__ . '/../views/PrezziarioDeiView.php';

use models\PrezziarioDeiListModel;
use views\PrezziarioDeiView;

class PrezziarioDeiController {

    public function render(): string {
        $rows = (new PrezziarioDeiListModel())->list();
        return (new PrezziarioDeiView())->display($rows);
    }
}
