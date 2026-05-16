<?php
namespace services;

class Response {
    public $ar = [];

    public function __construct() {
        $this->ar = [
            'res'   => 'no',
            'dom'   => null,
            'cmp'   => null,
            'msg'   => null,
            'dbres' => null,
            'hr'    => null,
            'dest'  => null,
        ];
    }

    public function setRes($res = 'no')   { $this->ar['res']   = $res; }
    public function setDom($dom = null)   { $this->ar['dom']   = $dom; }
    public function setCmp($cmp = null)   { $this->ar['cmp']   = $cmp; }
    public function setMsg($msg = null)   { $this->ar['msg']   = $msg; }
    public function setDbRes($dbRes = null) { $this->ar['dbres'] = $dbRes; }
    public function setHr($hr = null)     { $this->ar['hr']    = $hr; }
    public function setDest($dest = null) { $this->ar['dest']  = $dest; }

    public function getRes() { return $this->ar; }
}
