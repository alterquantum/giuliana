<?php
namespace interfaces\services;

interface CurrentUserInfoGetInterface {
    public function getInfo();
}

interface CurrentUserInfoSetInterface {
    public function setInfo($info): void;
}

interface CurrentFirstAccessSetInterface {
    public function setFirstAccess(): void;
}
