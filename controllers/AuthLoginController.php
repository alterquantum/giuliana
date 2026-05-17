<?php
namespace controllers;

require_once __DIR__ . '/../models/AuthLoginModel.php';
require_once __DIR__ . '/../controllers/UserInfoController.php';
require_once __DIR__ . '/../services/Response.php';

use models\AuthLoginModel;
use services\Response;

class AuthLoginController {
    private array $data;
    private Response $response;

    public function __construct(array $data) {
        $this->data     = $data;
        $this->response = new Response();
    }

    public function login(): array {
        $username = trim($this->data['username'] ?? '');
        $pwd      = $this->data['pwd'] ?? '';

        if (empty($username) || empty($pwd)) {
            $this->response->setRes('no');
            $this->response->setMsg('Inserire email e password.');
            return $this->response->getRes();
        }

        $row = (new AuthLoginModel())->getByUsername($username);

        if (empty($row)) {
            $this->response->setRes('no');
            $this->response->setMsg('Credenziali non valide.');
            return $this->response->getRes();
        }

        if (!$row['attivo']) {
            $this->response->setRes('no');
            $this->response->setMsg('Account disabilitato.');
            return $this->response->getRes();
        }

        if (!password_verify($pwd, $row['password_hash'])) {
            $this->response->setRes('no');
            $this->response->setMsg('Credenziali non valide.');
            return $this->response->getRes();
        }

        UserInfoController::set($row);

        $dest = ($row['ruolo'] === 'admin') ? './dashboard.html' : './presenze.html';

        $this->response->setRes('ok');
        $this->response->setDest($dest);
        return $this->response->getRes();
    }
}
