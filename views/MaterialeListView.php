<?php
namespace views;

class MaterialeListView {

    private array $statoBadge = [
        'ordinato'   => 'secondary',
        'consegnato' => 'info',
        'fatturato'  => 'success',
        'annullato'  => 'danger',
    ];

    public function display(array $rows, array $cantieri = [], array $fornitori = [], array $categorie = []): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-boxes me-2"></i>Materiali</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnNewMateriale"><i class="bi bi-plus-lg me-1"></i>Nuovo Ordine</button>';
        $html .= '</div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun materiale trovato.</div>';
            $html .= $this->modal($cantieri, $fornitori, $categorie);
            $html .= '</div>';
            return $html;
        }

        $totaleGenerale = 0.0;
        foreach ($rows as $row) {
            if (($row['stato'] ?? '') !== 'annullato') {
                $totaleGenerale += (float) ($row['totale'] ?? 0);
            }
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Descrizione</th><th>Cantiere</th><th>Fornitore</th><th>Categoria</th>';
        $html .= '<th class="text-end">Q.t&agrave;</th><th>U.M.</th>';
        $html .= '<th class="text-end">Costo unit. (&euro;)</th><th class="text-end">Totale (&euro;)</th>';
        $html .= '<th>Stato</th><th>Data ordine</th><th>Data cons. prev.</th>';
        $html .= '<th class="text-center" style="width:80px;">Azioni</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $id                   = htmlspecialchars($row['id']                    ?? '');
            $idCantiere           = htmlspecialchars($row['id_cantiere']           ?? '');
            $idFornitore          = htmlspecialchars($row['id_fornitore']          ?? '');
            $idCategoria          = htmlspecialchars($row['id_categoria']          ?? '');
            $descrizione          = htmlspecialchars($row['descrizione']           ?? '');
            $cantiere             = htmlspecialchars($row['cantiere']              ?? '—');
            $fornitore            = htmlspecialchars($row['fornitore']             ?? '—');
            $categoria            = htmlspecialchars($row['categoria']             ?? '—');
            $quantita             = number_format((float) ($row['quantita']        ?? 0), 2, ',', '.');
            $quantitaRaw          = (float) ($row['quantita']   ?? 0);
            $unitaMisura          = htmlspecialchars($row['unita_misura']          ?? '');
            $costoUnitarioRaw     = (float) ($row['costo_unitario']  ?? 0);
            $costoUnitario        = number_format($costoUnitarioRaw, 2, ',', '.');
            $totale               = number_format((float) ($row['totale']          ?? 0), 2, ',', '.');
            $stato                = $row['stato'] ?? '';
            $statoLabel           = htmlspecialchars(ucfirst($stato));
            $statoBadge           = $this->statoBadge[$stato] ?? 'secondary';
            $dataOrdine           = htmlspecialchars($row['data_ordine']           ?? '');
            $dataConsegnaPrevista = htmlspecialchars($row['data_consegna_prevista'] ?? '');
            $note                 = htmlspecialchars($row['note']                  ?? '');

            $html .= '<tr class="listrow" data-id="' . $id . '"'
                . ' data-id-cantiere="' . $idCantiere . '"'
                . ' data-id-fornitore="' . $idFornitore . '"'
                . ' data-id-categoria="' . $idCategoria . '"'
                . ' data-desc="' . $descrizione . '"'
                . ' data-qta="' . $quantitaRaw . '"'
                . ' data-um="' . $unitaMisura . '"'
                . ' data-prezzo="' . $costoUnitarioRaw . '"'
                . ' data-stato="' . htmlspecialchars($stato) . '"'
                . ' data-dt-ordine="' . $dataOrdine . '"'
                . ' data-dt-consegna="' . $dataConsegnaPrevista . '"'
                . ' data-note="' . $note . '"'
                . '>';
            $html .= '<td class="fw-semibold">' . $descrizione . '</td>';
            $html .= '<td>' . $cantiere . '</td>';
            $html .= '<td>' . $fornitore . '</td>';
            $html .= '<td>' . $categoria . '</td>';
            $html .= '<td class="text-end">' . $quantita . '</td>';
            $html .= '<td>' . $unitaMisura . '</td>';
            $html .= '<td class="text-end">' . $costoUnitario . '</td>';
            $html .= '<td class="text-end">' . $totale . '</td>';
            $html .= '<td><span class="badge bg-' . $statoBadge . '">' . $statoLabel . '</span></td>';
            $html .= '<td>' . $dataOrdine . '</td>';
            $html .= '<td>' . $dataConsegnaPrevista . '</td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-outline-primary btn-sm btnEditMateriale" data-id="' . $id . '" title="Modifica"><i class="bi bi-pencil"></i></button>';
            $html .= '</td></tr>';
        }

        $totaleFmt = number_format($totaleGenerale, 2, ',', '.');
        $html .= '<tr class="table-secondary fw-bold">';
        $html .= '<td colspan="7" class="text-end">Totale (esclusi annullati):</td>';
        $html .= '<td class="text-end">&euro; ' . $totaleFmt . '</td>';
        $html .= '<td colspan="4"></td>';
        $html .= '</tr>';

        $html .= '</tbody></table></div>';
        $html .= $this->modal($cantieri, $fornitori, $categorie);
        $html .= '</div>';
        return $html;
    }

    private function modal(array $cantieri, array $fornitori, array $categorie): string {
        $cantieriOpts = '<option value="">— Seleziona cantiere —</option>';
        foreach ($cantieri as $c) {
            $cantieriOpts .= '<option value="' . htmlspecialchars($c['id']) . '">' . htmlspecialchars($c['nome']) . '</option>';
        }

        $fornitoriOpts = '<option value="">— Seleziona fornitore —</option>';
        foreach ($fornitori as $f) {
            $fornitoriOpts .= '<option value="' . htmlspecialchars($f['id']) . '">' . htmlspecialchars($f['ragione_sociale']) . '</option>';
        }

        $categorieOpts = '<option value="">— Seleziona categoria —</option>';
        foreach ($categorie as $c) {
            $categorieOpts .= '<option value="' . htmlspecialchars($c['id']) . '">' . htmlspecialchars($c['nome']) . '</option>';
        }

        return '
<div class="modal fade" id="modalMateriale" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-boxes me-2"></i><span class="modaltitle">Nuovo Ordine Materiale</span></h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-danger d-none modalalert" role="alert"><span class="modalalertmsg"></span></div>
        <input type="hidden" class="materialeid" value="">
        <div class="row g-3">
          <div class="col-md-6">
            <label class="form-label fw-semibold">Cantiere <span class="text-danger">*</span></label>
            <select class="form-select matcantiere materialereq" id="matcantiere_sel">
              ' . $cantieriOpts . '
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Fornitore <span class="text-danger">*</span></label>
            <select class="form-select matfornitore materialereq" id="matfornitore_sel">
              ' . $fornitoriOpts . '
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Categoria <span class="text-danger">*</span></label>
            <select class="form-select matcategoria materialereq" id="matcategoria_sel">
              ' . $categorieOpts . '
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Stato</label>
            <select class="form-select matstato" id="matstato_sel">
              <option value="ordinato">Ordinato</option>
              <option value="consegnato">Consegnato</option>
              <option value="fatturato">Fatturato</option>
              <option value="annullato">Annullato</option>
            </select>
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Descrizione <span class="text-danger">*</span></label>
            <input type="text" class="form-control matdesc materialereq" id="matdesc" placeholder="Es. Calcestruzzo C25/30">
          </div>
          <div class="col-md-3">
            <label class="form-label fw-semibold">Quantit&agrave; <span class="text-danger">*</span></label>
            <input type="number" step="0.01" min="0" class="form-control matqta materialereq" id="matqta">
          </div>
          <div class="col-md-3">
            <label class="form-label fw-semibold">Unit&agrave; misura</label>
            <input type="text" class="form-control matum" id="matum" placeholder="m³, kg, pz…">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Costo unitario (&euro;)</label>
            <input type="number" step="0.01" min="0" class="form-control matprezzo" id="matprezzo">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Data ordine</label>
            <input type="date" class="form-control matdtordine" id="matdtordine">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Data consegna prevista</label>
            <input type="date" class="form-control matdtconsegna" id="matdtconsegna">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Note</label>
            <textarea class="form-control matnote" id="matnote" rows="2"></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <small class="text-muted me-auto msghint d-none">Compila i campi obbligatori <span class="text-danger">*</span></small>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnSaveMateriale" disabled>Salva</button>
      </div>
    </div>
  </div>
</div>';
    }
}
