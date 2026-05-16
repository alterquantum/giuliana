<?php
namespace views;

class DashboardView {

    public function display(array $kpi): string {
        $cards = [
            [
                'key'    => 'cantieri_attivi',
                'label'  => 'Cantieri Attivi',
                'icon'   => 'bi-building',
                'color'  => '#0d6efd',
            ],
            [
                'key'    => 'operai_attivi',
                'label'  => 'Operai Attivi',
                'icon'   => 'bi-people',
                'color'  => '#198754',
            ],
            [
                'key'    => 'clienti_totali',
                'label'  => 'Clienti Totali',
                'icon'   => 'bi-person-badge',
                'color'  => '#0dcaf0',
            ],
            [
                'key'    => 'fornitori_totali',
                'label'  => 'Fornitori Totali',
                'icon'   => 'bi-truck',
                'color'  => '#6f42c1',
            ],
            [
                'key'    => 'presenze_oggi',
                'label'  => 'Presenze Oggi',
                'icon'   => 'bi-calendar-check',
                'color'  => '#ffc107',
            ],
            [
                'key'    => 'documenti_in_scadenza',
                'label'  => 'Documenti in Scadenza',
                'icon'   => 'bi-file-earmark-exclamation',
                'color'  => '#dc3545',
            ],
        ];

        $html  = '<div class="p-4">';
        $html .= '<h4 class="mb-4 fw-semibold"><i class="bi bi-speedometer2 me-2"></i>Dashboard</h4>';
        $html .= '<div class="row g-3">';

        foreach ($cards as $card) {
            $value = htmlspecialchars((string) ($kpi[$card['key']] ?? '0'));
            $html .= '<div class="col-md-4 col-lg-2">';
            $html .= '<div class="card border-0 shadow-sm h-100" style="border-left:4px solid ' . $card['color'] . ' !important;border-left-width:4px !important;">';
            $html .= '<div class="card-body">';
            $html .= '<div class="d-flex align-items-start justify-content-between">';
            $html .= '<div>';
            $html .= '<div class="text-muted small mb-1">' . htmlspecialchars($card['label']) . '</div>';
            $html .= '<div class="fs-3 fw-bold">' . $value . '</div>';
            $html .= '</div>';
            $html .= '<div class="rounded-circle d-flex align-items-center justify-content-center" style="width:42px;height:42px;background-color:' . $card['color'] . '1a;">';
            $html .= '<i class="bi ' . $card['icon'] . ' fs-5" style="color:' . $card['color'] . ';"></i>';
            $html .= '</div>';
            $html .= '</div>';
            $html .= '</div>';
            $html .= '</div>';
            $html .= '</div>';
        }

        $html .= '</div>'; // .row
        $html .= '</div>'; // .p-4

        return $html;
    }
}
