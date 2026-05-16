<?php
namespace database;

use PDO;
use PDOStatement;

class Database {
    private PDO $pdo;

    public function __construct(PDO $pdo) {
        $this->pdo = $pdo;
    }

    /**
     * Calls a DB function and returns all rows.
     */
    public function call(string $function, array $params): array {
        $stmt = $this->executeFunction($function, $params);
        $result = $stmt->fetchAll();
        return $result !== false ? $result : [];
    }

    /**
     * Calls a DB function and returns a single row.
     */
    public function callOne(string $function, array $params): array {
        $stmt = $this->executeFunction($function, $params);
        $result = $stmt->fetch();
        return $result !== false ? $result : [];
    }

    /**
     * Validates function name, builds SELECT * FROM fn(?,…) with ::uuid casting
     * for UUID params, and binds BOOL/NULL/INT/STR correctly.
     */
    private function executeFunction(string $function, array $params): PDOStatement {
        // Validate function name: only alphanumeric + underscore
        if (!preg_match('/^[a-zA-Z_][a-zA-Z0-9_]*$/', $function)) {
            throw new \InvalidArgumentException("Invalid function name: $function");
        }

        $placeholders = [];
        foreach ($params as $param) {
            if ($this->isUuid($param)) {
                $placeholders[] = '?::uuid';
            } else {
                $placeholders[] = '?';
            }
        }

        $sql = sprintf(
            'SELECT * FROM %s(%s)',
            $function,
            implode(', ', $placeholders)
        );

        $stmt = $this->pdo->prepare($sql);

        $i = 1;
        foreach ($params as $param) {
            if ($param === null) {
                $stmt->bindValue($i, null, PDO::PARAM_NULL);
            } elseif (is_bool($param)) {
                $stmt->bindValue($i, $param, PDO::PARAM_BOOL);
            } elseif (is_int($param)) {
                $stmt->bindValue($i, $param, PDO::PARAM_INT);
            } else {
                $stmt->bindValue($i, $param, PDO::PARAM_STR);
            }
            $i++;
        }

        $stmt->execute();
        return $stmt;
    }

    /**
     * Checks if a value is a UUID string.
     */
    private function isUuid($value): bool {
        if (!is_string($value)) {
            return false;
        }
        return (bool) preg_match(
            '/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i',
            $value
        );
    }
}
