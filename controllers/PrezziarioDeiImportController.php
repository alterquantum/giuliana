<?php
namespace controllers;

require_once __DIR__ . '/../parsers/DeiPdfParser.php';
require_once __DIR__ . '/../models/PrezziarioDeiImportModel.php';
require_once __DIR__ . '/../services/Response.php';

use parsers\DeiPdfParser;
use models\PrezziarioDeiImportModel;
use services\Response;

class PrezziarioDeiImportController {
    private array    $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function import(): array {
        try {
            $testo = trim($this->data['testo_pdf'] ?? '');
            if ($testo === '') throw new \InvalidArgumentException('Testo PDF vuoto.');

            $sostituisci = ($this->data['sostituisci'] ?? '0') === '1';

            $parser = new DeiPdfParser();
            $voci   = $parser->parse($testo);

            if (empty($voci)) {
                throw new \RuntimeException('Nessuna voce riconosciuta nel testo. Verifica che il PDF sia il prezziario DEI.');
            }

            $model = new PrezziarioDeiImportModel();
            if ($sostituisci) $model->truncate();

            $n = 0;
            foreach ($voci as $v) {
                $model->upsertVoce($v);
                $n++;
            }

            $this->response->setRes('ok');
            $this->response->setMsg("Importate $n voci DEI.");
            $this->response->setDbRes(['n_voci' => $n]);
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore import DEI: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
