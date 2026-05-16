<?php
namespace views;

class FoglioGiornalieroView {

    private array $statiPresenza = ['presente', 'assente', 'ferie', 'malattia', 'permesso'];

    private array $statoBtnClass = [
        'presente' => 'btn-success',
        'assente'  => 'btn-danger',
        'ferie'    => 'btn-primary',
        'malattia' => 'btn-warning',
        'permesso' => 'btn-info',
    ];

    private array $statoLabel = [
        'presente' => 'P',
        'assente'  => 'A',
        'ferie'    => 'F',
        'malattia' => 'M',
        'permesso' => 'Per',
    ];

    public function display(array $rows): string {
        if (empty($rows)) {
            return '<div class="alert alert-info m-3">Nessun operaio assegnato a questo cantiere per la data selezionata.</div>';
        }

        $html = '<div class="fogliogiornaliero">';

        foreach ($rows as $row) {
            $idOperaio    = htmlspecialchars($row['id_operaio']           ?? '');
            $nome         = htmlspecialchars($row['nome']                 ?? '');
            $cognome      = htmlspecialchars($row['cognome']              ?? '');
            $qualifiche   = htmlspecialchars($row['qualifiche']           ?? '');
            $stato        = $row['stato']              ?? '';
            $oreOrd       = $row['ore_ordinarie']      ?? 0;
            $oreStr       = $row['ore_straordinarie']  ?? 0;
            $approvazione = $row['stato_approvazione'] ?? '';
            $isLocked     = ($approvazione === 'chiuso');

            $lockedAttr   = $isLocked ? ' data-locked="1"' : '';
            $disabledAttr = $isLocked ? ' disabled' : '';
            $lockedBadge  = $isLocked ? '<span class="badge bg-secondary ms-2"><i class="bi bi-lock-fill"></i> Chiuso</span>' : '';

            $html .= '<div class="workercard border rounded p-3 mb-2" data-id-operaio="' . $idOperaio . '" data-state="' . htmlspecialchars($stato) . '" data-ore-ord="' . htmlspecialchars((string)$oreOrd) . '" data-ore-str="' . htmlspecialchars((string)$oreStr) . '"' . $lockedAttr . '>';

            // Header row
            $html .= '<div class="d-flex align-items-center justify-content-between">';
            $html .= '<div>';
            $html .= '<strong>' . $cognome . ' ' . $nome . '</strong>';
            $html .= $lockedBadge;
            $html .= '</div>';
            $html .= '<small class="text-muted">' . $qualifiche . '</small>';
            $html .= '</div>';

            // State buttons + hours
            $html .= '<div class="d-flex gap-2 mt-2 flex-wrap align-items-center">';

            foreach ($this->statiPresenza as $s) {
                $active   = ($stato === $s) ? ' active' : '';
                $outline  = ($stato === $s) ? '' : 'outline-';
                $btnClass = 'btn-' . $outline . ltrim($this->statoBtnClass[$s], 'btn-');
                // Rebuild properly
                $baseCls  = $this->statoBtnClass[$s]; // e.g. btn-success
                if ($stato === $s) {
                    $cls = $baseCls;
                } else {
                    $cls = str_replace('btn-', 'btn-outline-', $baseCls);
                }
                $html .= '<button class="btn ' . $cls . ' btn-sm btnStato' . $disabledAttr . '" data-stato="' . $s . '" title="' . ucfirst($s) . '">';
                $html .= $this->statoLabel[$s];
                $html .= '</button>';
            }

            // Hours display
            $html .= '<div class="ms-auto d-flex align-items-center gap-3">';
            $html .= '<div class="d-flex flex-column align-items-center">';
            $html .= '<small class="text-muted" style="font-size:.65rem;">ORD</small>';
            $html .= '<input type="number" class="form-control form-control-sm text-center oreOrdinarie" style="width:60px;" value="' . htmlspecialchars((string)$oreOrd) . '" min="0" max="24" step="0.5"' . $disabledAttr . '>';
            $html .= '</div>';
            $html .= '<div class="d-flex flex-column align-items-center">';
            $html .= '<small class="text-muted" style="font-size:.65rem;">STR</small>';
            $html .= '<input type="number" class="form-control form-control-sm text-center oreStraordinarie" style="width:60px;" value="' . htmlspecialchars((string)$oreStr) . '" min="0" max="12" step="0.5"' . $disabledAttr . '>';
            $html .= '</div>';
            $html .= '</div>';

            $html .= '</div>'; // d-flex gap-2
            $html .= '</div>'; // workercard
        }

        $html .= '</div>'; // fogliogiornaliero

        return $html;
    }
}
