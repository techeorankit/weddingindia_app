<?php
// payment.php - Cashfree Payment Gateway API
// Endpoints:
//   GET  ?action=gateway_status  - Check if gateway is enabled
//   POST ?action=create_order    - Create Cashfree order
//   GET  ?action=verify          - Verify payment after completion
//   POST ?action=webhook         - Cashfree server webhook
//   GET  ?action=return          - Browser redirect after payment

require_once __DIR__ . '/config.php';
// If config.php is in api/ subfolder, try that path too
if (!function_exists('getDB')) {
    require_once __DIR__ . '/api/config.php';
}

$action = $_GET['action'] ?? 'gateway_status';

// Helper: get app setting value from DB
function getSettingVal(PDO $db, $key, $default = '') {
    $s = $db->prepare("SELECT `value` FROM app_settings WHERE `key` = ?");
    $s->execute([$key]);
    $row = $s->fetch();
    return $row ? (string)$row['value'] : $default;
}

// Helper: Cashfree base URL
function cashfreeBaseUrl($env) {
    return $env === 'production'
        ? 'https://api.cashfree.com/pg'
        : 'https://sandbox.cashfree.com/pg';
}

// Helper: Call Cashfree API
function cashfreeRequest($method, $path, $body, $appId, $secretKey, $env) {
    $url = cashfreeBaseUrl($env) . $path;
    $ch  = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_HTTPHEADER     => [
            'Content-Type: application/json',
            'x-api-version: 2023-08-01',
            'x-client-id: ' . $appId,
            'x-client-secret: ' . $secretKey,
        ],
    ]);
    if (!empty($body)) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }
    $resp     = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $decoded = json_decode($resp, true);
    if ($decoded === null) {
        return ['cf_error' => true, 'message' => 'Invalid response from Cashfree', 'http_code' => $httpCode];
    }
    return $decoded;
}

// ============================================================
// GET ?action=gateway_status
// ============================================================
if ($action === 'gateway_status') {
    $db      = getDB();
    $enabled = getSettingVal($db, 'cashfree_enabled', '0');
    $env     = getSettingVal($db, 'cashfree_environment', 'sandbox');
    $hasKeys = (
        getSettingVal($db, 'cashfree_app_id')    !== '' &&
        getSettingVal($db, 'cashfree_secret_key') !== ''
    );
    sendSuccess([
        'enabled'     => $enabled === '1',
        'environment' => $env,
        'has_keys'    => $hasKeys,
    ]);
}

// ============================================================
// POST ?action=create_order
// ============================================================
if ($action === 'create_order') {
    $userId = getAuthUserId();
    $input  = getInput();
    $planId = (int)($input['plan_id'] ?? 0);
    if ($planId <= 0) sendError(400, 'plan_id is required');

    $db = getDB();

    if (getSettingVal($db, 'cashfree_enabled') !== '1') {
        sendError(503, 'Payment gateway is currently disabled. Contact support.');
    }

    $appId     = getSettingVal($db, 'cashfree_app_id');
    $secretKey = getSettingVal($db, 'cashfree_secret_key');
    $env       = getSettingVal($db, 'cashfree_environment', 'sandbox');

    if ($appId === '' || $secretKey === '') {
        sendError(503, 'Payment gateway not configured. Contact admin.');
    }

    // Load plan
    $stmt = $db->prepare("SELECT * FROM upgrade_plans WHERE id = ? AND is_active = 1");
    $stmt->execute([$planId]);
    $plan = $stmt->fetch();
    if (!$plan) sendError(404, 'Plan not found');

    // Load user
    $uStmt = $db->prepare("SELECT u.phone, up.full_name FROM users u LEFT JOIN user_profiles up ON up.user_id = u.id WHERE u.id = ?");
    $uStmt->execute([$userId]);
    $user = $uStmt->fetch();
    if (!$user) sendError(404, 'User not found');

    // Parse amount
    $rawPrice = preg_replace('/[^0-9.]/', '', $plan['price'] ?? '0');
    $amount   = (float)$rawPrice;
    if ($amount <= 0) sendError(400, 'Invalid plan price');

    // Unique order ID
    $cfOrderId = 'WI_' . $userId . '_' . $planId . '_' . time();

    // Insert pending row
    $ins = $db->prepare("INSERT INTO payments (user_id, plan_id, cf_order_id, amount, currency, status) VALUES (?, ?, ?, ?, 'INR', 'PENDING')");
    $ins->execute([$userId, $planId, $cfOrderId, $amount]);

    // Phone formatting
    $phone = preg_replace('/\D/', '', $user['phone'] ?? '');
    if (strlen($phone) === 10) $phone = '91' . $phone;
    $emailFallback = $phone . '@weddingindiamatrimony.com';

    $cfPayload = [
        'order_id'       => $cfOrderId,
        'order_amount'   => $amount,
        'order_currency' => 'INR',
        'customer_details' => [
            'customer_id'    => 'user_' . $userId,
            'customer_phone' => $phone,
            'customer_name'  => $user['full_name'] ?? 'User ' . $userId,
            'customer_email' => $emailFallback,
        ],
        'order_meta' => [
            'return_url' => 'https://weddingindiamatrimony.com/api/payment.php?action=return&order_id=' . $cfOrderId,
            'notify_url' => 'https://weddingindiamatrimony.com/api/payment.php?action=webhook',
        ],
        'order_note' => ($plan['label'] ?? 'Plan') . ' - Wedding India Matrimony',
    ];

    $cfResp = cashfreeRequest('POST', '/orders', $cfPayload, $appId, $secretKey, $env);

    if (!empty($cfResp['cf_error']) || !isset($cfResp['payment_session_id'])) {
        $db->prepare("DELETE FROM payments WHERE cf_order_id = ?")->execute([$cfOrderId]);
        sendError(502, $cfResp['message'] ?? 'Cashfree order creation failed');
    }

    $sessionId = $cfResp['payment_session_id'];
    $db->prepare("UPDATE payments SET payment_session_id = ? WHERE cf_order_id = ?")->execute([$sessionId, $cfOrderId]);

    sendSuccess([
        'cf_order_id'        => $cfOrderId,
        'payment_session_id' => $sessionId,
        'amount'             => $amount,
        'environment'        => $env,
        'checkout_url'       => cashfreeBaseUrl($env) . '/checkout?payment_session_id=' . urlencode($sessionId),
    ]);
}

// ============================================================
// GET ?action=verify&order_id=WI_xxx
// ============================================================
if ($action === 'verify') {
    $userId  = getAuthUserId();
    $orderId = trim($_GET['order_id'] ?? '');
    if ($orderId === '') sendError(400, 'order_id is required');

    $db = getDB();

    $pStmt = $db->prepare("SELECT * FROM payments WHERE cf_order_id = ? AND user_id = ?");
    $pStmt->execute([$orderId, $userId]);
    $payment = $pStmt->fetch();
    if (!$payment) sendError(404, 'Order not found');

    if ($payment['status'] === 'SUCCESS') {
        sendSuccess(['status' => 'SUCCESS', 'already_activated' => true], 'Payment already verified');
    }

    $appId     = getSettingVal($db, 'cashfree_app_id');
    $secretKey = getSettingVal($db, 'cashfree_secret_key');
    $env       = getSettingVal($db, 'cashfree_environment', 'sandbox');

    $cfResp   = cashfreeRequest('GET', '/orders/' . $orderId, [], $appId, $secretKey, $env);
    $cfStatus = strtoupper($cfResp['order_status'] ?? 'UNKNOWN');

    if ($cfStatus === 'PAID') {
        $plan = $db->prepare("SELECT * FROM upgrade_plans WHERE id = ?");
        $plan->execute([$payment['plan_id']]);
        $plan = $plan->fetch();

        $db->prepare("UPDATE user_subscriptions SET status='expired' WHERE user_id=? AND status='active'")->execute([$userId]);
        $db->prepare("INSERT INTO user_subscriptions (user_id, plan_id, profile_limit, starts_at, expires_at, payment_reference) VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? MONTH), ?)")
           ->execute([$userId, $payment['plan_id'], $plan['profile_limit'] ?? 10, $plan['duration_months'] ?? 1, $orderId]);

        $cfPaymentId = $cfResp['cf_payment_id'] ?? null;
        $db->prepare("UPDATE payments SET status='SUCCESS', cf_payment_id=? WHERE cf_order_id=?")->execute([$cfPaymentId, $orderId]);

        sendSuccess(['status' => 'SUCCESS', 'plan' => $plan['label'] ?? ''], 'Payment successful! Subscription activated.');
    }

    if (in_array($cfStatus, ['EXPIRED', 'CANCELLED'])) {
        $db->prepare("UPDATE payments SET status='CANCELLED' WHERE cf_order_id=?")->execute([$orderId]);
        sendSuccess(['status' => 'CANCELLED'], 'Payment was cancelled.');
    }

    sendSuccess(['status' => 'PENDING'], 'Payment is still pending.');
}

// ============================================================
// POST ?action=webhook
// ============================================================
if ($action === 'webhook') {
    $rawBody = file_get_contents('php://input');
    $payload = json_decode($rawBody, true);

    $db        = getDB();
    $secretKey = getSettingVal($db, 'cashfree_secret_key');

    $tsHeader  = $_SERVER['HTTP_X_WEBHOOK_TIMESTAMP'] ?? '';
    $sigHeader = $_SERVER['HTTP_X_WEBHOOK_SIGNATURE']  ?? '';

    if ($tsHeader && $sigHeader && $secretKey) {
        $computed = base64_encode(hash_hmac('sha256', $tsHeader . $rawBody, $secretKey, true));
        if (!hash_equals($computed, $sigHeader)) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid signature']);
            exit();
        }
    }

    $orderId     = $payload['data']['order']['order_id']        ?? '';
    $cfStatus    = strtoupper($payload['data']['order']['order_status'] ?? '');
    $cfPaymentId = $payload['data']['payment']['cf_payment_id'] ?? null;

    if ($orderId === '') { http_response_code(200); echo '{}'; exit(); }

    $pStmt = $db->prepare("SELECT * FROM payments WHERE cf_order_id = ?");
    $pStmt->execute([$orderId]);
    $payment = $pStmt->fetch();
    if (!$payment) { http_response_code(200); echo '{}'; exit(); }

    $db->prepare("UPDATE payments SET webhook_data = ? WHERE cf_order_id = ?")->execute([json_encode($payload), $orderId]);

    if ($cfStatus === 'PAID' && $payment['status'] !== 'SUCCESS') {
        $userId = $payment['user_id'];
        $plan   = $db->prepare("SELECT * FROM upgrade_plans WHERE id = ?");
        $plan->execute([$payment['plan_id']]);
        $plan = $plan->fetch();

        $db->prepare("UPDATE user_subscriptions SET status='expired' WHERE user_id=? AND status='active'")->execute([$userId]);
        $db->prepare("INSERT INTO user_subscriptions (user_id, plan_id, profile_limit, starts_at, expires_at, payment_reference) VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? MONTH), ?)")
           ->execute([$userId, $payment['plan_id'], $plan['profile_limit'] ?? 10, $plan['duration_months'] ?? 1, $orderId]);
        $db->prepare("UPDATE payments SET status='SUCCESS', cf_payment_id=? WHERE cf_order_id=?")->execute([$cfPaymentId, $orderId]);

    } elseif (in_array($cfStatus, ['EXPIRED', 'CANCELLED', 'FAILED'])) {
        $db->prepare("UPDATE payments SET status='FAILED' WHERE cf_order_id=?")->execute([$orderId]);
    }

    http_response_code(200);
    echo json_encode(['status' => 'ok']);
    exit();
}

// ============================================================
// GET ?action=return
// ============================================================
if ($action === 'return') {
    $orderId = htmlspecialchars($_GET['order_id'] ?? '');
    ?>
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Payment Processing - Wedding India</title>
    <style>
      * { margin:0; padding:0; box-sizing:border-box; }
      body { font-family:'Segoe UI',sans-serif; background:linear-gradient(135deg,#E91E63,#AD1457); min-height:100vh; display:flex; align-items:center; justify-content:center; color:#fff; text-align:center; padding:24px; }
      .card { background:rgba(255,255,255,.12); backdrop-filter:blur(10px); border-radius:24px; padding:40px 32px; max-width:380px; width:100%; border:1px solid rgba(255,255,255,.2); }
      .icon { font-size:56px; margin-bottom:16px; }
      h1 { font-size:22px; font-weight:700; margin-bottom:10px; }
      p { font-size:14px; opacity:.85; line-height:1.6; }
      .note { margin-top:20px; background:rgba(255,255,255,.15); border-radius:12px; padding:14px; font-size:13px; }
      .order-id { margin-top:16px; font-size:12px; opacity:.6; word-break:break-all; }
    </style>
    </head>
    <body>
    <div class="card">
      <div class="icon">&#8987;</div>
      <h1>Verifying Payment...</h1>
      <p>Please wait. Do not close the app.</p>
      <p>Your subscription will activate automatically once payment is confirmed.</p>
      <div class="note">App mein wapas jaayein aur "I've Paid" button dabayein.</div>
      <?php if ($orderId): ?><div class="order-id">Order ID: <?= $orderId ?></div><?php endif; ?>
    </div>
    </body>
    </html>
    <?php
    exit();
}

// ============================================================
// GET ?action=history — User ke saare payments
// ============================================================
if ($action === 'history') {
    $userId = getAuthUserId();
    $db = getDB();

    $stmt = $db->prepare("
        SELECT p.id, p.cf_order_id, p.amount, p.currency, p.status,
               p.created_at, p.payment_session_id,
               up.label AS plan_label, up.duration_months
        FROM payments p
        LEFT JOIN upgrade_plans up ON up.id = p.plan_id
        WHERE p.user_id = ?
        ORDER BY p.created_at DESC
        LIMIT 50
    ");
    $stmt->execute([$userId]);
    $rows = $stmt->fetchAll();

    sendSuccess(['payments' => $rows], 'Payment history fetched');
}

sendError(400, 'Invalid action');
