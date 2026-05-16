<?php
namespace facades;

require_once __DIR__ . '/../services/CurrentUser.php';
require_once __DIR__ . '/../services/Response.php';
require_once __DIR__ . '/../controllers/AuthLoginController.php';
require_once __DIR__ . '/../controllers/CantiereUpsertController.php';
require_once __DIR__ . '/../controllers/OperaioUpsertController.php';
require_once __DIR__ . '/../controllers/OperaioToggleController.php';
require_once __DIR__ . '/../controllers/ClienteUpsertController.php';
require_once __DIR__ . '/../controllers/FornitoreUpsertController.php';
require_once __DIR__ . '/../controllers/PresenzaUpsertController.php';
require_once __DIR__ . '/../controllers/SettimanaChiudiController.php';
require_once __DIR__ . '/../controllers/MezzoUpsertController.php';
require_once __DIR__ . '/../controllers/MaterialeUpsertController.php';
require_once __DIR__ . '/../controllers/DocumentoUpsertController.php';
require_once __DIR__ . '/../controllers/GanttUpsertController.php';
require_once __DIR__ . '/../controllers/EvmSnapshotController.php';

use services\CurrentUser;
use services\Response;
use controllers\AuthLoginController;
use controllers\CantiereUpsertController;
use controllers\OperaioUpsertController;
use controllers\OperaioToggleController;
use controllers\ClienteUpsertController;
use controllers\FornitoreUpsertController;
use controllers\PresenzaUpsertController;
use controllers\SettimanaChiudiController;
use controllers\MezzoUpsertController;
use controllers\MaterialeUpsertController;
use controllers\DocumentoUpsertController;
use controllers\GanttUpsertController;
use controllers\EvmSnapshotController;

class Performer {
    private Response $response;
    private ?array $data;
    private CurrentUser $currentUser;

    public function __construct() {
        $this->data        = filter_input_array(INPUT_POST) ?? [];
        $this->currentUser = new CurrentUser();
        $this->response    = new Response();
    }

    public function perform(): array {
        $user   = $this->currentUser->getInfo();
        $action = $this->data['action'] ?? '';

        if (!$user && $action !== 'login') {
            $this->response->setRes('no');
            $this->response->setMsg('Sessione scaduta.');
            return $this->response->getRes();
        }

        switch ($action) {

            case 'login':
                $result = (new AuthLoginController($this->data))->login();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                $this->response->setDest($result['dest']);
                break;

            case 'logout':
                CurrentUser::unsetInfo();
                $this->response->setRes('ok');
                $this->response->setMsg('Logout effettuato.');
                break;

            case 'cantiere_create':
            case 'cantiere_update':
                $result = (new CantiereUpsertController($this->data))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                $this->response->setDbRes($result['dbres']);
                break;

            case 'operaio_create':
            case 'operaio_update':
                $result = (new OperaioUpsertController($this->data))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                $this->response->setDbRes($result['dbres']);
                break;

            case 'operaio_toggle':
                $result = (new OperaioToggleController($this->data))->toggle();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                $this->response->setDbRes($result['dbres']);
                break;

            case 'cliente_create':
            case 'cliente_update':
                $result = (new ClienteUpsertController($this->data))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                $this->response->setDbRes($result['dbres']);
                break;

            case 'fornitore_create':
            case 'fornitore_update':
                $result = (new FornitoreUpsertController($this->data))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                $this->response->setDbRes($result['dbres']);
                break;

            case 'presenza_upsert':
                $dataWithUser = array_merge($this->data, ['id_registrato_da' => $user['id'] ?? null]);
                $result = (new PresenzaUpsertController($dataWithUser))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                $this->response->setDbRes($result['dbres']);
                break;

            case 'foglio_giornaliero_save':
                // Loop over JSON presenze array
                $presenzeJson = $this->data['presenze'] ?? '[]';
                $presenzeArr  = json_decode($presenzeJson, true);
                $errors       = [];
                $saved        = 0;

                if (is_array($presenzeArr)) {
                    foreach ($presenzeArr as $presenza) {
                        $entry = array_merge($this->data, $presenza, ['id_registrato_da' => $user['id'] ?? null]);
                        $r     = (new PresenzaUpsertController($entry))->upsert();
                        if ($r['res'] === 'ok') {
                            $saved++;
                        } else {
                            $errors[] = $r['msg'];
                        }
                    }
                }

                if (empty($errors)) {
                    $this->response->setRes('ok');
                    $this->response->setMsg('Salvate ' . $saved . ' presenze.');
                } else {
                    $this->response->setRes('no');
                    $this->response->setMsg('Errori: ' . implode('; ', $errors));
                }
                break;

            case 'settimana_chiudi':
                $dataWithUser2 = array_merge($this->data, ['id_utente' => $user['id'] ?? null]);
                $result = (new SettimanaChiudiController($dataWithUser2))->chiudi();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                $this->response->setDbRes($result['dbres']);
                break;

            case 'mezzo_create':
            case 'mezzo_update':
                $result = (new MezzoUpsertController($this->data))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                break;

            case 'materiale_create':
            case 'materiale_update':
                $result = (new MaterialeUpsertController($this->data))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                break;

            case 'documento_create':
                $result = (new DocumentoUpsertController($this->data))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                break;

            case 'attivita_gantt_upsert':
                $result = (new GanttUpsertController($this->data))->upsert();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                break;

            case 'evm_snapshot':
                $result = (new EvmSnapshotController($this->data))->snapshot();
                $this->response->setRes($result['res']);
                $this->response->setMsg($result['msg']);
                break;

            default:
                $this->response->setRes('no');
                $this->response->setMsg('Azione non riconosciuta: ' . htmlspecialchars($action));
                break;
        }

        return $this->response->getRes();
    }
}

$p = (new Performer())->perform();
echo json_encode([
    'dom'   => $p['dom'],
    'msg'   => $p['msg'],
    'res'   => $p['res'],
    'dbres' => $p['dbres'],
    'hr'    => $p['hr'],
    'dest'  => $p['dest'],
]);
