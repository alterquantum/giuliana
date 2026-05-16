<?php
namespace controllers;

require_once __DIR__ . '/../services/CurrentUser.php';

use services\CurrentUser;

class UserInfoController {

    public static function set(array $row): void {
        $cu = new CurrentUser();
        $cu->setInfo([
            'id'      => $row['id'],
            'username' => $row['username'],
            'nome'    => $row['nome'],
            'cognome' => $row['cognome'],
            'ruolo'   => $row['ruolo'],
            'attivo'  => $row['attivo'],
        ]);
    }
}
