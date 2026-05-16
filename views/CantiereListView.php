<?php
namespace views;

class CantiereListView {

    private array $statoBadge = [
        'in_corso'    => 'success',
        'pianificato' => 'secondary',
        'sospeso'     => 'warning',
        'completato'  => 'primary',
    ];

    public function display(array $rows, array $clienti = []): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-building me-2"></i>Cantieri</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnNewCantiere"><i class="bi bi-plus-lg me-1"></i>Nuovo Cantiere</button>';
        $html .= '</div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun cantiere trovato.</div>';
            $html .= $this->modal($clienti);
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Nome</th><th>Cliente</th><th>Stato</th><th>Indirizzo</th>';
        $html .= '<th>Data Inizio</th><th>Importo (&euro;)</th><th>Completamento</th>';
        $html .= '<th class="text-center" style="width:80px;">Azioni</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $id             = htmlspecialchars($row['id']              ?? '');
            $nome           = htmlspecialchars($row['nome']            ?? '');
            $idCliente      = htmlspecialchars($row['id_cliente']      ?? '');
            $cliente        = htmlspecialchars($row['cliente']         ?? '—');
            $stato          = $row['stato'] ?? '';
            $indirizzo      = htmlspecialchars($row['indirizzo']       ?? '');
            $dataInizio     = htmlspecialchars($row['data_inizio']     ?? '');
            $dataFine       = htmlspecialchars($row['data_fine_prevista'] ?? '');
            $importo        = $row['importo_contratto'] ?? null;
            $tipoLavori     = htmlspecialchars($row['tipo_lavori']     ?? '');
            $note           = htmlspecialchars($row['note']            ?? '');
            $completamento  = (int) ($row['pct_completamento']         ?? 0);
            $badgeClass     = $this->statoBadge[$stato] ?? 'secondary';
            $statoLabel     = htmlspecialchars(str_replace('_', ' ', ucfirst($stato)));
            $importoRaw     = $importo !== null ? (float) $importo : '';
            $importoFmt     = $importo !== null ? number_format((float) $importo, 2, ',', '.') : '—';

            $progressColor = match ($badgeClass) {
                'success' => 'bg-success',
                'primary' => 'bg-primary',
                'warning' => 'bg-warning',
                default   => 'bg-secondary',
            };

            $html .= '<tr class="listrow" data-id="' . $id . '"'
                . ' data-nome="' . $nome . '"'
                . ' data-id-cliente="' . $idCliente . '"'
                . ' data-indirizzo="' . $indirizzo . '"'
                . ' data-data-inizio="' . $dataInizio . '"'
                . ' data-data-fine="' . $dataFine . '"'
                . ' data-stato="' . htmlspecialchars($stato) . '"'
                . ' data-importo="' . $importoRaw . '"'
                . ' data-tipo="' . $tipoLavori . '"'
                . ' data-note="' . $note . '"'
                . '>';
            $html .= '<td class="fw-semibold">' . $nome . '</td>';
            $html .= '<td>' . $cliente . '</td>';
            $html .= '<td><span class="badge bg-' . $badgeClass . '">' . $statoLabel . '</span></td>';
            $html .= '<td>' . $indirizzo . '</td>';
            $html .= '<td>' . $dataInizio . '</td>';
            $html .= '<td class="text-end">' . $importoFmt . '</td>';
            $html .= '<td style="min-width:120px;">';
            $html .= '<div class="d-flex align-items-center gap-2">';
            $html .= '<div class="progress flex-grow-1" style="height:8px;" role="progressbar" aria-valuenow="' . $completamento . '" aria-valuemin="0" aria-valuemax="100">';
            $html .= '<div class="progress-bar ' . $progressColor . '" style="width:' . $completamento . '%;"></div>';
            $html .= '</div><small class="text-muted">' . $completamento . '%</small>';
            $html .= '</div></td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-outline-primary btn-sm btnEditCantiere" data-id="' . $id . '" title="Modifica"><i class="bi bi-pencil"></i></button>';
            $html .= '</td></tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal($clienti);
        $html .= '</div>';
        return $html;
    }

    private function modal(array $clienti): string {
        $clientiOptions = '<option value="">— Seleziona cliente —</option>';
        foreach ($clienti as $c) {
            $clientiOptions .= '<option value="' . htmlspecialchars($c['id']) . '">' . htmlspecialchars($c['ragione_sociale']) . '</option>';
        }

        return '
<div class="modal fade" id="modalCantiere" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-building me-2"></i><span class="modaltitle">Nuovo Cantiere</span></h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-danger d-none modalalert" role="alert"><span class="modalalertmsg"></span></div>
        <input type="hidden" class="cantiereid" value="">
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label fw-semibold">Nome cantiere <span class="text-danger">*</span></label>
            <input type="text" class="form-control cntnome cantierereq" id="cntnome" placeholder="Es. Villa Bianchi">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Cliente <span class="text-danger">*</span></label>
            <select class="form-select cntcliente cantierereq" id="cntcliente_sel">
              ' . $clientiOptions . '
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Stato <span class="text-danger">*</span></label>
            <select class="form-select cntstato cantierereq" id="cntstato_sel">
              <option value="">— Seleziona stato —</option>
              <option value="pianificato">Pianificato</option>
              <option value="in_corso">In corso</option>
              <option value="sospeso">Sospeso</option>
              <option value="completato">Completato</option>
            </select>
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Indirizzo <span class="text-danger">*</span></label>
            <input type="text" class="form-control cntindirizzo cantierereq" id="cntindirizzo" placeholder="Via Roma 1, Città">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">Data inizio <span class="text-danger">*</span></label>
            <input type="date" class="form-control cntdtstart cantierereq" id="cntdtstart">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">Data fine prevista <span class="text-danger">*</span></label>
            <input type="date" class="form-control cntdtend cantierereq" id="cntdtend">
            <div class="invalid-feedback dateerror d-none">La data fine deve essere successiva alla data inizio.</div>
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">Importo contratto (&euro;)</label>
            <input type="number" step="0.01" min="0" class="form-control cntimporto" id="cntimporto" placeholder="0.00">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Tipo lavori</label>
            <input type="text" class="form-control cnttipo" id="cnttipo" placeholder="Es. Ristrutturazione completa">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Note</label>
            <textarea class="form-control cntnote" id="cntnote" rows="2"></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <small class="text-muted me-auto msghint d-none">Compila i campi obbligatori <span class="text-danger">*</span></small>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnSaveCantiere" disabled>Salva</button>
      </div>
    </div>
  </div>
</div>';
    }
}
