<?php
// settings_api.php - Public app settings API
// GET - Returns contact info, whatsapp, app settings for the app

require_once __DIR__ . '/config.php';

$db = getDB();
$keys = ['contact_phone', 'contact_whatsapp', 'contact_email', 'whatsapp_message',
         'app_name', 'chatbot_enabled', 'ads_enabled', 'ads_interval',
         'free_profile_limit', 'agora_app_id'];

$placeholders = implode(',', array_fill(0, count($keys), '?'));
$stmt = $db->prepare("SELECT `key`, `value` FROM app_settings WHERE `key` IN ($placeholders)");
$stmt->execute($keys);

$settings = [];
foreach ($stmt->fetchAll() as $row) {
    $settings[$row['key']] = $row['value'];
}

// Defaults if not set
$defaults = [
    'contact_phone'      => '+91 9999999999',
    'contact_whatsapp'   => '919999999999',
    'contact_email'      => 'support@weddingindiamatrimony.com',
    'whatsapp_message'   => 'Hello, I need help with Wedding India Matrimony app.',
    'app_name'           => 'Wedding India Matrimony',
    'chatbot_enabled'    => '1',
    'ads_enabled'        => '1',
    'ads_interval'       => '4',
    'free_profile_limit' => '5',
    'agora_app_id'       => '',
];

foreach ($defaults as $k => $v) {
    if (!isset($settings[$k])) $settings[$k] = $v;
}

sendSuccess($settings);
