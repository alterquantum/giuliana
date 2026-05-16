<?php
namespace controllers;

require_once __DIR__ . '/../models/DashboardModel.php';
require_once __DIR__ . '/../views/DashboardView.php';

use models\DashboardModel;
use views\DashboardView;

class DashboardController {

    public function render(): string {
        $kpi = (new DashboardModel())->getKpi();
        return (new DashboardView())->display($kpi);
    }
}
