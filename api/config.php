<?php
// ============================================================
//  Database Configuration
//  Edit these values before deploying to your server
// ============================================================

define('DB_HOST', 'localhost');
define('DB_NAME', 'wedding_india_db');
define('DB_USER', 'root');         // apna DB username daalo
define('DB_PASS', '');             // apna DB password daalo
define('DB_CHARSET', 'utf8mb4');

// ============================================================
//  App Configuration
// ============================================================
define('APP_NAME', 'Wedding India');
define('JWT_SECRET', 'wedding_india_secret_key_2025');  // production mein change karo
define('OTP_EXPIRY_MINUTES', 10);
define('TOKEN_EXPIRY_DAYS', 30);

// Upload settings
define('UPLOAD_DIR', __DIR__ . '/uploads/');
define('UPLOAD_URL', 'https://weddingindiamatrimony.com/api/uploads/');
define('MAX_FILE_SIZE', 5 * 1024 * 1024); // 5MB

// ============================================================
//  CORS Headers - Allow Flutter app to call API
// ============================================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ============================================================
//  Database Connection (PDO)
// ============================================================
function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        } catch (PDOException $e) {
            sendError(500, 'Database connection failed');
        }
    }
    return $pdo;
}

// ============================================================
//  Response Helpers
// ============================================================
function sendSuccess($data = [], $message = 'Success', $code = 200) {
    http_response_code($code);
    echo json_encode([
        'status'  => true,
        'message' => $message,
        'data'    => $data,
    ]);
    exit();
}

function sendError($code = 400, $message = 'Error') {
    http_response_code($code);
    echo json_encode([
        'status'  => false,
        'message' => $message,
        'data'    => null,
    ]);
    exit();
}

// ============================================================
//  Auth Token Helpers
// ============================================================
function generateToken($userId) {
    $payload = $userId . '|' . time() . '|' . bin2hex(random_bytes(16));
    return base64_encode($payload);
}

function validateToken($token) {
    if (!$token) return false;

    // Dev mode bypass: 'dev_token_' se shuru hone wale tokens allow karo
    if (strpos($token, 'dev_token_') === 0) {
        // Dev token se phone number nikalo
        $phone = substr($token, strlen('dev_token_'));
        $phone = preg_replace('/\D/', '', $phone); // sirf numbers
        if (strlen($phone) >= 10) {
            $phone10 = substr($phone, -10); // last 10 digits
            $db = getDB();
            $stmt = $db->prepare("SELECT id FROM users WHERE phone = ?");
            $stmt->execute([$phone10]);
            $user = $stmt->fetch();
            if ($user) return (int)$user['id'];

            // User nahi mila to create karo (dev mode mein)
            $stmt = $db->prepare("INSERT INTO users (phone, country_code, is_verified, auth_token, token_expires_at) VALUES (?, '+91', 1, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))");
            $stmt->execute([$phone10, $token]);
            return (int)$db->lastInsertId();
        }
    }

    $db = getDB();
    $stmt = $db->prepare("SELECT id FROM users WHERE auth_token = ? AND token_expires_at > NOW() AND is_verified = 1");
    $stmt->execute([$token]);
    $user = $stmt->fetch();
    return $user ? (int)$user['id'] : false;
}

function getAuthUserId() {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    if (strpos($authHeader, 'Bearer ') === 0) {
        $token = substr($authHeader, 7);
        $userId = validateToken($token);
        if (!$userId) sendError(401, 'Unauthorized. Please login again.');
        return $userId;
    }
    sendError(401, 'Authorization token missing.');
}

// ============================================================
//  Input Helper
// ============================================================
function getInput() {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    if ($data === null) {
        $data = $_POST;
    }
    return $data;
}
