<?php
namespace controllers;

require_once __DIR__ . '/../views/NavbarView.php';

use views\NavbarView;

class NavbarViewController {

    public function render(string $page, array $user): string {
        return (new NavbarView())->display($page, $user);
    }
}
