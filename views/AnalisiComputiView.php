<?php
namespace views;

class AnalisiComputiView {

    public function display(array $righe, string $idComputo = ''): string {
        $html = '<div class="p-4">';
        $html .= '<div class="d-flex align-items-center justify-content-between mb-4">';
        $html .= '<h4 class="fw-semibold mb-0"><i class="bi bi-bar-chart me-2"></i>Analisi Lavorazioni</h4>';
        $html .= '<button class="btn btn-sm btn-outline-secondary btnTornaComputi">'
               . '<i class="bi bi-arrow-left me-1"></i>Torna ai computi</button>';
        $html .= '</div>';

        if (empty($righe)) {
            $html .= '<div class="alert alert-warning">'
                   . 'Nessuna lavorazione trovata. Se le voci non hanno un codice DEI corrispondente '
                   . 'i calcoli non sono disponibili.'
                   . '</div>';
            $html .= '</div>';
            return $html;
        }

        // KPI card riepilogo
        $totGiorni  = array_sum(array_column($righe, 'durata_giorni'));
        $totImporto = array_sum(array_column($righe, 'importo_totale'));
        $totMat     = array_sum(array_column($righe, 'costo_materiali'));
        $totNoli    = array_sum(array_column($righe, 'costo_noli'));
        $nLav       = count($righe);

        $html .= '<div class="row g-3 mb-4">';
        $html .= $this->kpiCard('Lavorazioni', $nLav, 'bi-list-check', 'primary');
        $html .= $this->kpiCard('Durata totale', number_format($totGiorni, 1, ',', '.') . ' gg', 'bi-calendar-range', 'info');
        $html .= $this->kpiCard('Importo', number_format($totImporto, 2, ',', '.') . ' €', 'bi-currency-euro', 'success');
        $html .= $this->kpiCard('Costo materiali', number_format($totMat, 2, ',', '.') . ' €', 'bi-boxes', 'warning');
        $html .= '</div>';

        // Tabella dettaglio
        $html .= '<div class="table-responsive">';
        $html .= '<table class="table table-hover table-bordered align-middle table-sm">';
        $html .= '<thead class="table-dark"><tr>';
        $html .= '<th>Codice DEI</th><th>Lavorazione</th><th>U.M.</th>';
        $html .= '<th class="text-end">Quantità</th><th class="text-end">Durata (gg)</th>';
        $html .= '<th class="text-center">N° Operai</th><th>Specializzazioni</th>';
        $html .= '<th class="text-end">Costo Mat. (€)</th><th class="text-end">Noli (€)</th>';
        $html .= '<th>Attrezzature</th>';
        $html .= '</tr></thead><tbody>';

        foreach ($righe as $r) {
            $codice   = htmlspecialchars($r['codice_dei']              ?? '—');
            $desc     = htmlspecialchars($r['descrizione_lavorazione'] ?? '');
            $um       = htmlspecialchars($r['unita_misura']            ?? '');
            $qty      = $r['quantita_totale']  !== null ? number_format((float)$r['quantita_totale'], 2, ',', '.') : '—';
            $durata   = $r['durata_giorni']    !== null ? number_format((float)$r['durata_giorni'], 1, ',', '.') : '—';
            $nOp      = $r['n_operai']         !== null ? (int)$r['n_operai'] : '—';
            $mat      = $r['costo_materiali']  !== null ? number_format((float)$r['costo_materiali'], 2, ',', '.') : '—';
            $noli     = $r['costo_noli']       !== null ? number_format((float)$r['costo_noli'], 2, ',', '.') : '—';

            // Specializzazioni da JSONB {"muratore":2,"manovale":1}
            $specRaw  = $r['specializzazioni'] ?? null;
            $specHtml = '—';
            if ($specRaw) {
                $spec     = is_string($specRaw) ? json_decode($specRaw, true) : $specRaw;
                $tags     = [];
                foreach ((array)$spec as $ruolo => $num) {
                    $tags[] = '<span class="badge bg-light text-dark border">'
                            . htmlspecialchars((string)$num) . ' ' . htmlspecialchars($ruolo)
                            . '</span>';
                }
                $specHtml = implode(' ', $tags);
            }

            // Attrezzature (array PG)
            $attrRaw  = $r['attrezzature'] ?? null;
            $attrHtml = '—';
            if ($attrRaw) {
                $attr = is_string($attrRaw)
                    ? json_decode($attrRaw, true) ?? explode(',', trim($attrRaw, '{}'))
                    : $attrRaw;
                $tags = array_map(
                    fn($a) => '<span class="badge bg-secondary">' . htmlspecialchars(trim($a)) . '</span>',
                    (array)$attr
                );
                $attrHtml = implode(' ', $tags);
            }

            $html .= '<tr>';
            $html .= '<td><code class="small">' . $codice . '</code></td>';
            $html .= '<td>' . $desc . '</td>';
            $html .= '<td>' . $um . '</td>';
            $html .= '<td class="text-end">' . $qty . '</td>';
            $html .= '<td class="text-end fw-semibold">' . $durata . '</td>';
            $html .= '<td class="text-center fw-semibold">' . $nOp . '</td>';
            $html .= '<td>' . $specHtml . '</td>';
            $html .= '<td class="text-end">' . $mat . '</td>';
            $html .= '<td class="text-end">' . $noli . '</td>';
            $html .= '<td>' . $attrHtml . '</td>';
            $html .= '</tr>';
        }

        $html .= '</tbody></table></div>';
        $html .= '</div>';
        return $html;
    }

    private function kpiCard(string $label, mixed $val, string $icon, string $color): string {
        return '<div class="col-6 col-md-3">'
             . '<div class="card border-' . $color . ' h-100">'
             . '<div class="card-body text-center">'
             . '<div class="display-6 text-' . $color . ' mb-1"><i class="bi ' . $icon . '"></i></div>'
             . '<div class="fw-bold fs-5">' . $val . '</div>'
             . '<div class="text-muted small">' . $label . '</div>'
             . '</div></div></div>';
    }
}
