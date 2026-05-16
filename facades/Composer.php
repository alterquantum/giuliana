<?php
namespace facades;

require_once __DIR__ . '/../services/CurrentUser.php';
require_once __DIR__ . '/../services/Response.php';
require_once __DIR__ . '/../controllers/FoglioGiornalieroController.php';
require_once __DIR__ . '/../controllers/GrigliaSettimanaleController.php';
require_once __DIR__ . '/../models/OperaioListModel.php';
require_once __DIR__ . '/../models/CantiereListModel.php';
require_once __DIR__ . '/../models/FornitoreListModel.php';

use services\CurrentUser;
use services\Response;
use controllers\FoglioGiornalieroController;
use controllers\GrigliaSettimanaleController;
use models\OperaioListModel;
use models\CantiereListModel;
use models\FornitoreListModel;

class Composer {
    private Response $response;
    private ?array $data;
    private CurrentUser $currentUser;

    public function __construct() {
        $this->data        = filter_input_array(INPUT_POST) ?? [];
        $this->currentUser = new CurrentUser();
        $this->response    = new Response();
    }

    public function compose(): array {
        $user = $this->currentUser->getInfo();

        if (!$user) {
            $this->response->setRes('no');
            $this->response->setMsg('Sessione scaduta.');
            return $this->response->getRes();
        }

        $component = $this->data['compose'] ?? '';

        switch ($component) {

            case 'foglio_giornaliero':
                $html = (new FoglioGiornalieroController($this->data))->render();
                $this->response->setDom($html);
                $this->response->setRes('ok');
                break;

            case 'griglia_settimanale':
                $html = (new GrigliaSettimanaleController($this->data))->render();
                $this->response->setDom($html);
                $this->response->setRes('ok');
                break;

            case 'operai_per_cantiere':
                // Returns operai list optionally filtered by attivo, as cmp data
                $attivo = isset($this->data['attivo']) ? (bool)$this->data['attivo'] : null;
                $rows   = (new OperaioListModel())->list($attivo);
                $this->response->setCmp($rows);
                $this->response->setRes('ok');
                break;

            case 'cantieri_attivi':
                $rows = (new CantiereListModel())->list('in_corso');
                $this->response->setCmp($rows);
                $this->response->setRes('ok');
                break;

            case 'fornitori_per_categoria':
                // All fornitori — filtering by categoria done client-side or via extended model
                $rows = (new FornitoreListModel())->list();
                // Filter by categoria if provided
                $categoria = $this->data['categoria'] ?? null;
                if ($categoria !== null) {
                    $rows = array_values(array_filter($rows, function ($r) use ($categoria) {
                        return strtolower($r['categoria'] ?? '') === strtolower($categoria);
                    }));
                }
                $this->response->setCmp($rows);
                $this->response->setRes('ok');
                break;

            default:
                $this->response->setRes('no');
                $this->response->setMsg('Componente non riconosciuto.');
                break;
        }

        return $this->response->getRes();
    }
}

$c = (new Composer())->compose();
echo json_encode([
    'res' => $c['res'],
    'cmp' => $c['cmp'],
    'dom' => $c['dom'],
    'msg' => $c['msg'],
]);
