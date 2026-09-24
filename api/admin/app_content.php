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
            $msg = '✅ App content updated successfully!';
        }
    }
}

$appContent = $db->query("SELECT id, content_key, title, body, sort_order, is_active
    FROM app_content ORDER BY sort_order ASC, id ASC")->fetchAll();

include 'layout.php';
?>

<style>
/* ============================================
   IMPROVED UI STYLES
============================================ */

/* Alert Messages */
.alert {
    padding: 16px 20px;
    border-radius: 10px;
    margin-bottom: 24px;
    font-weight: 500;
    font-size: 14px;
    display: flex;
    align-items: center;
    gap: 10px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.04);
    animation: slideDown 0.3s ease;
}

@keyframes slideDown {
    from { opacity: 0; transform: translateY(-12px); }
    to { opacity: 1; transform: translateY(0); }
}

.alert-success {
    background: #e8f8ef;
    color: #0a6b3c;
    border-left: 4px solid #0a6b3c;
}

.alert-error {
    background: #fde8e8;
    color: #a11f1f;
    border-left: 4px solid #a11f1f;
}

/* Responsive Grid */
.settings-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
    max-width: 920px;
    margin-bottom: 32px;
}

@media (max-width: 768px) {
    .settings-grid {
        grid-template-columns: 1fr;
        gap: 20px;
    }
}

/* Cards */
.card {
    background: #ffffff;
    border-radius: 16px;
    padding: 28px 24px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.06), 0 1px 3px rgba(0,0,0,0.04);
    transition: box-shadow 0.25s ease, transform 0.2s ease;
    border: 1px solid #f0f2f5;
}

.card:hover {
    box-shadow: 0 8px 32px rgba(0,0,0,0.08);
}

.card-title {
    font-size: 17px;
    font-weight: 700;
    color: #1a1a2e;
    margin-bottom: 6px;
    display: flex;
    align-items: center;
    gap: 10px;
}

.card-title .icon {
    font-size: 20px;
}

.card-sub {
    font-size: 13px;
    color: #8c8fa7;
    margin-bottom: 22px;
}

/* Forms */
.form-group {
    margin-bottom: 18px;
}

.form-group label {
    display: block;
    font-size: 13px;
    font-weight: 600;
    color: #2d2d44;
    margin-bottom: 6px;
    letter-spacing: 0.3px;
}

.form-group input,
.form-group textarea {
    width: 100%;
    padding: 11px 14px;
    font-size: 14px;
    border: 1.5px solid #e2e5ed;
    border-radius: 10px;
    background: #fafbfc;
    transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
    font-family: inherit;
    color: #1a1a2e;
    box-sizing: border-box;
}

.form-group input:focus,
.form-group textarea:focus {
    outline: none;
    border-color: #6c5ce7;
    background: #ffffff;
    box-shadow: 0 0 0 4px rgba(108, 92, 231, 0.10);
}

.form-group textarea {
    resize: vertical;
    min-height: 120px;
    line-height: 1.6;
}

/* Buttons */
.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 11px 24px;
    font-size: 14px;
    font-weight: 600;
    border: none;
    border-radius: 10px;
    cursor: pointer;
    transition: all 0.25s ease;
    text-decoration: none;
    background: #6c5ce7;
    color: #fff;
    width: 100%;
    letter-spacing: 0.3px;
}

.btn:hover {
    background: #5a4bd1;
    transform: translateY(-1px);
    box-shadow: 0 6px 20px rgba(108, 92, 231, 0.30);
}

.btn:active {
    transform: translateY(0);
    box-shadow: none;
}

.btn-secondary {
    background: #eef0f5;
    color: #2d2d44;
}

.btn-secondary:hover {
    background: #e2e5ed;
    box-shadow: 0 4px 12px rgba(0,0,0,0.06);
}

/* Admin Info List */
.info-list {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.info-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 0;
    border-bottom: 1px solid #f0f2f5;
}

.info-item:last-child {
    border-bottom: none;
}

.info-label {
    color: #8c8fa7;
    font-size: 13px;
    font-weight: 500;
}

.info-value {
    font-weight: 600;
    color: #1a1a2e;
    font-size: 14px;
}

/* App Content Section */
.content-section {
    max-width: 920px;
    margin-top: 8px;
}

.content-block {
    background: #ffffff;
    border-radius: 16px;
    padding: 24px 24px 28px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.06);
    border: 1px solid #f0f2f5;
    margin-bottom: 24px;
    transition: box-shadow 0.25s ease;
}

.content-block:hover {
    box-shadow: 0 8px 32px rgba(0,0,0,0.08);
}

.content-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
    margin-bottom: 18px;
    padding-bottom: 14px;
    border-bottom: 2px solid #f4f5f9;
}

.content-key {
    font-size: 16px;
    font-weight: 700;
    color: #1a1a2e;
    background: #f4f5f9;
    padding: 4px 14px;
    border-radius: 20px;
    font-family: 'Courier New', monospace;
    letter-spacing: 0.3px;
}

.toggle-wrap {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 13px;
    font-weight: 500;
    color: #4a4a6a;
    cursor: pointer;
    user-select: none;
}

.toggle-wrap input[type="checkbox"] {
    width: 18px;
    height: 18px;
    accent-color: #6c5ce7;
    cursor: pointer;
}

/* Empty State */
.empty-state {
    padding: 40px 20px;
    text-align: center;
    color: #8c8fa7;
    background: #fafbfc;
    border-radius: 12px;
    border: 2px dashed #e2e5ed;
}

.empty-state code {
    background: #eef0f5;
    padding: 4px 12px;
    border-radius: 6px;
    font-size: 13px;
    color: #2d2d44;
}

/* Responsive fine-tune */
@media (max-width: 480px) {
    .card, .content-block {
        padding: 18px 16px;
    }
    .content-header {
        flex-direction: column;
        align-items: flex-start;
    }
    .btn {
        font-size: 13px;
        padding: 10px 16px;
    }
}
</style>

<!-- ========================================== -->
<!-- MESSAGES -->
<!-- ========================================== -->

<?php if ($msg): ?>
    <div class="alert alert-success">✅ <?= htmlspecialchars($msg) ?></div>
<?php endif; ?>

<?php if ($error): ?>
    <div class="alert alert-error">⚠️ <?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<!-- ========================================== -->
<!-- SETTINGS GRID : Password + Admin Info -->
<!-- ========================================== -->

<div class="settings-grid">

    <!-- Change Password Card -->
    <div class="card">
        <div class="card-title">
            <span class="icon">🔐</span> Change Password
        </div>
        <div class="card-sub">Update your admin account password</div>

        <form method="POST">
            <input type="hidden" name="action" value="change_password">

            <div class="form-group">
                <label>Current Password</label>
                <input type="password" name="current" placeholder="Enter current password" required>
            </div>

            <div class="form-group">
                <label>New Password</label>
                <input type="password" name="new_pass" placeholder="Min 6 characters" required minlength="6">
            </div>

            <div class="form-group">
                <label>Confirm New Password</label>
                <input type="password" name="confirm_pass" placeholder="Re-enter new password" required>
            </div>

            <button type="submit" class="btn">🔄 Update Password</button>
        </form>
    </div>

    <!-- Admin Info Card -->
    <div class="card">
        <div class="card-title">
            <span class="icon">👤</span> Admin Info
        </div>
        <div class="card-sub">Your account details &amp; system info</div>

        <div class="info-list">
            <div class="info-item">
                <span class="info-label">Username</span>
                <span class="info-value"><?= htmlspecialchars(currentAdmin()['username']) ?></span>
            </div>
            <div class="info-item">
                <span class="info-label">Name</span>
                <span class="info-value"><?= htmlspecialchars(currentAdmin()['name']) ?></span>
            </div>
            <div class="info-item">
                <span class="info-label">Panel Version</span>
                <span class="info-value">1.0.0</span>
            </div>
            <div class="info-item">
                <span class="info-label">App Name</span>
                <span class="info-value">💍 Wedding India</span>
            </div>
        </div>
    </div>

</div>

<!-- ========================================== -->
<!-- APP CONTENT SECTION -->
<!-- ========================================== -->

<div class="content-section">
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:20px;flex-wrap:wrap;">
        <h2 style="font-size:18px;font-weight:700;color:#1a1a2e;margin:0;">📄 App Content Manager</h2>
        <span style="font-size:13px;color:#8c8fa7;background:#f4f5f9;padding:4px 14px;border-radius:20px;">
            Privacy Policy · Terms · About Us · Help
        </span>
    </div>
    <p style="color:#6c6f8a;font-size:14px;margin-bottom:24px;max-width:700px;">
        Update content for Privacy Policy, Terms &amp; Conditions, About Us and Help Line pages.
        Toggle visibility to show/hide in the app.
    </p>

    <?php if (empty($appContent)): ?>
        <div class="empty-state">
            <div style="font-size:40px;margin-bottom:12px;">📂</div>
            <p style="font-size:15px;margin-bottom:6px;">No app content found.</p>
            <p style="font-size:13px;">Please run <code>api/app_content.sql</code> to set up the content tables.</p>
        </div>
    <?php else: ?>
        <?php foreach ($appContent as $content): ?>
            <div class="content-block">
                <form method="POST">
                    <input type="hidden" name="action" value="update_app_content">
                    <input type="hidden" name="content_key" value="<?= htmlspecialchars($content['content_key']) ?>">

                    <div class="content-header">
                        <span class="content-key"><?= htmlspecialchars($content['content_key']) ?></span>
                        <label class="toggle-wrap">
                            <input type="checkbox" name="is_active" value="1" <?= $content['is_active'] ? 'checked' : '' ?>>
                            <span>Visible in app</span>
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

                    <button type="submit" class="btn" style="width:auto;padding:10px 28px;">💾 Update Content</button>
                </form>
            </div>
        <?php endforeach; ?>
    <?php endif; ?>
</div>

<?php include 'layout_end.php'; ?>