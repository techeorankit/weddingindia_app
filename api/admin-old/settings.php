<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Settings';

$msg = '';
$error = '';
$db = getDB();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $action = $_POST['action'] ?? '';
  if ($action === 'change_password') {
        $admin = currentAdmin();
        // Verify current password from DB
        $row = $db->prepare("SELECT password FROM admins WHERE id=?");
        $row->execute([$admin['id']]);
        $row = $row->fetch();

        if (!$row || !password_verify($_POST['current'], $row['password'])) {
            $error = 'Current password is incorrect';
        } elseif (strlen($_POST['new_pass']) < 6) {
            $error = 'New password must be at least 6 characters';
        } elseif ($_POST['new_pass'] !== $_POST['confirm_pass']) {
            $error = 'Passwords do not match';
        } else {
            $hashed = password_hash($_POST['new_pass'], PASSWORD_BCRYPT);
            $db->prepare("UPDATE admins SET password=? WHERE id=?")->execute([$hashed, $admin['id']]);
            $msg = 'Password updated successfully! Please login again.';
            session_destroy();
            header('refresh:2;url=index.php');
        }
        } elseif ($action === 'update_app_content') {
          $contentKey = trim($_POST['content_key'] ?? '');
          $title = trim($_POST['title'] ?? '');
          $body = trim($_POST['body'] ?? '');
          $isActive = isset($_POST['is_active']) ? 1 : 0;

          if ($contentKey === '' || $title === '' || $body === '') {
            $error = 'Content key, title and content are required';
          } else {
            $stmt = $db->prepare("UPDATE app_content
              SET title = ?, body = ?, is_active = ?
              WHERE content_key = ?");
            $stmt->execute([$title, $body, $isActive, $contentKey]);
            $msg = 'App content updated successfully';
          }
    }
}

      $appContent = $db->query("SELECT id, content_key, title, body, sort_order, is_active
        FROM app_content ORDER BY sort_order ASC, id ASC")->fetchAll();

include 'layout.php';
?>

<?php if ($msg): ?><div class="alert alert-success">✅ <?= $msg ?></div><?php endif; ?>
<?php if ($error): ?><div class="alert alert-error">⚠️ <?= $error ?></div><?php endif; ?>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;max-width:800px">

  <div class="table-card" style="padding:24px">
    <h2 style="font-size:16px;font-weight:700;margin-bottom:20px">Change Admin Password</h2>
    <form method="POST">
      <input type="hidden" name="action" value="change_password">
      <div class="form-group">
        <label>Current Password</label>
        <input type="password" name="current" required>
      </div>
      <div class="form-group">
        <label>New Password</label>
        <input type="password" name="new_pass" required minlength="6">
      </div>
      <div class="form-group">
        <label>Confirm New Password</label>
        <input type="password" name="confirm_pass" required>
      </div>
      <button type="submit" class="btn btn-primary" style="width:100%">Update Password</button>
    </form>
  </div>

  <div class="table-card" style="padding:24px">
    <h2 style="font-size:16px;font-weight:700;margin-bottom:20px">Admin Info</h2>
    <div style="display:flex;flex-direction:column;gap:12px">
      <div style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid #f5f5f5">
        <span style="color:#888;font-size:13px">Username</span>
        <span style="font-weight:600"><?= htmlspecialchars(currentAdmin()['username']) ?></span>
      </div>
      <div style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid #f5f5f5">
        <span style="color:#888;font-size:13px">Name</span>
        <span style="font-weight:600"><?= htmlspecialchars(currentAdmin()['name']) ?></span>
      </div>
      <div style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid #f5f5f5">
        <span style="color:#888;font-size:13px">Panel Version</span>
        <span style="font-weight:600">1.0.0</span>
      </div>
      <div style="display:flex;justify-content:space-between;padding:10px 0">
        <span style="color:#888;font-size:13px">App Name</span>
        <span style="font-weight:600">Wedding India</span>
      </div>
    </div>
  </div>

</div>

<div class="table-card" style="padding:24px;max-width:900px;margin-top:24px">
  <h2 style="font-size:16px;font-weight:700;margin-bottom:8px">App Content</h2>
  <p style="color:#888;font-size:13px;margin-bottom:20px">
    Privacy Policy, Terms &amp; Conditions, About Us and Help Line ka content yahan se update karein.
  </p>

  <?php if (empty($appContent)): ?>
    <div style="padding:20px 0;color:#888">No app content found. Please run <code>api/app_content.sql</code> first.</div>
  <?php else: ?>
    <?php foreach ($appContent as $content): ?>
      <form method="POST" style="padding:20px 0;border-top:1px solid #f0f0f0">
        <input type="hidden" name="action" value="update_app_content">
        <input type="hidden" name="content_key" value="<?= htmlspecialchars($content['content_key']) ?>">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;gap:12px;flex-wrap:wrap">
          <h3 style="font-size:15px;font-weight:700"><?= htmlspecialchars($content['content_key']) ?></h3>
          <label style="display:flex;align-items:center;gap:8px;font-size:13px;color:#555">
            <input type="checkbox" name="is_active" value="1" <?= $content['is_active'] ? 'checked' : '' ?>>
            Visible in app
          </label>
        </div>
        <div class="form-group">
          <label>Title</label>
          <input type="text" name="title" value="<?= htmlspecialchars($content['title']) ?>" required>
        </div>
        <div class="form-group">
          <label>Content</label>
          <textarea name="body" rows="7" required><?= htmlspecialchars($content['body']) ?></textarea>
        </div>
        <button type="submit" class="btn btn-primary">Update Content</button>
      </form>
    <?php endforeach; ?>
  <?php endif; ?>
</div>

<?php include 'layout_end.php'; ?>
