<?php
// GET /api/upgrade.php
require_once __DIR__ . '/config.php';

$db = getDB();
$action = $_GET['action'] ?? 'plans';

if ($action === 'subscribe') {
    $userId = getAuthUserId();
    $input = getInput();
    $planId = (int)($input['plan_id'] ?? 0);
    $paymentReference = trim($input['payment_reference'] ?? '');
    if ($planId <= 0 || $paymentReference === '') {
        sendError(400, 'Plan and successful payment reference are required');
    }

    $stmt = $db->prepare("SELECT id, profile_limit, duration_months FROM upgrade_plans WHERE id = ? AND is_active = 1");
    $stmt->execute([$planId]);
    $plan = $stmt->fetch();
    if (!$plan) sendError(404, 'Plan not found');

    $db->prepare("UPDATE user_subscriptions SET status = 'expired' WHERE user_id = ? AND status = 'active'")
        ->execute([$userId]);
    $stmt = $db->prepare("INSERT INTO user_subscriptions
        (user_id, plan_id, profile_limit, starts_at, expires_at, payment_reference)
        VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? MONTH), ?)");
    $stmt->execute([$userId, $plan['id'], $plan['profile_limit'], $plan['duration_months'], $paymentReference]);
    sendSuccess(['subscription_id' => (int)$db->lastInsertId()], 'Package activated successfully');
}

if ($action === 'status') {
    $userId = getAuthUserId();
    $stmt = $db->prepare("SELECT s.plan_id, s.profile_limit, s.profiles_viewed, s.starts_at, s.expires_at,
        p.label FROM user_subscriptions s JOIN upgrade_plans p ON p.id = s.plan_id
        WHERE s.user_id = ? AND s.status = 'active' AND s.expires_at > NOW()
        ORDER BY s.expires_at DESC LIMIT 1");
    $stmt->execute([$userId]);
    $subscription = $stmt->fetch();

    // Free limit from settings
    $freeLimit = (int)(function() use ($db) {
        $s = $db->prepare("SELECT `value` FROM app_settings WHERE `key` = 'free_profile_limit'");
        $s->execute(); $r = $s->fetch();
        return $r ? (int)$r['value'] : 5;
    })();

    // Count views for non-subscribers
    if (!$subscription) {
        $vStmt = $db->prepare("SELECT COUNT(*) FROM profile_views WHERE viewer_id = ?");
        $vStmt->execute([$userId]);
        $viewed = (int)$vStmt->fetchColumn();
        sendSuccess([
            'plan_id'         => null,
            'profile_limit'   => $freeLimit,
            'profiles_viewed' => $viewed,
            'expires_at'      => null,
            'free_limit'      => $freeLimit,
        ]);
    }

    sendSuccess(array_merge($subscription, ['free_limit' => $freeLimit]));
}

$plans = $db->query("SELECT * FROM upgrade_plans WHERE is_active=1 ORDER BY sort_order")->fetchAll();
$features = $db->query("SELECT * FROM upgrade_features WHERE is_active=1 ORDER BY sort_order")->fetchAll();

sendSuccess([
    'plans'    => $plans,
    'features' => $features,
]);
