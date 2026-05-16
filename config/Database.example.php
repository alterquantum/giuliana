<?php
return [
    'driver'   => 'pgsql',
    'host'     => '127.0.0.1',
    'port'     => '5432',
    'database' => 'giuliana',
    'username' => 'postgres',
    'password' => 'YOUR_PASSWORD_HERE',
    'charset'  => 'utf8',
    'options'  => [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ],
];
