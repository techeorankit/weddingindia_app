<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'App Settings';
$db = getDB();

// Ensure all keys exist
$defaults = [
    'contact_phone'      => '+91 9999999999',
    'contact_whatsapp'   => '919999999999',
    'contact_email'      => 'support@weddingindiamatrimony.com',
    'whatsapp_message'   => 'Hello, I need help with Wedding India Matrimony app.',
    'app_name'           => 'Wedding India Matrimony',
    'chatbot_enabled'    => '1',
    'ads_enabled'        => '1',
    'ads_interval'       => '4',
    'ads_max_per_session' => '0',
    'free_profile_limit' => '5',
    'agora_app_id'       => '',
];
foreach ($defaults as $k => $v) {
    $db->prepare("INSERT IGNORE INTO app_settings (`key`,`value`) VALUES (?,?)")->execute([$k,$v]);
}

$msg = '';
$msgType = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fields = ['contact_phone','contact_whatsapp','contact_email','whatsapp_message',
               'app_name','chatbot_enabled','ads_enabled','ads_interval',
               'ads_max_per_session','free_profile_limit','agora_app_id'];
    foreach ($fields as $field) {
        $val = trim($_POST[$field] ?? '');
        // checkboxes
        if (in_array($field, ['chatbot_enabled','ads_enabled'])) {
            $val = isset($_POST[$field]) ? '1' : '0';
        }
        $db->prepare("INSERT INTO app_settings (`key`,`value`) VALUES (?,?) ON DUPLICATE KEY UPDATE `value`=?")
           ->execute([$field, $val, $val]);
    }
    $msg = '✅ Settings saved successfully!';
    $msgType = 'success';
}

// Fetch current settings
$rows = $db->query("SELECT `key`,`value` FROM app_settings WHERE `key` IN (
    'contact_phone','contact_whatsapp','contact_email','whatsapp_message',
    'app_name','chatbot_enabled','ads_enabled','ads_interval'
)")->fetchAll(PDO::FETCH_KEY_PAIR);
$settings = array_merge($defaults, $rows);

include 'layout.php';
?>

<style>
.settings-section{background:#fff;border-radius:16px;box-shadow:0 2px 10px rgba(0,0,0,.06);margin-bottom:20px;overflow:hidden;border:1px solid #eef0f5}
.settings-section-header{padding:16px 22px;border-bottom:1px solid #eef0f5;display:flex;align-items:center;gap:10px}
.settings-section-header h3{font-size:15px;font-weight:700;color:#1a1a2e;margin:0}
.settings-body{padding:22px}
.setting-row{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px}
.toggle-row{display:flex;align-items:center;justify-content:space-between;padding:12px 0;border-bottom:1px solid #f5f5f5}
.toggle-row:last-child{border-bottom:none}
.toggle-label{font-size:14px;font-weight:600;color:#1a1a2e}
.toggle-desc{font-size:12px;color:#888;margin-top:2px}
.toggle-switch{position:relative;width:48px;height:26px;cursor:pointer}
.toggle-switch input{opacity:0;width:0;height:0}
.toggle-slider{position:absolute;inset:0;background:#ccc;border-radius:26px;transition:.3s}
.toggle-slider:before{content:'';position:absolute;width:20px;height:20px;left:3px;bottom:3px;background:#fff;border-radius:50%;transition:.3s}
.toggle-switch input:checked+.toggle-slider{background:#E91E63}
.toggle-switch input:checked+.toggle-slider:before{transform:translateX(22px)}
@media(max-width:600px){.setting-row{grid-template-columns:1fr}}
</style>

<?php if ($msg): ?>
<div class="alert alert-<?= $msgType === 'success' ? 'success' : 'error' ?>"><?= htmlspecialchars($msg) ?></div>
<?php endif; ?>

<form method="POST">

<!-- Contact Settings -->
<div class="settings-section">
  <div class="settings-section-header">
    <span style="font-size:20px">📞</span>
    <h3>Contact & Support</h3>
  </div>
  <div class="settings-body">
    <div class="setting-row">
      <div class="form-group">
        <label>Customer Care Phone Number</label>
        <input type="text" name="contact_phone" value="<?= htmlspecialchars($settings['contact_phone']) ?>"
          placeholder="+91 9999999999">
        <small style="color:#888;font-size:11px">Shown in Help & Support section</small>
      </div>
      <div class="form-group">
        <label>Support Email</label>
        <input type="email" name="contact_email" value="<?= htmlspecialchars($settings['contact_email']) ?>"
          placeholder="support@example.com">
      </div>
    </div>
    <div class="setting-row">
      <div class="form-group">
        <label>WhatsApp Number (with country code, no +)</label>
        <input type="text" name="contact_whatsapp" value="<?= htmlspecialchars($settings['contact_whatsapp']) ?>"
          placeholder="919999999999">
        <small style="color:#888;font-size:11px">Used for WhatsApp chat button</small>
      </div>
      <div class="form-group">
        <label>WhatsApp Default Message</label>
        <input type="text" name="whatsapp_message" value="<?= htmlspecialchars($settings['whatsapp_message']) ?>"
          placeholder="Hello, I need help...">
      </div>
    </div>
  </div>
</div>

<!-- App Settings -->
<div class="settings-section">
  <div class="settings-section-header">
    <span style="font-size:20px">⚙️</span>
    <h3>General App Settings</h3>
  </div>
  <div class="settings-body">
    <div class="form-group" style="margin-bottom:20px">
      <label>App Name</label>
      <input type="text" name="app_name" value="<?= htmlspecialchars($settings['app_name']) ?>"
        placeholder="Wedding India Matrimony" style="max-width:400px">
    </div>

    <div class="toggle-row">
      <div>
        <div class="toggle-label">🤖 Chatbot / WhatsApp Help Button</div>
        <div class="toggle-desc">Show floating WhatsApp chat button in the app</div>
      </div>
      <label class="toggle-switch">
        <input type="checkbox" name="chatbot_enabled" value="1" <?= $settings['chatbot_enabled'] === '1' ? 'checked' : '' ?>>
        <span class="toggle-slider"></span>
      </label>
    </div>

    <div class="toggle-row">
      <div>
        <div class="toggle-label">📢 Advertisements</div>
        <div class="toggle-desc">Show ads between profiles in matches list</div>
      </div>
      <label class="toggle-switch">
        <input type="checkbox" name="ads_enabled" value="1" <?= $settings['ads_enabled'] === '1' ? 'checked' : '' ?>>
        <span class="toggle-slider"></span>
      </label>
    </div>

    <div style="margin-top:16px">
      <label>Show Ad After Every N Profiles</label>
      <input type="number" name="ads_interval" min="1" max="20"
        value="<?= htmlspecialchars($settings['ads_interval']) ?>"
        style="width:80px;padding:8px 12px;border:1.5px solid #e0e0e0;border-radius:8px;font-size:14px;margin-top:6px">
      <small style="color:#888;font-size:12px;margin-left:8px">profiles</small>
    </div>
  </div>
</div>

<!-- Free Profile Limit -->
<div class="settings-section">
  <div class="settings-section-header">
    <span style="font-size:20px">👁️</span>
    <h3>Free Profile View Limit</h3>
  </div>
  <div class="settings-body">
    <div style="display:flex;align-items:center;gap:16px;flex-wrap:wrap">
      <div>
        <label style="display:block;font-size:13px;font-weight:600;color:#444;margin-bottom:6px">
          Free profiles before premium required
        </label>
        <div style="display:flex;align-items:center;gap:10px">
          <input type="number" name="free_profile_limit" min="1" max="100"
            value="<?= htmlspecialchars($settings['free_profile_limit'] ?? '5') ?>"
            style="width:80px;padding:8px 12px;border:1.5px solid #e0e0e0;border-radius:8px;font-size:14px">
          <small style="color:#888;font-size:13px">profiles free, then upgrade prompt</small>
        </div>
      </div>
      <div style="background:#fce4ec;border-radius:12px;padding:12px 16px;font-size:13px;color:#c62828">
        ⚠️ Free users can view <strong><?= htmlspecialchars($settings['free_profile_limit'] ?? '5') ?></strong> profiles.
        After that, they must purchase a package.
      </div>
    </div>
  </div>
</div>

<!-- Agora Video/Voice Call -->
<div class="settings-section">
  <div class="settings-section-header">
    <span style="font-size:20px">📞</span>
    <h3>Video / Voice Call (Agora.io)</h3>
  </div>
  <div class="settings-body">
    <div style="background:#e3f2fd;border-radius:10px;padding:12px 16px;margin-bottom:16px;font-size:13px;color:#1565c0">
      ℹ️ Get free App ID from <a href="https://www.agora.io" target="_blank" style="color:#1565c0;font-weight:600">agora.io</a>
      — Free tier: 10,000 min/month. Leave blank to disable calls.
    </div>
    <div class="form-group">
      <label>Agora App ID</label>
      <input type="text" name="agora_app_id"
        value="<?= htmlspecialchars($settings['agora_app_id'] ?? '') ?>"
        placeholder="e.g. a1b2c3d4e5f6g7h8i9j0...">
      <small style="color:#888;font-size:11px">
        Dashboard → Project Management → App ID. Keep blank = calls disabled.
      </small>
    </div>
  </div>
</div>

<!-- Preview -->
<div class="settings-section">
  <div class="settings-section-header">
    <span style="font-size:20px">👁️</span>
    <h3>App Links Preview</h3>
  </div>
  <div class="settings-body">
    <div style="display:flex;gap:12px;flex-wrap:wrap">
      <a href="tel:<?= htmlspecialchars($settings['contact_phone']) ?>"
         style="display:flex;align-items:center;gap:8px;background:#e8f5e9;color:#2e7d32;padding:10px 18px;border-radius:10px;text-decoration:none;font-size:13px;font-weight:600">
        📞 <?= htmlspecialchars($settings['contact_phone']) ?>
      </a>
      <a href="https://wa.me/<?= htmlspecialchars($settings['contact_whatsapp']) ?>?text=<?= urlencode($settings['whatsapp_message']) ?>"
         target="_blank"
         style="display:flex;align-items:center;gap:8px;background:#e8f5e9;color:#1b5e20;padding:10px 18px;border-radius:10px;text-decoration:none;font-size:13px;font-weight:600">
        💬 WhatsApp Test Link
      </a>
      <a href="mailto:<?= htmlspecialchars($settings['contact_email']) ?>"
         style="display:flex;align-items:center;gap:8px;background:#e3f2fd;color:#1565c0;padding:10px 18px;border-radius:10px;text-decoration:none;font-size:13px;font-weight:600">
        ✉️ <?= htmlspecialchars($settings['contact_email']) ?>
      </a>
    </div>
  </div>
</div>

<button type="submit" class="btn btn-primary" style="padding:12px 32px;font-size:15px">
  💾 Save All Settings
</button>

</form>

<?php include 'layout_end.php'; ?>
