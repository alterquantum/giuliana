<?php
namespace controllers;

require_once __DIR__ . '/../models/DocumentoListModel.php';
require_once __DIR__ . '/../models/CantiereListModel.php';
require_once __DIR__ . '/../models/TipoDocumentoListModel.php';
require_once __DIR__ . '/../views/DocumentoListView.php';

use models\DocumentoListModel;
use models\CantiereListModel;
use models\TipoDocumentoListModel;
use views\DocumentoListView;

class DocumentoListController {

    public function render(): string {
        $rows     = (new DocumentoListModel())->list();
        $cantieri = (new CantiereListModel())->list();
        $tipi     = (new TipoDocumentoListModel())->list();
        return (new DocumentoListView())->display($rows, $cantieri, $tipi);
    }
}
