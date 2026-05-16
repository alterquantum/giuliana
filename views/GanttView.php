<?php
namespace views;

class GanttView {

    private function statoBadgeColor(string $stato): string {
        return match ($stato) {
            'in_corso'   => 'success',
            'completato' => 'primary',
            'sospeso'    => 'warning',
            default      => 'secondary',
        };
    }

    private function indexColor(float $value): string {
        if ($value >= 0.95) return 'text-success';
        if ($value >= 0.80) return 'text-warning';
        return 'text-danger';
    }

    private function vacColor(float $value): string {
        return $value >= 0 ? 'text-success' : 'text-danger';
    }

    private function progressColor(int $pct): string {
        if ($pct <= 30) return 'bg-danger';
        if ($pct <= 70) return 'bg-warning';
        return 'bg-success';
    }

    private function scostamentoHtml(?int $gg): string {
        if ($gg === null) return '';
        if ($gg === 0)         return '<span class="badge bg-success">In tempo</span>';
        if ($gg > 0 && $gg <= 7) return '<span class="badge bg-warning text-dark">+' . $gg . ' gg</span>';
        if ($gg > 7)           return '<span class="badge bg-danger">+' . $gg . ' gg</span>';
        return '<span class="badge bg-primary">' . $gg . ' gg</span>';
    }

    public function displayPortfolio(array $rows): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-2">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-calendar3-range me-2"></i>Gantt &amp; EVM</h4>';
        $html .= '</div>';
        $html .= '<p class="text-muted mb-4">Portfolio cantieri &mdash; EVM riepilogativo</p>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun dato EVM disponibile.</div>';
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="row g-3">';

        foreach ($rows as $row) {
            $cantiere     = htmlspecialchars($row['cantiere']      ?? '');
            $stato        = $row['stato']  ?? '';
            $statoLabel   = htmlspecialchars(str_replace('_', ' ', ucfirst($stato)));
            $statoColor   = $this->statoBadgeColor($stato);

            $spi          = (float) ($row['spi'] ?? 0);
            $cpi          = (float) ($row['cpi'] ?? 0);
            $bac          = number_format((float) ($row['bac'] ?? 0), 2, ',', '.');
            $vac          = (float) ($row['vac'] ?? 0);
            $vacFmt       = number_format($vac, 2, ',', '.');
            $dataSnapshot = htmlspecialchars($row['data_snapshot'] ?? '—');

            $spiColor      = $this->indexColor($spi);
            $cpiColor      = $this->indexColor($cpi);
            $vacColorClass = $this->vacColor($vac);

            $spiFmt = number_format($spi, 2, ',', '.');
            $cpiFmt = number_format($cpi, 2, ',', '.');

            $html .= '<div class="col-md-6 col-lg-4">';
            $html .= '<div class="card border-0 shadow-sm h-100"><div class="card-body">';
            $html .= '<div class="d-flex align-items-start justify-content-between mb-2">';
            $html .= '<h6 class="fw-semibold mb-0">' . $cantiere . '</h6>';
            $html .= '<span class="badge bg-' . $statoColor . '">' . $statoLabel . '</span>';
            $html .= '</div>';
            $html .= '<div class="row g-2 text-center mt-1">';
            $html .= '<div class="col-6"><small class="text-muted d-block">SPI</small><span class="fw-bold ' . $spiColor . '">' . $spiFmt . '</span></div>';
            $html .= '<div class="col-6"><small class="text-muted d-block">CPI</small><span class="fw-bold ' . $cpiColor . '">' . $cpiFmt . '</span></div>';
            $html .= '<div class="col-6"><small class="text-muted d-block">BAC</small><small>&euro; ' . $bac . '</small></div>';
            $html .= '<div class="col-6"><small class="text-muted d-block">VAC</small><small class="' . $vacColorClass . '">&euro; ' . $vacFmt . '</small></div>';
            $html .= '</div>';
            $html .= '<div class="mt-2 text-end"><small class="text-muted">Snapshot: ' . $dataSnapshot . '</small></div>';
            $html .= '</div></div></div>';
        }

        $html .= '</div></div>';
        return $html;
    }

    public function display(array $ganttRows, array $evm): string {
        $html  = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-calendar3-range me-2"></i>Gantt &amp; EVM</h4>';
        $html .= '<button class="btn btn-primary btn-sm btnNewAttivita"><i class="bi bi-plus-lg me-1"></i>Aggiungi attivit&agrave;</button>';
        $html .= '</div>';

        $bac = (float) ($evm['bac'] ?? 0);
        $spi = (float) ($evm['spi'] ?? 0);
        $cpi = (float) ($evm['cpi'] ?? 0);
        $eac = (float) ($evm['eac'] ?? 0);
        $vac = (float) ($evm['vac'] ?? 0);

        $bacFmt = number_format($bac, 2, ',', '.');
        $spiFmt = number_format($spi, 2, ',', '.');
        $cpiFmt = number_format($cpi, 2, ',', '.');
        $eacFmt = number_format($eac, 2, ',', '.');
        $vacFmt = number_format($vac, 2, ',', '.');

        $spiColor      = $this->indexColor($spi);
        $cpiColor      = $this->indexColor($cpi);
        $vacColorClass = $this->vacColor($vac);

        $html .= '<div class="row g-3 mb-4">';
        $html .= '<div class="col-auto"><div class="card border-0 shadow-sm px-3 py-2 text-center"><small class="text-muted d-block">BAC</small><strong>&euro; ' . $bacFmt . '</strong></div></div>';
        $html .= '<div class="col-auto"><div class="card border-0 shadow-sm px-3 py-2 text-center"><small class="text-muted d-block">SPI</small><strong class="' . $spiColor . '">' . $spiFmt . '</strong></div></div>';
        $html .= '<div class="col-auto"><div class="card border-0 shadow-sm px-3 py-2 text-center"><small class="text-muted d-block">CPI</small><strong class="' . $cpiColor . '">' . $cpiFmt . '</strong></div></div>';
        $html .= '<div class="col-auto"><div class="card border-0 shadow-sm px-3 py-2 text-center"><small class="text-muted d-block">EAC</small><strong>&euro; ' . $eacFmt . '</strong></div></div>';
        $html .= '<div class="col-auto"><div class="card border-0 shadow-sm px-3 py-2 text-center"><small class="text-muted d-block">VAC</small><strong class="' . $vacColorClass . '">&euro; ' . $vacFmt . '</strong></div></div>';
        $html .= '</div>';

        if (empty($ganttRows)) {
            $html .= '<div class="alert alert-info">Nessuna attivit&agrave; trovata per questo cantiere.</div>';
            $html .= $this->modal($ganttRows);
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Task</th><th>Inizio prev.</th><th>Fine prev.</th>';
        $html .= '<th class="text-end">% Compl.</th>';
        $html .= '<th class="text-end">Budget prev. (&euro;)</th>';
        $html .= '<th class="text-end">Costo eff. (&euro;)</th>';
        $html .= '<th>Scostamento</th><th style="min-width:120px;">Progress</th>';
        $html .= '<th class="text-center" style="width:60px;">Az.</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($ganttRows as $row) {
            $id             = htmlspecialchars($row['id']                    ?? '');
            $idPadre        = htmlspecialchars($row['id_padre']              ?? '');
            $nomeTask       = htmlspecialchars($row['nome']                  ?? '');
            $dataInizioPrev = htmlspecialchars($row['data_inizio_prevista']  ?? '');
            $dataFinePrev   = htmlspecialchars($row['data_fine_prevista']    ?? '');
            $pct            = (int) ($row['percentuale_completamento']       ?? 0);
            $budgetPrevRaw  = (float) ($row['budget_previsto']               ?? 0);
            $costoEffRaw    = (float) ($row['costo_effettivo']               ?? 0);
            $budgetPrev     = number_format($budgetPrevRaw, 2, ',', '.');
            $costoEff       = number_format($costoEffRaw, 2, ',', '.');
            $scostamentoGg  = isset($row['scostamento_gg']) ? (int) $row['scostamento_gg'] : null;
            $ordine         = (int) ($row['ordine']                          ?? 0);
            $isParent       = ($row['id_padre'] ?? null) === null || $row['id_padre'] === '';
            $taskClass      = $isParent ? 'fw-bold' : 'ps-3';
            $progressColor  = $this->progressColor($pct);
            $scostHtml      = $this->scostamentoHtml($scostamentoGg);

            $html .= '<tr class="listrow" data-id="' . $id . '"'
                . ' data-nome="' . $nomeTask . '"'
                . ' data-id-padre="' . $idPadre . '"'
                . ' data-dt-inizio-prev="' . $dataInizioPrev . '"'
                . ' data-dt-fine-prev="' . $dataFinePrev . '"'
                . ' data-pct="' . $pct . '"'
                . ' data-budget="' . $budgetPrevRaw . '"'
                . ' data-costo-eff="' . $costoEffRaw . '"'
                . ' data-ordine="' . $ordine . '"'
                . '>';
            $html .= '<td class="' . $taskClass . '">' . $nomeTask . '</td>';
            $html .= '<td>' . $dataInizioPrev . '</td>';
            $html .= '<td>' . $dataFinePrev . '</td>';
            $html .= '<td class="text-end">' . $pct . '%</td>';
            $html .= '<td class="text-end">' . $budgetPrev . '</td>';
            $html .= '<td class="text-end">' . $costoEff . '</td>';
            $html .= '<td>' . $scostHtml . '</td>';
            $html .= '<td>';
            $html .= '<div class="progress" style="height:8px;" role="progressbar" aria-valuenow="' . $pct . '" aria-valuemin="0" aria-valuemax="100">';
            $html .= '<div class="progress-bar ' . $progressColor . '" style="width:' . $pct . '%;"></div>';
            $html .= '</div></td>';
            $html .= '<td class="text-center">';
            $html .= '<button class="btn btn-outline-primary btn-sm btnEditAttivita" data-id="' . $id . '" title="Modifica"><i class="bi bi-pencil"></i></button>';
            $html .= '</td></tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= $this->modal($ganttRows);
        $html .= '</div>';
        return $html;
    }

    private function modal(array $ganttRows): string {
        $parentOpts = '<option value="">— Nessuno (task principale) —</option>';
        foreach ($ganttRows as $r) {
            if (($r['id_padre'] ?? null) === null || $r['id_padre'] === '') {
                $parentOpts .= '<option value="' . htmlspecialchars($r['id']) . '">' . htmlspecialchars($r['nome']) . '</option>';
            }
        }

        return '
<div class="modal fade" id="modalAttivita" data-bs-backdrop="static" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-calendar3-range me-2"></i><span class="modaltitle">Nuova Attivit&agrave;</span></h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-danger d-none modalalert" role="alert"><span class="modalalertmsg"></span></div>
        <input type="hidden" class="attivitaid" value="">
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label fw-semibold">Nome task <span class="text-danger">*</span></label>
            <input type="text" class="form-control attnome attivitareq" id="attnome" placeholder="Es. Fondazioni">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Task padre</label>
            <select class="form-select attpadre" id="attpadre_sel">
              ' . $parentOpts . '
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Ordine</label>
            <input type="number" min="0" class="form-control attordine" id="attordine" value="0">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Inizio previsto <span class="text-danger">*</span></label>
            <input type="date" class="form-control attdtinizioprev attivitareq" id="attdtinizioprev">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Fine prevista <span class="text-danger">*</span></label>
            <input type="date" class="form-control attdtfineprev attivitareq" id="attdtfineprev">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">% Completamento</label>
            <input type="number" min="0" max="100" class="form-control attpct" id="attpct" value="0">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">Budget previsto (&euro;)</label>
            <input type="number" step="0.01" min="0" class="form-control attbudget" id="attbudget" value="0">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">Costo effettivo (&euro;)</label>
            <input type="number" step="0.01" min="0" class="form-control attcosteff" id="attcosteff" value="0">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Inizio effettivo</label>
            <input type="date" class="form-control attdtinizioeff" id="attdtinizioeff">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">Fine effettiva</label>
            <input type="date" class="form-control attdtfineeff" id="attdtfineeff">
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <small class="text-muted me-auto msghint d-none">Compila i campi obbligatori <span class="text-danger">*</span></small>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annulla</button>
        <button type="button" class="btn btn-primary btnSaveAttivita" disabled>Salva</button>
      </div>
    </div>
  </div>
</div>';
    }
}
