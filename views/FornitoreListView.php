<?php
namespace views;

class FornitoreListView {

    private array $categoriaBadge = [
        'edilizia'      => 'primary',
        'noleggio'      => 'info',
        'materiali'     => 'success',
        'mat_edili'     => 'success',
        'subappalto'    => 'warning',
        'trasporti'     => 'secondary',
        'impiantistica' => 'danger',
    ];

    public function display(array $rows): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-truck me-2"></i>Fornitori</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnNewFornitore"><i class="bi bi-plus-lg me-1"></i>Nuovo Fornitore</button>';
        $html .= '</div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun fornitore trovato.</div>';
            $html .= $this->modal();
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Ragione Sociale</th><th>Categoria</th><th>P.IVA</th>';
        $html .= '<th>Referente</th><th>Telefono</th>';
        $html .= '<th class="text-center" style="width:80px;">Azioni</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $id             = htmlspecialchars($row['id']              ?? '');
            $ragioneSociale = htmlspecialchars($row['ragione_sociale'] ?? '');
            $categoria      = $row['categoria'] ?? '';
            $piva           = htmlspecialchars($row['piva']            ?? '');
            $referente      = htmlspecialchars($row['referente']       ?? '');
            $email          = htmlspecialchars($row['email']           ?? '');
            $telefono       = htmlspecialchars($row['telefono']        ?? '');
            $iban           = htmlspecialchars($row['iban']            ?? '');
            $indirizzo      = htmlspecialchars($row['indirizzo']       ?? '');
            $note           = htmlspecialchars($row['note']            ?? '');
            $badgeClass     = $this->categoriaBadge[strtolower($categoria)] ?? 'secondary';
            $catLabel       = htmlspecialchars(ucfirst(str_replace('_', ' ', $categoria)));

            $html .= '<tr class="listrow" data-id="' . $id . '"'
                . ' data-nome="' . $ragioneSociale . '"'
                . ' data-categoria="' . htmlspecialchars($categoria) . '"'
                . ' data-piva="' . $piva . '"'
                . ' data-referente="' . $referente . '"'
                . ' data-email="' . $email . '"'
                . ' data-telefono="' . $telefono . '"'
                . ' data-iban="' . $iban . '"'
                . ' data-indirizzo="' . $indirizzo . '"'
                . ' data-note="' . $note . '"'
                . '>';
            $html .= '<td class="fw-semibold">' . $ragioneSociale . '</td>';
            $html .= '<td><span class="badge bg-' . $badgeClass . '">' . $catLabel . '</span></td>';
            $html .= '<td><code>' . $piva . '</code></td>';
            $html .= '<td>' . $referente . '</td>';
            $html .= '<td>' . $telefono . '</td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-outline-primary btn-sm btnEditFornitore" data-id="' . $id . '" title="Modifica"><i class="bi bi-pencil"></i></button>';
            $html .= '</td></tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal();
        $html .= '</div>';
        return $html;
    }

    private function modal(): string {
        return '
<div class="modal fade" id="modalFornitore" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-truck me-2"></i><span class="modaltitle">Nuovo Fornitore</span></h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-danger d-none modalalert" role="alert"><span class="modalalertmsg"></span></div>
        <input type="hidden" class="fornitoreid" value="">
        <div class="row g-3">
          <div class="col-md-8">
            <label class="form-label fw-semibold">Ragione Sociale <span class="text-danger">*</span></label>
            <input type="text" class="form-control fornnome fornitorereq" id="fornnome" placeholder="Cementi Rossi Srl">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">Categoria <span class="text-danger">*</span></label>
            <select class="form-select forncategoria fornitorereq" id="forncategoria_sel">
              <option value="">— Seleziona —</option>
              <option value="edilizia">Edilizia</option>
              <option value="noleggio">Noleggio</option>
              <option value="materiali">Materiali</option>
              <option value="mat_edili">Mat. edili</option>
              <option value="subappalto">Subappalto</option>
              <option value="trasporti">Trasporti</option>
              <option value="impiantistica">Impiantistica</option>
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">P.IVA</label>
            <input type="text" class="form-control fornpiva" id="fornpiva">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Referente</label>
            <input type="text" class="form-control fornreferente" id="fornreferente">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Email</label>
            <input type="email" class="form-control fornemail" id="fornemail">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Telefono</label>
            <input type="text" class="form-control forntel" id="forntel">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">IBAN</label>
            <input type="text" class="form-control forniban" id="forniban" placeholder="IT60 X054 2811 1010 0000 0123 456">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Indirizzo</label>
            <input type="text" class="form-control fornindirizzo" id="fornindirizzo">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Note</label>
            <textarea class="form-control fornnote" id="fornnote" rows="2"></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <small class="text-muted me-auto msghint d-none">Compila i campi obbligatori <span class="text-danger">*</span></small>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnSaveFornitore" disabled>Salva</button>
      </div>
    </div>
  </div>
</div>';
    }
}
