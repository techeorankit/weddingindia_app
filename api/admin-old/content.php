<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'App Content';
$msg = '';
$error = '';

$contentDefinitions = [
    'privacy' => 'Privacy Policy',
    'terms' => 'Terms & Conditions',
    'about' => 'About Us',
    'help' => 'Help Line',
];

$db = getDB();
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $key = $_POST['content_key'] ?? '';
    if (!isset($contentDefinitions[$key])) {
        $error = 'Invalid content page';
    } else {
        $title = trim($_POST['title'] ?? $contentDefinitions[$key]);
        $body = trim($_POST['body'] ?? '');
        if ($title === '' || $body === '') {
            $error = 'Title and content are required';
        } else {
            $stmt = $db->prepare("INSERT INTO app_content (content_key, title, body, sort_order, is_active)
                VALUES (?, ?, ?, ?, 1)
                ON DUPLICATE KEY UPDATE title = VALUES(title), body = VALUES(body), is_active = 1");
            $stmt->execute([$key, $title, $body, array_search($key, array_keys($contentDefinitions), true)]);
            $msg = $contentDefinitions[$key] . ' updated successfully';
        }
    }
}

$rows = $db->query("SELECT content_key, title, body FROM app_content")->fetchAll();
$savedContent = [];
foreach ($rows as $row) {
    $savedContent[$row['content_key']] = $row;
}

include 'layout.php';
?>

<?php if ($msg): ?><div class="alert alert-success"><?= htmlspecialchars($msg) ?></div><?php endif; ?>
<?php if ($error): ?><div class="alert alert-error"><?= htmlspecialchars($error) ?></div><?php endif; ?>

<div style="display:grid;gap:20px;max-width:900px">
<?php foreach ($contentDefinitions as $key => $label):
    $row = $savedContent[$key] ?? ['title' => $label, 'body' => ''];
?>
  <div class="table-card" style="padding:24px">
    <h2 style="font-size:16px;font-weight:700;margin-bottom:16px"><?= htmlspecialchars($label) ?></h2>
    <form method="POST">
      <input type="hidden" name="content_key" value="<?= htmlspecialchars($key) ?>">
      <div class="form-group">
        <label>Title</label>
        <input type="text" name="title" value="<?= htmlspecialchars($row['title']) ?>" required>
      </div>
      <div class="form-group">
        <label>Content</label>
        <textarea name="body" rows="6" required><?= htmlspecialchars($row['body']) ?></textarea>
      </div>
      <button type="submit" class="btn btn-primary">Save <?= htmlspecialchars($label) ?></button>
    </form>
  </div>
<?php endforeach; ?>
</div>

<?php include 'layout_end.php'; ?>