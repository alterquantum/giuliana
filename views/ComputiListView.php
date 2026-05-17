<?php
namespace views;

class ComputiListView {

    public function display(array $computi, array $cantieri, string $idCantiere = ''): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-calculator me-2"></i>Computi Metrici</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnImportaComputo">'
               . '<i class="bi bi-upload me-1"></i>Importa Computo PriMus</button>';
        $html .= '</div>';

        // Selezione cantiere
        $html .= '<div class="row mb-4"><div class="col-md-5">';
        $html .= '<label class="form-label fw-semibold">Cantiere</label>';
        $html .= '<select class="form-select selCantiereComputi">';
        $html .= '<option value="">— Seleziona cantiere —</option>';
        foreach ($cantieri as $c) {
            $sel  = ($c['id'] === $idCantiere) ? ' selected' : '';
            $html .= '<option value="' . htmlspecialchars($c['id']) . '"' . $sel . '>'
                   . htmlspecialchars($c['nome']) . '</option>';
        }
        $html .= '</select></div></div>';

        if ($idCantiere === '') {
            $html .= '<div class="alert alert-info">Seleziona un cantiere per vedere i computi.</div>';
            $html .= $this->modal($cantieri);
            $html .= '</div>';
            return $html;
        }

        if (empty($computi)) {
            $html .= '<div class="alert alert-info">'
                   . 'Nessun computo importato per questo cantiere. Clicca <strong>Importa Computo PriMus</strong>.'
                   . '</div>';
            $html .= $this->modal($cantieri, $idCantiere);
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>File</th><th class="text-end">Importo totale (€)</th>';
        $html .= '<th class="text-center">N° voci</th><th>Importato il</th>';
        $html .= '<th class="text-center" style="width:110px;">Azioni</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($computi as $c) {
            $id       = htmlspecialchars($c['id']            ?? '');
            $nome     = htmlspecialchars($c['nome_file']     ?? '');
            $importo  = $c['importo_totale'] !== null
                ? number_format((float)$c['importo_totale'], 2, ',', '.') . ' €' : '—';
            $nVoci    = htmlspecialchars($c['n_voci']        ?? '0');
            $data     = htmlspecialchars(substr($c['created_at'] ?? '', 0, 16));

            $html .= '<tr data-id="' . $id . '">';
            $html .= '<td><i class="bi bi-file-earmark-pdf text-danger me-1"></i>' . $nome . '</td>';
            $html .= '<td class="text-end">' . $importo . '</td>';
            $html .= '<td class="text-center">' . $nVoci . '</td>';
            $html .= '<td>' . $data . '</td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-sm btn-outline-primary me-1 btnAnalisiComputo" '
                   . 'data-id="' . $id . '" title="Analisi lavorazioni">'
                   . '<i class="bi bi-bar-chart"></i></button>';
            $html .= '<button class="btn btn-sm btn-outline-danger btnEliminaComputo" '
                   . 'data-id="' . $id . '" title="Elimina">'
                   . '<i class="bi bi-trash"></i></button>';
            $html .= '</td></tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal($cantieri, $idCantiere);
        $html .= '</div>';
        return $html;
    }

    private function modal(array $cantieri, string $idCantiere = ''): string {
        $opts = '<option value="">— Seleziona cantiere —</option>';
        foreach ($cantieri as $c) {
            $sel  = ($c['id'] === $idCantiere) ? ' selected' : '';
            $opts .= '<option value="' . htmlspecialchars($c['id']) . '"' . $sel . '>'
                   . htmlspecialchars($c['nome']) . '</option>';
        }

        return '
<div class="modal fade" id="modalImportaComputo" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-upload me-2"></i>Importa Computo Metrico PriMus</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-info small">
          <i class="bi bi-info-circle me-1"></i>
          Il testo viene estratto <strong>nel browser</strong> — il file PDF non viene caricato sul server.
          Assicurati di aver prima importato il <strong>Prezziario DEI</strong> per ottenere tempistiche e operai.
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">Cantiere</label>
          <select class="form-select computoCantiere">' . $opts . '</select>
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">PDF Computo Metrico (PriMus)</label>
          <input type="file" class="form-control computoFile" accept=".pdf">
        </div>
        <div class="computoProgress d-none">
          <div class="d-flex align-items-center gap-2 mb-2">
            <div class="spinner-border spinner-border-sm text-primary"></div>
            <span class="computoProgressLabel">Estrazione testo in corso…</span>
          </div>
          <div class="progress" style="height:8px;">
            <div class="progress-bar computoProgressBar" style="width:0%"></div>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnAvviaImportComputo" disabled>
          <i class="bi bi-upload me-1"></i>Avvia Import
        </button>
      </div>
    </div>
  </div>
</div>';
    }
}
