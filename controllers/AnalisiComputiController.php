<?php
namespace controllers;

require_once __DIR__ . '/../models/AnalisiComputiModel.php';
require_once __DIR__ . '/../views/AnalisiComputiView.php';

use models\AnalisiComputiModel;
use views\AnalisiComputiView;

class AnalisiComputiController {
    private string $idComputo;

    public function __construct(string $idComputo = '') {
        $this->idComputo = $idComputo;
    }

    public function render(): string {
        $righe = $this->idComputo !== ''
            ? (new AnalisiComputiModel())->analisi($this->idComputo)
            : [];
        return (new AnalisiComputiView())->display($righe, $this->idComputo);
    }
}
