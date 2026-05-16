<?php
namespace controllers;

require_once __DIR__ . '/../models/ClienteListModel.php';
require_once __DIR__ . '/../views/ClienteListView.php';

use models\ClienteListModel;
use views\ClienteListView;

class ClienteListController {

    public function render(): string {
        $rows = (new ClienteListModel())->list();
        return (new ClienteListView())->display($rows);
    }
}
