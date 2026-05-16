<?php
namespace controllers;

require_once __DIR__ . '/../models/ReportModel.php';
require_once __DIR__ . '/../views/ReportView.php';

use models\ReportModel;
use views\ReportView;

class ReportController {

    public function render(): string {
        $data = (new ReportModel())->getData();
        return (new ReportView())->display($data);
    }
}
