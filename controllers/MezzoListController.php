<?php
namespace controllers;

require_once __DIR__ . '/../models/MezzoListModel.php';
require_once __DIR__ . '/../views/MezzoListView.php';

use models\MezzoListModel;
use views\MezzoListView;

class MezzoListController {

    public function render(): string {
        $rows = (new MezzoListModel())->list();
        return (new MezzoListView())->display($rows);
    }
}
