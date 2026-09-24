<?php
// POST /api/interactions.php
// Body: { "to_user_id": 101, "type": "interest" }
// type: interest | shortlist | ignore | chat

require_once __DIR__ . '/config.php';

$fromUserId = getAuthUserId();
$input      = getInput();
$toUserId   = (int)($input['to_user_id'] ?? 0);
$type       = trim($input['type'] ?? '');

$allowed = ['interest', 'shortlist', 'ignore', 'chat'];
if ($toUserId <= 0)              sendError(400, 'to_user_id required');
if (!in_array($type, $allowed)) sendError(400, 'Invalid type');
if ($fromUserId === $toUserId)   sendError(400, 'Cannot interact with yourself');

$db = getDB();

$stmt = $db->prepare("SELECT id FROM user_subscriptions
    WHERE user_id = ? AND status = 'active' AND expires_at > NOW()
    LIMIT 1");
$stmt->execute([$fromUserId]);
if (!$stmt->fetch()) {
    sendError(402, 'Please buy a package to interact with profiles.');
}

// Toggle: agar already hai toh remove, warna add
$stmt = $db->prepare("SELECT id FROM user_interactions WHERE from_user_id=? AND to_user_id=? AND type=?");
$stmt->execute([$fromUserId, $toUserId, $type]);
$existing = $stmt->fetch();

if ($existing) {
    $db->prepare("DELETE FROM user_interactions WHERE id=?")->execute([$existing['id']]);
    sendSuccess(['active' => false], ucfirst($type) . ' removed');
} else {
    $db->prepare("INSERT INTO user_interactions (from_user_id, to_user_id, type) VALUES (?,?,?)
                  ON DUPLICATE KEY UPDATE updated_at=NOW()")
       ->execute([$fromUserId, $toUserId, $type]);
    sendSuccess(['active' => true], ucfirst($type) . ' saved');
}
