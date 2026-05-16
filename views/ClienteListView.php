<?php
namespace views;

class ClienteListView {

    private array $tipoBadge = [
        'azienda' => 'primary',
        'privato' => 'info',
        'ente'    => 'warning',
        'pa'      => 'secondary',
    ];

    public function display(array $rows): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-person-badge me-2"></i>Clienti</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnNewCliente"><i class="bi bi-plus-lg me-1"></i>Nuovo Cliente</button>';
        $html .= '</div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun cliente trovato.</div>';
            $html .= $this->modal();
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Ragione Sociale</th><th>Tipo</th><th>P.IVA</th><th>Referente</th>';
        $html .= '<th>Email</th><th class="text-center">Cantieri</th>';
        $html .= '<th class="text-center" style="width:80px;">Azioni</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $id             = htmlspecialchars($row['id']              ?? '');
            $ragioneSociale = htmlspecialchars($row['ragione_sociale'] ?? '');
            $tipo           = $row['tipo'] ?? '';
            $piva           = htmlspecialchars($row['piva']            ?? '');
            $cf             = htmlspecialchars($row['codice_fiscale']  ?? '');
            $referente      = htmlspecialchars($row['referente']       ?? '');
            $email          = htmlspecialchars($row['email']           ?? '');
            $telefono       = htmlspecialchars($row['telefono']        ?? '');
            $indirizzo      = htmlspecialchars($row['indirizzo']       ?? '');
            $note           = htmlspecialchars($row['note']            ?? '');
            $nCantieri      = (string) ($row['n_cantieri']             ?? 0);
            $badgeClass     = $this->tipoBadge[strtolower($tipo)] ?? 'secondary';
            $tipoLabel      = htmlspecialchars(ucfirst($tipo));

            $html .= '<tr class="listrow" data-id="' . $id . '"'
                . ' data-nome="' . $ragioneSociale . '"'
                . ' data-tipo="' . htmlspecialchars($tipo) . '"'
                . ' data-piva="' . $piva . '"'
                . ' data-cf="' . $cf . '"'
                . ' data-referente="' . $referente . '"'
                . ' data-email="' . $email . '"'
                . ' data-telefono="' . $telefono . '"'
                . ' data-indirizzo="' . $indirizzo . '"'
                . ' data-note="' . $note . '"'
                . '>';
            $html .= '<td class="fw-semibold">' . $ragioneSociale . '</td>';
            $html .= '<td><span class="badge bg-' . $badgeClass . '">' . $tipoLabel . '</span></td>';
            $html .= '<td><code>' . $piva . '</code></td>';
            $html .= '<td>' . $referente . '</td>';
            $html .= '<td><a href="mailto:' . $email . '" class="text-decoration-none">' . $email . '</a></td>';
            $html .= '<td class="text-center"><span class="badge bg-light text-dark border">' . htmlspecialchars($nCantieri) . '</span></td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-outline-primary btn-sm btnEditCliente" data-id="' . $id . '" title="Modifica"><i class="bi bi-pencil"></i></button>';
            $html .= '</td></tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal();
        $html .= '</div>';
        return $html;
    }

    private function modal(): string {
        return '
<div class="modal fade" id="modalCliente" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-person-badge me-2"></i><span class="modaltitle">Nuovo Cliente</span></h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-danger d-none modalalert" role="alert"><span class="modalalertmsg"></span></div>
        <input type="hidden" class="clienteid" value="">
        <div class="row g-3">
          <div class="col-md-8">
            <label class="form-label fw-semibold">Ragione Sociale / Nome <span class="text-danger">*</span></label>
            <input type="text" class="form-control cltnome clientereq" id="cltnome" placeholder="Acme Srl">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">Tipo <span class="text-danger">*</span></label>
            <select class="form-select clttipo clientereq" id="clttipo_sel">
              <option value="">— Seleziona —</option>
              <option value="azienda">Azienda</option>
              <option value="privato">Privato</option>
              <option value="ente">Ente</option>
              <option value="pa">PA</option>
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">P.IVA</label>
            <input type="text" class="form-control cltpiva" id="cltpiva" placeholder="01234567890">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Codice Fiscale</label>
            <input type="text" class="form-control cltcf" id="cltcf" placeholder="RSSMRA80A01H501U">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Referente</label>
            <input type="text" class="form-control cltreferente" id="cltreferente">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Telefono</label>
            <input type="text" class="form-control clttel" id="clttel">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Email</label>
            <input type="email" class="form-control cltemail" id="cltemail">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Indirizzo</label>
            <input type="text" class="form-control cltindirizzo" id="cltindirizzo">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Note</label>
            <textarea class="form-control cltnote" id="cltnote" rows="2"></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <small class="text-muted me-auto msghint d-none">Compila i campi obbligatori <span class="text-danger">*</span></small>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnSaveCliente" disabled>Salva</button>
      </div>
    </div>
  </div>
</div>';
    }
}
