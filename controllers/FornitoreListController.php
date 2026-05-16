<?php
namespace controllers;

require_once __DIR__ . '/../models/FornitoreListModel.php';
require_once __DIR__ . '/../views/FornitoreListView.php';

use models\FornitoreListModel;
use views\FornitoreListView;

class FornitoreListController {

    public function render(): string {
        $rows = (new FornitoreListModel())->list();
        return (new FornitoreListView())->display($rows);
    }
}
