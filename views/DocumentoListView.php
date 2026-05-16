<?php
namespace views;

class DocumentoListView {

    public function display(array $rows, array $cantieri = [], array $tipi = []): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-file-earmark-text me-2"></i>Documenti</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnNewDocumento"><i class="bi bi-plus-lg me-1"></i>Carica Documento</button>';
        $html .= '</div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun documento trovato.</div>';
            $html .= $this->modal($cantieri, $tipi);
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Nome</th><th>Tipo</th><th>Cantiere</th><th>Caricato da</th>';
        $html .= '<th>Formato</th><th>Data emissione</th><th>Data scadenza</th>';
        $html .= '<th>Stato scadenza</th>';
        $html .= '<th class="text-center" style="width:80px;">Azioni</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $id            = htmlspecialchars($row['id']             ?? '');
            $nome          = htmlspecialchars($row['nome']           ?? '');
            $tipo          = htmlspecialchars($row['tipo']           ?? '—');
            $cantiere      = htmlspecialchars($row['cantiere']       ?? '—');
            $caricatoDa    = htmlspecialchars($row['caricato_da']    ?? '—');
            $formato       = htmlspecialchars($row['tipo_file']      ?? '—');
            $dataEmissione = htmlspecialchars($row['data_emissione'] ?? '');
            $dataScadenza  = htmlspecialchars($row['data_scadenza']  ?? '');
            $idTipo        = htmlspecialchars($row['id_tipo']        ?? '');
            $idCantiere    = htmlspecialchars($row['id_cantiere']    ?? '');

            $ggScadenzaRaw = $row['gg_scadenza'] ?? null;

            $rowClass = 'listrow';
            if ($ggScadenzaRaw !== null) {
                $ggScadenza = (int) $ggScadenzaRaw;
                if ($ggScadenza < 0) {
                    $rowClass .= ' table-danger';
                } elseif ($ggScadenza <= 30) {
                    $rowClass .= ' table-warning';
                }
            }

            if ($ggScadenzaRaw === null) {
                $statoScadenza = '<span class="badge bg-secondary">Nessuna</span>';
            } else {
                $ggScadenza = (int) $ggScadenzaRaw;
                if ($ggScadenza < 0) {
                    $statoScadenza = '<span class="badge bg-danger">Scaduto</span>';
                } elseif ($ggScadenza <= 30) {
                    $statoScadenza = '<span class="badge bg-warning text-dark">' . $ggScadenza . ' gg</span>';
                } else {
                    $statoScadenza = '<span class="badge bg-success">Valido</span>';
                }
            }

            $html .= '<tr class="' . $rowClass . '" data-id="' . $id . '"'
                . ' data-id-tipo="' . $idTipo . '"'
                . ' data-id-cantiere="' . $idCantiere . '"'
                . ' data-nome="' . $nome . '"'
                . ' data-emissione="' . $dataEmissione . '"'
                . ' data-scadenza="' . $dataScadenza . '"'
                . '>';
            $html .= '<td class="fw-semibold">' . $nome . '</td>';
            $html .= '<td>' . $tipo . '</td>';
            $html .= '<td>' . $cantiere . '</td>';
            $html .= '<td>' . $caricatoDa . '</td>';
            $html .= '<td>' . $formato . '</td>';
            $html .= '<td>' . $dataEmissione . '</td>';
            $html .= '<td>' . $dataScadenza . '</td>';
            $html .= '<td>' . $statoScadenza . '</td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-outline-primary btn-sm btnEditDocumento" data-id="' . $id . '" title="Visualizza"><i class="bi bi-eye"></i></button>';
            $html .= '</td></tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal($cantieri, $tipi);
        $html .= '</div>';
        return $html;
    }

    private function modal(array $cantieri, array $tipi): string {
        $cantieriOpts = '<option value="">— Nessun cantiere —</option>';
        foreach ($cantieri as $c) {
            $cantieriOpts .= '<option value="' . htmlspecialchars($c['id']) . '">' . htmlspecialchars($c['nome']) . '</option>';
        }

        $tipiOpts = '<option value="">— Seleziona tipo —</option>';
        foreach ($tipi as $t) {
            $tipiOpts .= '<option value="' . htmlspecialchars($t['id']) . '">' . htmlspecialchars($t['nome']) . '</option>';
        }

        return '
<div class="modal fade" id="modalDocumento" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-file-earmark-text me-2"></i>Carica Documento</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-danger d-none modalalert" role="alert"><span class="modalalertmsg"></span></div>
        <div class="row g-3">
          <div class="col-md-6">
            <label class="form-label fw-semibold">Tipo documento <span class="text-danger">*</span></label>
            <select class="form-select doctipo documentoreq" id="doctipo_sel">
              ' . $tipiOpts . '
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Cantiere (opzionale)</label>
            <select class="form-select doccantiere" id="doccantiere_sel">
              ' . $cantieriOpts . '
            </select>
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Nome documento <span class="text-danger">*</span></label>
            <input type="text" class="form-control docnome documentoreq" id="docnome" placeholder="Es. DURC aziendale marzo 2026">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Descrizione</label>
            <textarea class="form-control docdesc" id="docdesc" rows="2"></textarea>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Data emissione</label>
            <input type="date" class="form-control docemissione" id="docemissione">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Data scadenza</label>
            <input type="date" class="form-control docscadenza" id="docscadenza">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">File (opzionale)</label>
            <input type="file" class="form-control docfile" id="docfile" accept=".pdf,.doc,.docx,.jpg,.png">
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <small class="text-muted me-auto msghint d-none">Compila i campi obbligatori <span class="text-danger">*</span></small>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnSaveDocumento" disabled>Salva</button>
      </div>
    </div>
  </div>
</div>';
    }
}
