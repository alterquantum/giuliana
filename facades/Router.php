<?php
namespace facades;

require_once __DIR__ . '/../services/CurrentUser.php';
require_once __DIR__ . '/../services/Response.php';
require_once __DIR__ . '/../controllers/NavbarViewController.php';
require_once __DIR__ . '/../controllers/DashboardController.php';
require_once __DIR__ . '/../controllers/CantiereListController.php';
require_once __DIR__ . '/../controllers/OperaioListController.php';
require_once __DIR__ . '/../controllers/ClienteListController.php';
require_once __DIR__ . '/../controllers/FornitoreListController.php';
require_once __DIR__ . '/../controllers/MezzoListController.php';
require_once __DIR__ . '/../controllers/MaterialeListController.php';
require_once __DIR__ . '/../controllers/DocumentoListController.php';
require_once __DIR__ . '/../controllers/GanttController.php';
require_once __DIR__ . '/../controllers/ReportController.php';
require_once __DIR__ . '/../controllers/PrezziarioDeiController.php';
require_once __DIR__ . '/../controllers/ComputiListController.php';
require_once __DIR__ . '/../controllers/AnalisiComputiController.php';

use services\CurrentUser;
use services\Response;
use controllers\NavbarViewController;
use controllers\DashboardController;
use controllers\CantiereListController;
use controllers\OperaioListController;
use controllers\ClienteListController;
use controllers\FornitoreListController;
use controllers\MezzoListController;
use controllers\MaterialeListController;
use controllers\DocumentoListController;
use controllers\GanttController;
use controllers\ReportController;
use controllers\PrezziarioDeiController;
use controllers\ComputiListController;
use controllers\AnalisiComputiController;

class Router {
    private Response $response;
    private ?array $data;
    private CurrentUser $currentUser;

    public function __construct() {
        $this->data        = filter_input_array(INPUT_POST) ?? [];
        $this->currentUser = new CurrentUser();
        $this->response    = new Response();
    }

    public function goTo(): array {
        $user = $this->currentUser->getInfo();

        if (!$user) {
            $this->response->setRes('no');
            $this->response->setMsg('Sessione scaduta.');
        } else {
            $page = $this->data['page'] ?? '';

            $this->response->setHr((new NavbarViewController())->render($page, $user));

            switch ($page) {
                case 'dashboard':
                    $this->response->setDom((new DashboardController())->render());
                    break;
                case 'cantieri':
                    $this->response->setDom((new CantiereListController())->render());
                    break;
                case 'operai':
                    $this->response->setDom((new OperaioListController())->render());
                    break;
                case 'clienti':
                    $this->response->setDom((new ClienteListController())->render());
                    break;
                case 'fornitori':
                    $this->response->setDom((new FornitoreListController())->render());
                    break;
                case 'presenze':
                    $this->response->setDom('<div class="p-4"><div class="fogliowrapper"></div><div class="grigliawrapper"></div></div>');
                    break;
                case 'mezzi':
                    $this->response->setDom((new MezzoListController())->render());
                    break;
                case 'materiali':
                    $this->response->setDom((new MaterialeListController())->render());
                    break;
                case 'documenti':
                    $this->response->setDom((new DocumentoListController())->render());
                    break;
                case 'gantt':
                    $this->response->setDom((new GanttController($this->data))->render());
                    break;
                case 'report':
                    $this->response->setDom((new ReportController())->render());
                    break;
                case 'prezziario_dei':
                    $this->response->setDom((new PrezziarioDeiController())->render());
                    break;
                case 'computi':
                    $idCant = $this->data['id_cantiere'] ?? '';
                    $this->response->setDom((new ComputiListController($idCant))->render());
                    break;
                case 'analisi_computo':
                    $idComp = $this->data['id_computo'] ?? '';
                    $this->response->setDom((new AnalisiComputiController($idComp))->render());
                    break;
                default:
                    $this->response->setDom((new DashboardController())->render());
                    break;
            }

            $this->response->setRes('ok');
        }

        return $this->response->getRes();
    }
}

$r = (new Router())->goTo();
echo json_encode([
    'dom' => $r['dom'],
    'res' => $r['res'],
    'hr'  => $r['hr'],
    'msg' => $r['msg'],
]);
