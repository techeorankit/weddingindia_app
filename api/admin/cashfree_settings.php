<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Payment Gateway';

$db  = getDB();
$msg = '';
$err = '';

// ── Helper: get a setting value ──────────────────────────────────────────────
function getSetting(PDO $db, string $key, string $default = ''): string {
    $s = $db->prepare("SELECT `value` FROM app_settings WHERE `key` = ?");
    $s->execute([$key]);
    $row = $s->fetch();
    return $row ? (string)$row['value'] : $default;
}

// ── Save settings ────────────────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'save_cashfree') {
    $appId      = trim($_POST['cashfree_app_id']      ?? '');
    $secretKey  = trim($_POST['cashfree_secret_key']  ?? '');
    $environment = in_array($_POST['cashfree_environment'] ?? '', ['sandbox','production'])
                    ? $_POST['cashfree_environment']
                    : 'sandbox';
    $enabled    = isset($_POST['cashfree_enabled']) ? '1' : '0';

    $upsert = $db->prepare("
        INSERT INTO app_settings (`key`, `value`)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)
    ");

    $upsert->execute(['cashfree_app_id',      $appId]);
    $upsert->execute(['cashfree_secret_key',  $secretKey]);
    $upsert->execute(['cashfree_environment', $environment]);
    $upsert->execute(['cashfree_enabled',     $enabled]);

    $msg = 'Payment gateway settings saved successfully!';
}

// ── Load current values ───────────────────────────────────────────────────────
$cfAppId      = getSetting($db, 'cashfree_app_id');
$cfSecretKey  = getSetting($db, 'cashfree_secret_key');
$cfEnv        = getSetting($db, 'cashfree_environment', 'sandbox');
$cfEnabled    = getSetting($db, 'cashfree_enabled', '0');

// ── Recent payments ───────────────────────────────────────────────────────────
$payments = $db->query("
    SELECT p.*, u.phone,
           up.full_name,
           pl.label AS plan_label
    FROM   payments p
    LEFT JOIN users         u  ON u.id  = p.user_id
    LEFT JOIN user_profiles up ON up.user_id = p.user_id
    LEFT JOIN upgrade_plans pl ON pl.id = p.plan_id
    ORDER BY p.created_at DESC
    LIMIT 50
")->fetchAll();

include 'layout.php';
?>

<?php if ($msg): ?><div class="alert alert-success">✅ <?= htmlspecialchars($msg) ?></div><?php endif; ?>
<?php if ($err): ?><div class="alert alert-error">⚠️  <?= htmlspecialchars($err) ?></div><?php endif; ?>

<!-- ── Stats row ─────────────────────────────────────────────────────────── -->
<?php
$stats = $db->query("
    SELECT
        COUNT(*)                                        AS total,
        SUM(status = 'SUCCESS')                         AS success,
        SUM(status = 'PENDING')                         AS pending,
        SUM(status = 'FAILED')                          AS failed,
        COALESCE(SUM(CASE WHEN status='SUCCESS' THEN amount END), 0) AS revenue
    FROM payments
")->fetch();
?>
<div class="stats-grid" style="margin-bottom:24px">
    <div class="stat-card">
        <div class="stat-icon" style="background:#e8f5e9">💰</div>
        <div class="stat-info">
            <h3>₹<?= number_format((float)$stats['revenue'], 2) ?></h3>
            <p>Total Revenue</p>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:#e3f2fd">📦</div>
        <div class="stat-info">
            <h3><?= (int)$stats['total'] ?></h3>
            <p>Total Orders</p>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:#e8f5e9">✅</div>
        <div class="stat-info">
            <h3><?= (int)$stats['success'] ?></h3>
            <p>Successful</p>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:#fff3e0">⏳</div>
        <div class="stat-info">
            <h3><?= (int)$stats['pending'] ?></h3>
            <p>Pending</p>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:#fce4ec">❌</div>
        <div class="stat-info">
            <h3><?= (int)$stats['failed'] ?></h3>
            <p>Failed</p>
        </div>
    </div>
</div>

<!-- ── Settings card ─────────────────────────────────────────────────────── -->
<div style="display:grid;grid-template-columns:1fr 1fr;gap:24px;align-items:start">

<div class="table-card" style="padding:28px">
    <h2 style="font-size:16px;font-weight:700;margin-bottom:6px">🔑 Cashfree API Keys</h2>
    <p style="color:#888;font-size:13px;margin-bottom:22px">
        Keys aapke
        <a href="https://merchant.cashfree.com" target="_blank" style="color:#E91E63">Cashfree Merchant Dashboard</a>
        se milenge → Developers → API Keys.
    </p>

    <form method="POST">
        <input type="hidden" name="action" value="save_cashfree">

        <div class="form-group">
            <label>App ID</label>
            <input type="text" name="cashfree_app_id"
                   value="<?= htmlspecialchars($cfAppId) ?>"
                   placeholder="e.g. 12345678abcdefgh12345678">
        </div>

        <div class="form-group">
            <label>Secret Key</label>
            <input type="password" name="cashfree_secret_key"
                   value="<?= htmlspecialchars($cfSecretKey) ?>"
                   placeholder="Your Cashfree secret key"
                   id="secretKeyInput">
            <label style="display:flex;align-items:center;gap:6px;margin-top:6px;font-weight:normal;cursor:pointer">
                <input type="checkbox" onchange="
                    document.getElementById('secretKeyInput').type =
                    this.checked ? 'text' : 'password'">
                Show key
            </label>
        </div>

        <div class="form-group">
            <label>Environment</label>
            <select name="cashfree_environment">
                <option value="sandbox"    <?= $cfEnv === 'sandbox'    ? 'selected' : '' ?>>
                    🧪 Sandbox (Testing)
                </option>
                <option value="production" <?= $cfEnv === 'production' ? 'selected' : '' ?>>
                    🚀 Production (Live)
                </option>
            </select>
        </div>

        <div class="form-group">
            <label style="display:flex;align-items:center;gap:10px;cursor:pointer">
                <input type="checkbox" name="cashfree_enabled" value="1"
                       <?= $cfEnabled === '1' ? 'checked' : '' ?>>
                <span>Enable Cashfree Payments in App</span>
            </label>
        </div>

        <button type="submit" class="btn btn-primary" style="width:100%;padding:12px">
            💾 Save Settings
        </button>
    </form>

    <div style="margin-top:24px;padding:16px;background:#f8f9fa;border-radius:12px;font-size:13px;color:#555">
        <strong>📌 Webhook URL</strong> — Cashfree dashboard mein yeh URL set karein:<br>
        <code style="display:block;margin-top:8px;padding:8px 12px;background:#fff;border:1px solid #e0e0e0;border-radius:8px;word-break:break-all;font-size:12px">
            https://weddingindiamatrimony.com/api/payment.php?action=webhook
        </code>
        <br>
        <strong>📌 Return URL</strong> (for redirect flow):<br>
        <code style="display:block;margin-top:8px;padding:8px 12px;background:#fff;border:1px solid #e0e0e0;border-radius:8px;word-break:break-all;font-size:12px">
            https://weddingindiamatrimony.com/api/payment.php?action=return
        </code>
    </div>
</div>

<!-- ── How to get keys ───────────────────────────────────────────────────── -->
<div class="table-card" style="padding:28px">
    <h2 style="font-size:16px;font-weight:700;margin-bottom:16px">📖 Setup Guide</h2>
    <ol style="padding-left:20px;line-height:2;font-size:14px;color:#444">
        <li>
            <a href="https://merchant.cashfree.com/register" target="_blank" style="color:#E91E63">
                Cashfree Merchant Account
            </a> banayein (free hai)
        </li>
        <li>Dashboard → <strong>Developers → API Keys</strong> pe jaayein</li>
        <li>
            <strong>Sandbox</strong> keys copy karein testing ke liye,<br>
            <strong>Production</strong> keys live jaane pe use karein
        </li>
        <li>Upar wale form mein paste karein aur Save karein</li>
        <li>
            Webhook URL apne Cashfree dashboard mein set karein<br>
            (Developers → Webhooks)
        </li>
        <li>App se ek test payment karein ✅</li>
    </ol>

    <div style="margin-top:20px;padding:14px;background:#fff3e0;border-radius:10px;border-left:4px solid #FF9800;font-size:13px">
        <strong>⚠️ Important:</strong> Production mein jaane se pehle Cashfree ka
        KYC process complete karein. Iske bina settlements nahi honge.
    </div>

    <div style="margin-top:14px;padding:14px;background:#e8f5e9;border-radius:10px;border-left:4px solid #4CAF50;font-size:13px">
        <strong>✅ Sandbox Test Cards:</strong><br>
        Card: <code>4111 1111 1111 1111</code><br>
        Expiry: Any future date &nbsp;|&nbsp; CVV: Any 3 digits<br>
        UPI: <code>success@upi</code> (success) / <code>failure@upi</code> (failure)
    </div>
</div>

</div>

<!-- ── Recent Transactions ───────────────────────────────────────────────── -->
<div class="table-card" style="margin-top:28px">
    <div class="table-header">
        <h2>Recent Transactions</h2>
        <span style="font-size:13px;color:#888">Last 50 orders</span>
    </div>
    <table>
        <thead>
            <tr>
                <th>#</th>
                <th>User</th>
                <th>Plan</th>
                <th>Amount</th>
                <th>CF Order ID</th>
                <th>CF Payment ID</th>
                <th>Status</th>
                <th>Date</th>
            </tr>
        </thead>
        <tbody>
        <?php if (empty($payments)): ?>
            <tr><td colspan="8" style="text-align:center;color:#888;padding:32px">
                No transactions yet
            </td></tr>
        <?php else: ?>
            <?php foreach ($payments as $p): ?>
            <tr>
                <td><?= (int)$p['id'] ?></td>
                <td>
                    <div style="font-weight:600"><?= htmlspecialchars($p['full_name'] ?? 'N/A') ?></div>
                    <div style="font-size:12px;color:#888"><?= htmlspecialchars($p['phone'] ?? '') ?></div>
                </td>
                <td><?= htmlspecialchars($p['plan_label'] ?? 'N/A') ?></td>
                <td style="font-weight:700">₹<?= number_format((float)$p['amount'], 2) ?></td>
                <td><code style="font-size:12px"><?= htmlspecialchars($p['cf_order_id']) ?></code></td>
                <td>
                    <?php if ($p['cf_payment_id']): ?>
                        <code style="font-size:12px"><?= htmlspecialchars($p['cf_payment_id']) ?></code>
                    <?php else: ?>
                        <span style="color:#bbb">—</span>
                    <?php endif; ?>
                </td>
                <td>
                    <?php
                    $badgeClass = match($p['status']) {
                        'SUCCESS'   => 'badge-green',
                        'PENDING'   => 'badge-orange',
                        'FAILED'    => 'badge-red',
                        'CANCELLED' => 'badge-red',
                        default     => 'badge-blue',
                    };
                    ?>
                    <span class="badge <?= $badgeClass ?>"><?= htmlspecialchars($p['status']) ?></span>
                </td>
                <td style="font-size:12px;color:#888"><?= date('d M Y, h:i A', strtotime($p['created_at'])) ?></td>
            </tr>
            <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
</div>

<?php include 'layout_end.php'; ?>
