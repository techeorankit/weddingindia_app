<?php
// call_token.php - Generate Agora RTC Token for voice/video calls
// POST { channel_name, uid }
// Returns: { token, channel_name, uid, app_id }
//
// NOTE: For production, use Agora's official token builder.
// For development/no-auth mode, App ID only is enough.
// This endpoint returns App ID + channel so app can join.

require_once __DIR__ . '/config.php';

$userId = getAuthUserId();
$input  = getInput();

$channelName = trim($input['channel_name'] ?? '');
$uid         = (int)($input['uid'] ?? $userId);

if ($channelName === '') sendError(400, 'channel_name required');

$db    = getDB();
$appId = getSettingVal($db, 'agora_app_id', '');

if ($appId === '') {
    sendError(503, 'Video/Voice calling is not configured. Contact admin.');
}

// Helper
function getSettingVal(PDO $db, $key, $default = '') {
    $s = $db->prepare("SELECT `value` FROM app_settings WHERE `key` = ?");
    $s->execute([$key]);
    $row = $s->fetch();
    return $row ? (string)$row['value'] : $default;
}

// For no-auth mode (App Certificate empty), token is null — App ID enough
// For production with App Certificate, generate proper token here
// We return null token — Agora SDK will use App ID only (testing mode)
sendSuccess([
    'app_id'       => $appId,
    'channel_name' => $channelName,
    'uid'          => $uid,
    'token'        => null, // Set up App Certificate + token server for production
]);
