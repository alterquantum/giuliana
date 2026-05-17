<?php
namespace views;

class PrezziarioDeiView {

    public function display(array $rows): string {
        $nVoci = count($rows);
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-book me-2"></i>Prezziario DEI</h4>';
        $html .= '<div class="d-flex gap-2">';
        $html .= '<span class="badge bg-secondary align-self-center">' . $nVoci . ' voci</span>';
        $html .= '<button class="btn btn-outline-secondary btn-sm btnImportaDei">'
               . '<i class="bi bi-upload me-1"></i>Importa / Aggiorna DEI</button>';
        $html .= '</div></div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">'
                   . '<i class="bi bi-info-circle me-2"></i>'
                   . 'Nessun prezziario importato. Clicca <strong>Importa / Aggiorna DEI</strong> per caricare il PDF del prezziario.'
                   . '</div>';
            $html .= $this->modal();
            $html .= '</div>';
            return $html;
        }

        // Ricerca rapida
        $html .= '<div class="mb-3">'
               . '<input type="text" class="form-control deiSearch" placeholder="Cerca per codice o descrizione…">'
               . '</div>';

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle table-sm" id="tableDei">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th style="width:130px;">Codice</th>';
        $html .= '<th>Descrizione</th>';
        $html .= '<th style="width:70px;">U.M.</th>';
        $html .= '<th style="width:110px;" class="text-end">Prezzo (€)</th>';
        $html .= '<th style="width:120px;" class="text-end">Incid. Man. (€)</th>';
        $html .= '<th style="width:120px;" class="text-end">Incid. Mat. (€)</th>';
        $html .= '<th style="width:120px;" class="text-end">Rend. gg</th>';
        $html .= '<th>Categoria</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $codice   = htmlspecialchars($row['codice']          ?? '');
            $desc     = htmlspecialchars($row['descrizione']     ?? '');
            $um       = htmlspecialchars($row['unita_misura']    ?? '');
            $prezzo   = $row['prezzo_unitario']        !== null ? number_format((float)$row['prezzo_unitario'], 2, ',', '.') : '—';
            $mano     = $row['incidenza_manodopera']   !== null ? number_format((float)$row['incidenza_manodopera'], 2, ',', '.') : '—';
            $mat      = $row['incidenza_materiali']    !== null ? number_format((float)$row['incidenza_materiali'], 2, ',', '.') : '—';
            $rend     = $row['rendimento_giornaliero'] !== null ? number_format((float)$row['rendimento_giornaliero'], 4, ',', '.') : '—';
            $cat      = htmlspecialchars($row['categoria']       ?? '');

            $html .= '<tr>';
            $html .= '<td><code>' . $codice . '</code></td>';
            $html .= '<td>' . $desc . '</td>';
            $html .= '<td>' . $um . '</td>';
            $html .= '<td class="text-end">' . $prezzo . '</td>';
            $html .= '<td class="text-end">' . $mano . '</td>';
            $html .= '<td class="text-end">' . $mat . '</td>';
            $html .= '<td class="text-end">' . $rend . '</td>';
            $html .= '<td><small class="text-muted">' . $cat . '</small></td>';
            $html .= '</tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal();
        $html .= '</div>';
        return $html;
    }

    private function modal(): string {
        return '
<div class="modal fade" id="modalImportaDei" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-upload me-2"></i>Importa Prezziario DEI</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-info small">
          <i class="bi bi-info-circle me-1"></i>
          Il testo viene estratto <strong>nel browser</strong> tramite PDF.js — il file non viene caricato sul server.
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">Seleziona PDF del prezziario DEI</label>
          <input type="file" class="form-control deiFile" accept=".pdf">
        </div>
        <div class="mb-3 form-check">
          <input type="checkbox" class="form-check-input deiSostituisci" id="deiSostituisci" value="1">
          <label class="form-check-label" for="deiSostituisci">
            Sostituisci tutto il prezziario (cancella le voci esistenti prima di importare)
          </label>
        </div>
        <div class="deiProgress d-none">
          <div class="d-flex align-items-center gap-2 mb-2">
            <div class="spinner-border spinner-border-sm text-primary"></div>
            <span class="deiProgressLabel">Estrazione testo in corso…</span>
          </div>
          <div class="progress" style="height:8px;">
            <div class="progress-bar deiProgressBar" style="width:0%"></div>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnAvviaImportDei" disabled>
          <i class="bi bi-upload me-1"></i>Avvia Import
        </button>
      </div>
    </div>
  </div>
</div>';
    }
}
