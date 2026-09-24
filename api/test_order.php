<?php
// Quick test - simulates create_order without auth
require_once __DIR__ . '/config.php';

function getSettingVal(PDO $db, $key, $default = '') {
    $s = $db->prepare("SELECT `value` FROM app_settings WHERE `key` = ?");
    $s->execute([$key]);
    $row = $s->fetch();
    return $row ? (string)$row['value'] : $default;
}

$db = getDB();

$appId     = getSettingVal($db, 'cashfree_app_id');
$secretKey = getSettingVal($db, 'cashfree_secret_key');
$env       = getSettingVal($db, 'cashfree_environment', 'sandbox');

// Load plan 1
$stmt = $db->prepare("SELECT * FROM upgrade_plans WHERE id = 1");
$stmt->execute();
$plan = $stmt->fetch();

$rawPrice = preg_replace('/[^0-9.]/', '', $plan['price'] ?? '0');
$amount   = (float)$rawPrice;

$cfOrderId = 'TEST_' . time();
$phone = '9999999999';

$cfPayload = [
    'order_id'       => $cfOrderId,
    'order_amount'   => $amount,
    'order_currency' => 'INR',
    'customer_details' => [
        'customer_id'    => 'test_user',
        'customer_phone' => '919999999999',
        'customer_name'  => 'Test User',
        'customer_email' => 'test@test.com',
    ],
    'order_meta' => [
        'return_url' => 'https://weddingindiamatrimony.com/payment.php?action=return&order_id=' . $cfOrderId,
        'notify_url' => 'https://weddingindiamatrimony.com/payment.php?action=webhook',
    ],
];

$baseUrl = $env === 'production' ? 'https://api.cashfree.com/pg' : 'https://sandbox.cashfree.com/pg';
$url = $baseUrl . '/orders';

$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CUSTOMREQUEST  => 'POST',
    CURLOPT_HTTPHEADER     => [
        'Content-Type: application/json',
        'x-api-version: 2023-08-01',
        'x-client-id: ' . $appId,
        'x-client-secret: ' . $secretKey,
    ],
    CURLOPT_POSTFIELDS => json_encode($cfPayload),
]);
$resp     = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo json_encode([
    'http_code'  => $httpCode,
    'curl_error' => $curlError,
    'env'        => $env,
    'amount'     => $amount,
    'app_id_len' => strlen($appId),
    'response'   => json_decode($resp, true) ?? $resp,
], JSON_PRETTY_PRINT);
