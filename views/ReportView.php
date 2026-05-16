<?php

namespace views;

class ReportView
{
    public function display(array $data): string
    {
        $evm = $data['evm'] ?? [];
        $docScadenza = $data['doc_scadenza'] ?? [];
        $mezziScadenza = $data['mezzi_scadenza'] ?? [];

        $html = '<div class="p-4">';

        $html .= '<div class="d-flex align-items-center mb-4">';
        $html .= '<i class="bi bi-bar-chart-line fs-2 me-2"></i>';
        $html .= '<h2 class="mb-0">Report &amp; Analisi</h2>';
        $html .= '</div>';

        $html .= '<div class="mb-5">';
        $html .= '<h5>EVM Portfolio</h5>';
        if (empty($evm)) {
            $html .= '<div class="alert alert-info">Nessun dato EVM disponibile.</div>';
        } else {
            $html .= '<div class="table-responsive">';
            $html .= '<table class="table table-bordered table-hover">';
            $html .= '<thead class="table-dark"><tr>';
            $html .= '<th>Cantiere</th><th>Stato</th><th>BAC (€)</th><th>SPI</th><th>CPI</th><th>EAC (€)</th><th>VAC (€)</th><th>Snapshot</th>';
            $html .= '</tr></thead>';
            $html .= '<tbody>';
            foreach ($evm as $row) {
                $spi = round($row['spi'], 3);
                $cpi = round($row['cpi'], 3);

                if ($spi >= 1.0) {
                    $spiBadge = 'bg-success';
                } elseif ($spi >= 0.8) {
                    $spiBadge = 'bg-warning text-dark';
                } else {
                    $spiBadge = 'bg-danger';
                }

                if ($cpi >= 1.0) {
                    $cpiBadge = 'bg-success';
                } elseif ($cpi >= 0.8) {
                    $cpiBadge = 'bg-warning text-dark';
                } else {
                    $cpiBadge = 'bg-danger';
                }

                $html .= '<tr>';
                $html .= '<td>' . htmlspecialchars($row['cantiere']) . '</td>';
                $html .= '<td>' . htmlspecialchars($row['stato']) . '</td>';
                $html .= '<td>' . number_format($row['bac'], 2, ',', '.') . '</td>';
                $html .= '<td><span class="badge ' . $spiBadge . '">' . $spi . '</span></td>';
                $html .= '<td><span class="badge ' . $cpiBadge . '">' . $cpi . '</span></td>';
                $html .= '<td>' . number_format($row['eac'], 2, ',', '.') . '</td>';
                $html .= '<td>' . number_format($row['vac'], 2, ',', '.') . '</td>';
                $html .= '<td>' . htmlspecialchars($row['data_snapshot']) . '</td>';
                $html .= '</tr>';
            }
            $html .= '</tbody></table></div>';
        }
        $html .= '</div>';

        $html .= '<div class="mb-5">';
        $html .= '<h5>Documenti in scadenza (30 giorni)</h5>';
        if (empty($docScadenza)) {
            $html .= '<div class="alert alert-success">Nessun documento in scadenza.</div>';
        } else {
            $html .= '<div class="table-responsive">';
            $html .= '<table class="table table-bordered table-hover">';
            $html .= '<thead class="table-dark"><tr>';
            $html .= '<th>Nome</th><th>Tipo</th><th>Cantiere</th><th>Scadenza</th><th>Giorni</th>';
            $html .= '</tr></thead>';
            $html .= '<tbody>';
            foreach ($docScadenza as $row) {
                if ($row['scaduto']) {
                    $giorniCell = '<td class="text-danger fw-bold">Scaduto</td>';
                } elseif ($row['giorni_mancanti'] <= 7) {
                    $giorniCell = '<td class="text-danger">' . (int)$row['giorni_mancanti'] . '</td>';
                } elseif ($row['giorni_mancanti'] <= 30) {
                    $giorniCell = '<td class="text-warning">' . (int)$row['giorni_mancanti'] . '</td>';
                } else {
                    $giorniCell = '<td>' . (int)$row['giorni_mancanti'] . '</td>';
                }

                $html .= '<tr>';
                $html .= '<td>' . htmlspecialchars($row['nome']) . '</td>';
                $html .= '<td>' . htmlspecialchars($row['tipo']) . '</td>';
                $html .= '<td>' . htmlspecialchars($row['cantiere']) . '</td>';
                $html .= '<td>' . htmlspecialchars($row['data_scadenza']) . '</td>';
                $html .= $giorniCell;
                $html .= '</tr>';
            }
            $html .= '</tbody></table></div>';
        }
        $html .= '</div>';

        $html .= '<div class="mb-5">';
        $html .= '<h5>Mezzi in scadenza (30 giorni)</h5>';
        if (empty($mezziScadenza)) {
            $html .= '<div class="alert alert-success">Nessun mezzo in scadenza.</div>';
        } else {
            $html .= '<div class="table-responsive">';
            $html .= '<table class="table table-bordered table-hover">';
            $html .= '<thead class="table-dark"><tr>';
            $html .= '<th>Nome</th><th>Tipo</th><th>Targa</th><th>Scadenza</th><th>Tipo scadenza</th><th>Giorni</th>';
            $html .= '</tr></thead>';
            $html .= '<tbody>';
            foreach ($mezziScadenza as $row) {
                $giorni = $row['giorni_mancanti'];
                if ($giorni <= 0) {
                    $giorniCell = '<td class="text-danger fw-bold">Scaduto</td>';
                } elseif ($giorni <= 7) {
                    $giorniCell = '<td class="text-danger">' . (int)$giorni . '</td>';
                } elseif ($giorni <= 30) {
                    $giorniCell = '<td class="text-warning">' . (int)$giorni . '</td>';
                } else {
                    $giorniCell = '<td>' . (int)$giorni . '</td>';
                }

                $html .= '<tr>';
                $html .= '<td>' . htmlspecialchars($row['nome']) . '</td>';
                $html .= '<td>' . htmlspecialchars($row['tipo']) . '</td>';
                $html .= '<td>' . htmlspecialchars($row['targa']) . '</td>';
                $html .= '<td>' . htmlspecialchars($row['data_scadenza']) . '</td>';
                $html .= '<td>' . htmlspecialchars($row['tipo_scadenza']) . '</td>';
                $html .= $giorniCell;
                $html .= '</tr>';
            }
            $html .= '</tbody></table></div>';
        }
        $html .= '</div>';

        $html .= '</div>';

        return $html;
    }
}
