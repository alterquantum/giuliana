<?php
namespace views;

class NavbarView {

    public function display(string $page, array $user): string {
        $nome    = htmlspecialchars($user['nome']    ?? '');
        $cognome = htmlspecialchars($user['cognome'] ?? '');
        $ruolo   = htmlspecialchars($user['ruolo']   ?? '');

        $initials = strtoupper(
            mb_substr($user['nome']    ?? '', 0, 1) .
            mb_substr($user['cognome'] ?? '', 0, 1)
        );

        $links = [
            [
                'section' => null,
                'items'   => [
                    ['key' => 'dashboard',  'icon' => 'bi-speedometer2',         'label' => 'Dashboard'],
                ],
            ],
            [
                'section' => 'Anagrafica',
                'items'   => [
                    ['key' => 'cantieri',   'icon' => 'bi-building',             'label' => 'Cantieri'],
                    ['key' => 'operai',     'icon' => 'bi-people',               'label' => 'Operai'],
                    ['key' => 'clienti',    'icon' => 'bi-person-badge',         'label' => 'Clienti'],
                    ['key' => 'fornitori',  'icon' => 'bi-truck',                'label' => 'Fornitori'],
                ],
            ],
            [
                'section' => 'Operativo',
                'items'   => [
                    ['key' => 'presenze',   'icon' => 'bi-calendar-check',       'label' => 'Presenze'],
                    ['key' => 'mezzi',      'icon' => 'bi-truck-front',          'label' => 'Mezzi'],
                    ['key' => 'materiali',  'icon' => 'bi-boxes',                'label' => 'Materiali'],
                ],
            ],
            [
                'section' => 'Gestione',
                'items'   => [
                    ['key' => 'documenti',  'icon' => 'bi-file-earmark-text',    'label' => 'Documenti'],
                    ['key' => 'report',     'icon' => 'bi-bar-chart-line',       'label' => 'Report'],
                    ['key' => 'gantt',      'icon' => 'bi-calendar3-range',      'label' => 'Gantt'],
                ],
            ],
        ];

        $html  = '<div id="sidebar" class="d-flex flex-column bg-dark text-white" style="width:250px;min-height:100vh;flex-shrink:0;">';

        // Logo
        $html .= '<div class="p-3 border-bottom border-secondary">';
        $html .= '<div class="d-flex align-items-center gap-2">';
        $html .= '<i class="bi bi-building-fill-gear fs-4 text-warning"></i>';
        $html .= '<div><div class="fw-bold lh-1">GestioneCantieri</div><small class="text-white-50">v1.0</small></div>';
        $html .= '</div>';
        $html .= '</div>';

        // Nav
        $html .= '<nav class="flex-grow-1 py-2 overflow-auto">';

        foreach ($links as $group) {
            if ($group['section'] !== null) {
                $html .= '<div class="px-3 pt-3 pb-1">';
                $html .= '<small class="text-uppercase text-white-50 fw-semibold" style="font-size:.65rem;letter-spacing:.08em;">'
                    . htmlspecialchars($group['section'])
                    . '</small>';
                $html .= '</div>';
            }
            foreach ($group['items'] as $item) {
                $isActive   = ($page === $item['key']);
                $linkClass  = $isActive ? 'nav-link active text-white' : 'nav-link text-white-50';
                $activeBg   = $isActive ? ' bg-primary bg-opacity-25 rounded' : '';
                $href = './' . htmlspecialchars($item['key']) . '.html';
                $html .= '<a href="' . $href . '" class="' . $linkClass . ' px-3 py-2 d-flex align-items-center gap-2 text-decoration-none' . $activeBg . '">';
                $html .= '<i class="bi ' . $item['icon'] . '"></i>';
                $html .= '<span>' . htmlspecialchars($item['label']) . '</span>';
                $html .= '</a>';
            }
        }

        $html .= '</nav>';

        // User footer
        $html .= '<div class="p-3 border-top border-secondary">';
        $html .= '<div class="d-flex align-items-center gap-2">';
        $html .= '<div class="rounded-circle bg-warning text-dark d-flex align-items-center justify-content-center fw-bold flex-shrink-0" style="width:36px;height:36px;font-size:.85rem;">';
        $html .= htmlspecialchars($initials);
        $html .= '</div>';
        $html .= '<div class="flex-grow-1 overflow-hidden">';
        $html .= '<div class="fw-semibold lh-1 text-truncate">' . $nome . ' ' . $cognome . '</div>';
        $html .= '<small class="text-white-50">' . $ruolo . '</small>';
        $html .= '</div>';
        $html .= '<a href="#" id="btnlogout" class="text-white-50 text-decoration-none ms-1" title="Logout"><i class="bi bi-box-arrow-right fs-5"></i></a>';
        $html .= '</div>';
        $html .= '</div>';

        $html .= '</div>'; // #sidebar

        return $html;
    }
}
