<?php
namespace controllers;

require_once __DIR__ . '/../models/GanttModel.php';
require_once __DIR__ . '/../views/GanttView.php';

use models\GanttModel;
use views\GanttView;

class GanttController {
    private array $data;

    public function __construct(array $data = []) {
        $this->data = $data;
    }

    public function render(): string {
        $idCantiere = $this->data['id_cantiere'] ?? null;

        if ($idCantiere) {
            $ganttRows = (new GanttModel())->getGantt($idCantiere);
            $evm       = (new GanttModel())->getEvm($idCantiere);
            return (new GanttView())->display($ganttRows, $evm);
        } else {
            $portfolioRows = (new GanttModel())->getEvmPortfolio();
            return (new GanttView())->displayPortfolio($portfolioRows);
        }
    }
}
