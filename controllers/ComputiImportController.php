<?php
namespace controllers;

require_once __DIR__ . '/../parsers/PrimusPdfParser.php';
require_once __DIR__ . '/../models/ComputiImportModel.php';
require_once __DIR__ . '/../services/Response.php';

use parsers\PrimusPdfParser;
use models\ComputiImportModel;
use services\Response;

class ComputiImportController {
    private array    $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function import(): array {
        try {
            $testo      = trim($this->data['testo_pdf']   ?? '');
            $idCantiere = trim($this->data['id_cantiere'] ?? '');
            $nomeFile   = trim($this->data['nome_file']   ?? 'computo.pdf');

            if ($testo === '')      throw new \InvalidArgumentException('Testo PDF vuoto.');
            if ($idCantiere === '') throw new \InvalidArgumentException('Cantiere non specificato.');

            $parser = new PrimusPdfParser();
            $voci   = $parser->parse($testo);

            if (empty($voci)) {
                throw new \RuntimeException(
                    'Nessuna voce riconosciuta. Verifica che il PDF sia un computo PriMus.'
                );
            }

            $model        = new ComputiImportModel();
            $importoTot   = 0.0;

            // Arricchimento con dati DEI (rendimento, n_operai)
            foreach ($voci as &$v) {
                $importoTot += (float)($v['importo'] ?? 0);
                if (!empty($v['codice_dei'])) {
                    $dei = $model->getDeiRendimento($v['codice_dei']);
                    if (!empty($dei)) {
                        $rend = (float)($dei['rendimento_giornaliero'] ?? 0);
                        $qt   = (float)($v['quantita'] ?? 0);
                        $v['durata_giorni'] = $rend > 0 ? round($qt / $rend, 2) : null;
                        $squadra = json_decode($dei['squadra_tipo'] ?? '{}', true);
                        $v['n_operai'] = array_sum((array)$squadra) ?: null;
                    }
                }
            }
            unset($v);

            $result = $model->importa($idCantiere, $nomeFile, $importoTot, $voci);

            $this->response->setRes('ok');
            $this->response->setMsg(
                'Computo importato: ' . ($result['n_voci'] ?? count($voci)) . ' voci.'
            );
            $this->response->setDbRes($result);
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore import computo: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }

    public function elimina(): array {
        try {
            $id = $this->data['id'] ?? '';
            if ($id === '') throw new \InvalidArgumentException('ID mancante.');
            (new ComputiImportModel())->elimina($id);
            $this->response->setRes('ok');
            $this->response->setMsg('Computo eliminato.');
        } catch (\Throwable $e) {
            $this->response->setRes('no');
            $this->response->setMsg('Errore: ' . $e->getMessage());
        }
        return $this->response->getRes();
    }
}
