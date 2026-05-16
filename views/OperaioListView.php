<?php
namespace views;

class OperaioListView {

    public function display(array $rows): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-people me-2"></i>Operai</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnNewOperaio"><i class="bi bi-plus-lg me-1"></i>Nuovo Operaio</button>';
        $html .= '</div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun operaio trovato.</div>';
            $html .= $this->modal();
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Nome</th><th>Cognome</th><th>Cod. Fiscale</th><th>Telefono</th>';
        $html .= '<th>Data Assunzione</th><th class="text-center">Attivo</th>';
        $html .= '<th class="text-center" style="width:80px;">Azioni</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $id             = htmlspecialchars($row['id']              ?? '');
            $nome           = htmlspecialchars($row['nome']            ?? '');
            $cognome        = htmlspecialchars($row['cognome']         ?? '');
            $cf             = htmlspecialchars($row['codice_fiscale']  ?? '');
            $telefono       = htmlspecialchars($row['telefono']        ?? '');
            $email          = htmlspecialchars($row['email']           ?? '');
            $dataNascita    = htmlspecialchars($row['data_nascita']    ?? '');
            $dataAssunzione = htmlspecialchars($row['data_assunzione'] ?? '');
            $attivo         = !empty($row['attivo']);
            $attivoInt      = $attivo ? 1 : 0;
            $toggleClass    = $attivo ? 'btn-success' : 'btn-outline-secondary';
            $toggleIcon     = $attivo ? 'bi-toggle-on' : 'bi-toggle-off';
            $toggleTitle    = $attivo ? 'Disabilita' : 'Abilita';

            $html .= '<tr class="listrow" data-id="' . $id . '"'
                . ' data-nome="' . $nome . '"'
                . ' data-cognome="' . $cognome . '"'
                . ' data-cf="' . $cf . '"'
                . ' data-telefono="' . $telefono . '"'
                . ' data-email="' . $email . '"'
                . ' data-data-nascita="' . $dataNascita . '"'
                . ' data-data-assunzione="' . $dataAssunzione . '"'
                . '>';
            $html .= '<td>' . $nome . '</td>';
            $html .= '<td class="fw-semibold">' . $cognome . '</td>';
            $html .= '<td><code>' . $cf . '</code></td>';
            $html .= '<td>' . $telefono . '</td>';
            $html .= '<td>' . $dataAssunzione . '</td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn ' . $toggleClass . ' btn-sm btnToggleOperaio" data-id="' . $id . '" data-active="' . $attivoInt . '" title="' . $toggleTitle . '">';
            $html .= '<i class="bi ' . $toggleIcon . '"></i></button>';
            $html .= '</td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-outline-primary btn-sm btnEditOperaio" data-id="' . $id . '" title="Modifica"><i class="bi bi-pencil"></i></button>';
            $html .= '</td></tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal();
        $html .= '</div>';
        return $html;
    }

    private function modal(): string {
        return '
<div class="modal fade" id="modalOperaio" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-person me-2"></i><span class="modaltitle">Nuovo Operaio</span></h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-danger d-none modalalert" role="alert"><span class="modalalertmsg"></span></div>
        <input type="hidden" class="operaioid" value="">
        <div class="row g-3">
          <div class="col-md-6">
            <label class="form-label fw-semibold">Nome <span class="text-danger">*</span></label>
            <input type="text" class="form-control opnome operaioreq" id="opnome" placeholder="Mario">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Cognome <span class="text-danger">*</span></label>
            <input type="text" class="form-control opcognome operaioreq" id="opcognome" placeholder="Rossi">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Codice Fiscale</label>
            <input type="text" class="form-control opcf" id="opcf" placeholder="RSSMRA80A01H501U" maxlength="16">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Telefono</label>
            <input type="text" class="form-control optel" id="optel" placeholder="333 1234567">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Email</label>
            <input type="email" class="form-control opemail" id="opemail" placeholder="mario.rossi@email.it">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Data di nascita</label>
            <input type="date" class="form-control opdtnascita" id="opdtnascita">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Data assunzione</label>
            <input type="date" class="form-control opdtassunzione" id="opdtassunzione">
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <small class="text-muted me-auto msghint d-none">Compila i campi obbligatori <span class="text-danger">*</span></small>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnSaveOperaio" disabled>Salva</button>
      </div>
    </div>
  </div>
</div>';
    }
}
