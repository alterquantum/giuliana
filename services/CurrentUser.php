<?php
namespace services;

if (!isset($_SESSION)) {
    session_start();
}

require_once __DIR__ . '/../interfaces/services/CurrentUserServiceImplementation.php';

use interfaces\services\CurrentUserInfoGetInterface;
use interfaces\services\CurrentUserInfoSetInterface;
use interfaces\services\CurrentFirstAccessSetInterface;

class CurrentUser implements CurrentUserInfoGetInterface, CurrentUserInfoSetInterface, CurrentFirstAccessSetInterface {

    const appname = 'giuliana';

    public function getInfo() {
        return isset($_SESSION[self::appname]) ? $_SESSION[self::appname]['info'] : false;
    }

    public function setInfo($info): void {
        $_SESSION[self::appname]['info'] = $info;
    }

    public function setFirstAccess(): void {
        $_SESSION[self::appname]['info']['first_access'] = 0;
    }

    public static function unsetInfo(): void {
        if (isset($_SESSION[self::appname])) {
            unset($_SESSION[self::appname]);
        }
    }
}
