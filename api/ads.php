<?php
// ads.php - Advertisement API
// GET ?action=list        - Active ads for app (public)
// POST ?action=click      - Track click { ad_id }
// POST ?action=impression - Track impression { ad_id }

require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? 'list';

// ── GET active ads ──────────────────────────────────────────────────────────
if ($action === 'list') {
    $db = getDB();

    // Check if ads enabled in app_settings
    $s = $db->prepare("SELECT `value` FROM app_settings WHERE `key` = 'ads_enabled'");
    $s->execute();
    $enabled = $s->fetchColumn();
    // If key missing or explicitly '0', return empty
    if ($enabled === '0') {
        sendSuccess(['ads' => [], 'interval' => 4]);
    }

    // Get interval
    $s2 = $db->prepare("SELECT `value` FROM app_settings WHERE `key` = 'ads_interval'");
    $s2->execute();
    $interval = (int)($s2->fetchColumn() ?: 4);

    // Fetch active ads — no date filter (dates are optional in admin)
    $stmt = $db->prepare("
        SELECT id, title, description, media_type, media_url, click_url, advertiser
        FROM advertisements
        WHERE is_active = 1
        ORDER BY RAND()
        LIMIT 10
    ");
    $stmt->execute();
    $ads = $stmt->fetchAll();

    sendSuccess(['ads' => $ads, 'interval' => $interval]);
}

// ── Track impression ────────────────────────────────────────────────────────
if ($action === 'impression') {
    $input = getInput();
    $adId  = (int)($input['ad_id'] ?? 0);
    if ($adId > 0) {
        getDB()->prepare("UPDATE advertisements SET impressions = impressions + 1 WHERE id = ?")
               ->execute([$adId]);
    }
    sendSuccess([], 'ok');
}

// ── Track click ─────────────────────────────────────────────────────────────
if ($action === 'click') {
    $input = getInput();
    $adId  = (int)($input['ad_id'] ?? 0);
    if ($adId > 0) {
        getDB()->prepare("UPDATE advertisements SET clicks = clicks + 1 WHERE id = ?")
               ->execute([$adId]);
    }
    sendSuccess([], 'ok');
}

sendError(400, 'Invalid action');
