<?php
namespace controllers;

require_once __DIR__ . '/../models/MaterialeListModel.php';
require_once __DIR__ . '/../models/CantiereListModel.php';
require_once __DIR__ . '/../models/FornitoreListModel.php';
require_once __DIR__ . '/../models/CategoriaListModel.php';
require_once __DIR__ . '/../views/MaterialeListView.php';

use models\MaterialeListModel;
use models\CantiereListModel;
use models\FornitoreListModel;
use models\CategoriaListModel;
use views\MaterialeListView;

class MaterialeListController {

    public function render(): string {
        $rows      = (new MaterialeListModel())->list();
        $cantieri  = (new CantiereListModel())->list();
        $fornitori = (new FornitoreListModel())->list();
        $categorie = (new CategoriaListModel())->list();
        return (new MaterialeListView())->display($rows, $cantieri, $fornitori, $categorie);
    }
}
