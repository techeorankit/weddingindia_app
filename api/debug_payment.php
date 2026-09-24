<?php
// Debug file - upload to public_html/debug_payment.php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$headers = getallheaders();
$body = file_get_contents('php://input');

echo json_encode([
    'status' => true,
    'method' => $_SERVER['REQUEST_METHOD'],
    'headers' => $headers,
    'body' => json_decode($body, true) ?? $body,
    'get' => $_GET,
    'server_time' => date('Y-m-d H:i:s'),
]);
