<?php
session_start();

// DB config (same as main api)
define('DB_HOST', 'localhost');
define('DB_NAME', 'wedding_india_db');
define('DB_USER', 'root');
define('DB_PASS', '');

function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER, DB_PASS,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
        );
    }
    return $pdo;
}

function checkAdminLogin(string $username, string $password): array|false {
    try {
        $db = getDB();
        $stmt = $db->prepare("SELECT id, username, password, name FROM admins WHERE username = ? AND is_active = 1");
        $stmt->execute([trim($username)]);
        $admin = $stmt->fetch();
        if ($admin && password_verify($password, $admin['password'])) {
            // Update last login
            $db->prepare("UPDATE admins SET last_login = NOW() WHERE id = ?")->execute([$admin['id']]);
            return $admin;
        }
        return false;
    } catch (Exception $e) {
        return false;
    }
}

function requireLogin() {
    if (empty($_SESSION['admin_logged_in'])) {
        header('Location: index.php');
        exit();
    }
}

function isLoggedIn(): bool {
    return !empty($_SESSION['admin_logged_in']);
}

function currentAdmin(): array {
    return $_SESSION['admin_data'] ?? ['name' => 'Admin', 'username' => 'admin'];
}
