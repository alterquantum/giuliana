<?php
namespace views;

class MezzoListView {

    private array $tipoBadge = [
        'autocarro'   => 'primary',
        'escavatore'  => 'warning',
        'gru'         => 'danger',
        'betoniera'   => 'secondary',
        'compressore' => 'info',
        'sollevatore' => 'success',
        'altro'       => 'dark',
    ];

    public function display(array $rows): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-truck-front me-2"></i>Parco Macchine</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnNewMezzo"><i class="bi bi-plus-lg me-1"></i>Nuovo Mezzo</button>';
        $html .= '</div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun mezzo trovato.</div>';
            $html .= $this->modal();
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Nome</th><th>Tipo</th><th>Targa</th><th>N&deg; Seriale</th>';
        $html .= '<th>Cantiere corrente</th><th>Data revisione</th><th>Data assicurazione</th>';
        $html .= '<th class="text-center">Stato</th>';
        $html .= '<th class="text-center" style="width:80px;">Azioni</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $id              = htmlspecialchars($row['id']              ?? '');
            $nome            = htmlspecialchars($row['nome']            ?? '');
            $tipo            = $row['tipo'] ?? '';
            $tipoLabel       = htmlspecialchars(ucfirst($tipo));
            $tipoBadge       = $this->tipoBadge[$tipo] ?? 'dark';
            $targa           = htmlspecialchars($row['targa']           ?? '');
            $numeroSeriale   = htmlspecialchars($row['numero_seriale']  ?? '');
            $cantiereCorrente = htmlspecialchars($row['cantiere_corrente'] ?? '—');
            $dataRevisione   = htmlspecialchars($row['data_revisione']  ?? '');
            $dataAssicurazione = htmlspecialchars($row['data_scadenza_assicurazione'] ?? '');
            $note            = htmlspecialchars($row['note']            ?? '');
            $attivo          = !empty($row['attivo']);

            $ggRevisioneRaw = $row['gg_scadenza_revisione'] ?? null;
            if ($ggRevisioneRaw === null) {
                $revisioneHtml = $dataRevisione ?: '—';
            } else {
                $ggRevisione = (int) $ggRevisioneRaw;
                if ($ggRevisione < 0) {
                    $revisioneHtml = '<span class="badge bg-danger">Scaduta</span>';
                } elseif ($ggRevisione < 30) {
                    $revisioneHtml = '<span class="badge bg-warning text-dark">' . $ggRevisione . 'gg</span>';
                } else {
                    $revisioneHtml = $dataRevisione;
                }
            }

            $dataAssRaw = $row['data_scadenza_assicurazione'] ?? null;
            if ($dataAssRaw === null || $dataAssRaw === '') {
                $assicurazioneHtml = '—';
            } else {
                $oggi    = new \DateTime();
                $scad    = new \DateTime($dataAssRaw);
                $diff    = (int) $oggi->diff($scad)->days;
                $expired = $scad < $oggi;
                $ggAss   = $expired ? -$diff : $diff;
                $dataFmt = htmlspecialchars($dataAssRaw);
                if ($ggAss < 0) {
                    $assicurazioneHtml = '<span class="text-danger">' . $dataFmt . '</span>';
                } elseif ($ggAss < 30) {
                    $assicurazioneHtml = '<span class="text-warning">' . $dataFmt . '</span>';
                } else {
                    $assicurazioneHtml = $dataFmt;
                }
            }

            $attivoHtml = $attivo
                ? '<i class="bi bi-check-circle-fill text-success"></i>'
                : '<i class="bi bi-circle text-secondary"></i>';

            $html .= '<tr class="listrow" data-id="' . $id . '"'
                . ' data-nome="' . $nome . '"'
                . ' data-tipo="' . htmlspecialchars($tipo) . '"'
                . ' data-targa="' . $targa . '"'
                . ' data-seriale="' . $numeroSeriale . '"'
                . ' data-dt-revisione="' . $dataRevisione . '"'
                . ' data-dt-assicurazione="' . $dataAssicurazione . '"'
                . ' data-note="' . $note . '"'
                . '>';
            $html .= '<td class="fw-semibold">' . $nome . '</td>';
            $html .= '<td><span class="badge bg-' . $tipoBadge . '">' . $tipoLabel . '</span></td>';
            $html .= '<td>' . ($targa ?: '—') . '</td>';
            $html .= '<td>' . ($numeroSeriale ?: '—') . '</td>';
            $html .= '<td>' . $cantiereCorrente . '</td>';
            $html .= '<td>' . $revisioneHtml . '</td>';
            $html .= '<td>' . $assicurazioneHtml . '</td>';
            $html .= '<td class="text-center">' . $attivoHtml . '</td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-outline-primary btn-sm btnEditMezzo" data-id="' . $id . '" title="Modifica"><i class="bi bi-pencil"></i></button>';
            $html .= '</td></tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal();
        $html .= '</div>';
        return $html;
    }

    private function modal(): string {
        return '
<div class="modal fade" id="modalMezzo" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-truck-front me-2"></i><span class="modaltitle">Nuovo Mezzo</span></h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-danger d-none modalalert" role="alert"><span class="modalalertmsg"></span></div>
        <input type="hidden" class="mezzoid" value="">
        <div class="row g-3">
          <div class="col-md-8">
            <label class="form-label fw-semibold">Nome <span class="text-danger">*</span></label>
            <input type="text" class="form-control meznome mezzoreq" id="meznome" placeholder="Es. Autocarro Iveco 75E">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">Tipo <span class="text-danger">*</span></label>
            <select class="form-select meztipo mezzoreq" id="meztipo_sel">
              <option value="">— Seleziona —</option>
              <option value="autocarro">Autocarro</option>
              <option value="escavatore">Escavatore</option>
              <option value="gru">Gru</option>
              <option value="betoniera">Betoniera</option>
              <option value="compressore">Compressore</option>
              <option value="sollevatore">Sollevatore</option>
              <option value="altro">Altro</option>
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Targa</label>
            <input type="text" class="form-control meztarga" id="meztarga" placeholder="TO 512 AB">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">N&deg; Seriale</label>
            <input type="text" class="form-control mezseriale" id="mezseriale">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Data revisione</label>
            <input type="date" class="form-control mezdtrevisione" id="mezdtrevisione">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Scad. assicurazione</label>
            <input type="date" class="form-control mezdtassicurazione" id="mezdtassicurazione">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">Note</label>
            <textarea class="form-control meznote" id="meznote" rows="2"></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <small class="text-muted me-auto msghint d-none">Compila i campi obbligatori <span class="text-danger">*</span></small>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnSaveMezzo" disabled>Salva</button>
      </div>
    </div>
  </div>
</div>';
    }
}
