<?php
// GET /api/content.php - Public app content managed from the admin panel
require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError(405, 'Method not allowed');
}

$db = getDB();
$stmt = $db->query("SELECT content_key, title, body FROM app_content WHERE is_active = 1 ORDER BY sort_order ASC");
$content = [];

foreach ($stmt->fetchAll() as $row) {
    $content[$row['content_key']] = [
        'title' => $row['title'],
        'body' => $row['body'],
    ];
}

sendSuccess($content);