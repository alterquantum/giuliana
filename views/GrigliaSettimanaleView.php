<?php
namespace views;

class GrigliaSettimanaleView {

    private array $cellClass = [
        'presente' => 'cell-ord bg-success bg-opacity-25',
        'assente'  => 'cell-ass bg-danger bg-opacity-25',
        'ferie'    => 'cell-fer bg-primary bg-opacity-25',
        'malattia' => 'cell-mal bg-warning bg-opacity-25',
        'permesso' => 'cell-per',
        ''         => 'cell-empty bg-light',
    ];

    private array $cellAbbr = [
        'presente' => 'P',
        'assente'  => 'A',
        'ferie'    => 'F',
        'malattia' => 'M',
        'permesso' => 'Per',
    ];

    private array $days = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];
    private array $dayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    public function display(array $rows, int $anno, int $settimana): string {
        $html  = '<div class="p-3">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-3">';
        $html .= '<h6 class="mb-0 fw-semibold"><i class="bi bi-calendar3-range me-1"></i>Settimana ' . $settimana . ' / ' . $anno . '</h6>';
        $html .= '<button class="btn btn-warning btn-sm" id="btnChiudiSettimana"><i class="bi bi-lock me-1"></i>Chiudi Settimana</button>';
        $html .= '</div>';

        if (empty($rows)) {
            $html .= '<div class="alert alert-info">Nessun dato per questa settimana.</div>';
            $html .= '</div>';
            return $html;
        }

        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-sm table-bordered align-middle griglia-settimanale">';
        $html .= '<thead class="table-dark">';
        $html .= '<tr>';
        $html .= '<th>Operaio</th>';

        foreach ($this->dayLabels as $label) {
            $html .= '<th class="text-center" style="width:50px;">' . $label . '</th>';
        }

        $html .= '</tr>';
        $html .= '</thead>';
        $html .= '<tbody>';

        foreach ($rows as $row) {
            $idOperaio = htmlspecialchars($row['id_operaio'] ?? '');
            $nome      = htmlspecialchars($row['nome']       ?? '');
            $cognome   = htmlspecialchars($row['cognome']    ?? '');

            $html .= '<tr data-id-operaio="' . $idOperaio . '">';
            $html .= '<td class="fw-semibold">' . $cognome . ' ' . $nome . '</td>';

            foreach ($this->days as $day) {
                $val       = trim((string)($row[$day] ?? ''));
                $cellCls   = $this->cellClass[$val] ?? ($this->cellClass[''] );
                // Handle numeric values (ore_ordinarie stored as day value)
                if (is_numeric($val) && $val !== '') {
                    $cellCls = 'cell-ord bg-success bg-opacity-25';
                    $display = $val;
                } else {
                    $display = $this->cellAbbr[$val] ?? '';
                }
                $html .= '<td class="text-center ' . $cellCls . '" style="font-size:.8rem;">' . htmlspecialchars($display) . '</td>';
            }

            $html .= '</tr>';
        }

        $html .= '</tbody>';
        $html .= '</table>';
        $html .= '</div>'; // table-responsive

        // Legend
        $html .= '<div class="d-flex gap-3 mt-2 flex-wrap">';
        $legend = [
            ['cls' => 'bg-success bg-opacity-25', 'label' => 'Presente'],
            ['cls' => 'bg-danger bg-opacity-25',  'label' => 'Assente'],
            ['cls' => 'bg-primary bg-opacity-25', 'label' => 'Ferie'],
            ['cls' => 'bg-warning bg-opacity-25', 'label' => 'Malattia'],
            ['cls' => 'bg-info bg-opacity-25',    'label' => 'Permesso'],
            ['cls' => 'bg-light border',          'label' => 'Non assegnato'],
        ];
        foreach ($legend as $l) {
            $html .= '<div class="d-flex align-items-center gap-1">';
            $html .= '<div class="rounded" style="width:14px;height:14px;" class="' . $l['cls'] . '"></div>';
            $html .= '<small class="text-muted">' . $l['label'] . '</small>';
            $html .= '</div>';
        }
        $html .= '</div>';

        $html .= '</div>'; // p-3

        return $html;
    }
}
