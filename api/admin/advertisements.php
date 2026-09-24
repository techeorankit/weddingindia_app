<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Advertisements';
$db = getDB();

// ── Ensure table + columns exist ────────────────────────────────────────────
$db->exec("CREATE TABLE IF NOT EXISTS `advertisements` (
  `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title`           VARCHAR(200) NOT NULL,
  `description`     TEXT DEFAULT NULL,
  `media_type`      ENUM('image','video') NOT NULL DEFAULT 'image',
  `media_url`       VARCHAR(500) NOT NULL DEFAULT '',
  `click_url`       VARCHAR(500) DEFAULT NULL,
  `advertiser`      VARCHAR(200) DEFAULT NULL,
  `phone`           VARCHAR(20)  DEFAULT NULL,
  `ad_price`        DECIMAL(10,2) DEFAULT NULL COMMENT 'Amount charged from advertiser',
  `advertiser_note` VARCHAR(500) DEFAULT NULL COMMENT 'Internal notes',
  `position`        INT NOT NULL DEFAULT 4,
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `impressions`     INT UNSIGNED NOT NULL DEFAULT 0,
  `clicks`          INT UNSIGNED NOT NULL DEFAULT 0,
  `starts_at`       DATETIME DEFAULT NULL,
  `ends_at`         DATETIME DEFAULT NULL,
  `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

// Add new columns if upgrading from old version
try { $db->exec("ALTER TABLE advertisements ADD COLUMN `ad_price` DECIMAL(10,2) DEFAULT NULL"); } catch(Exception $e){}
try { $db->exec("ALTER TABLE advertisements ADD COLUMN `advertiser_note` VARCHAR(500) DEFAULT NULL"); } catch(Exception $e){}

$msg = ''; $msgType = '';

// ── Upload dir (use DOCUMENT_ROOT for reliability) ──────────────────────────
$uploadDir = rtrim($_SERVER['DOCUMENT_ROOT'], '/') . '/api/uploads/ads/';
if (!is_dir($uploadDir)) @mkdir($uploadDir, 0755, true);
$uploadUrl = 'https://weddingindiamatrimony.com/api/uploads/ads/';

// ── Handle POST ─────────────────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $act = $_POST['act'] ?? '';

    if ($act === 'add' || $act === 'edit') {
        $id              = (int)($_POST['id'] ?? 0);
        $title           = trim($_POST['title'] ?? '');
        $description     = trim($_POST['description'] ?? '');
        $media_type      = in_array($_POST['media_type'] ?? '', ['image','video']) ? $_POST['media_type'] : 'image';
        $click_url       = trim($_POST['click_url'] ?? '');
        $advertiser      = trim($_POST['advertiser'] ?? '');
        $phone           = trim($_POST['phone'] ?? '');
        $ad_price        = $_POST['ad_price'] !== '' ? (float)$_POST['ad_price'] : null;
        $advertiser_note = trim($_POST['advertiser_note'] ?? '');
        $position        = max(1, (int)($_POST['position'] ?? 4));
        $is_active       = isset($_POST['is_active']) ? 1 : 0;
        $starts_at       = !empty($_POST['starts_at']) ? $_POST['starts_at'] : null;
        $ends_at         = !empty($_POST['ends_at'])   ? $_POST['ends_at']   : null;

        if ($title === '') { $msg = 'Title is required.'; $msgType = 'error'; }
        else {
            $media_url = trim($_POST['existing_media_url'] ?? '');

            if (!empty($_FILES['media_file']['name']) && $_FILES['media_file']['error'] === 0) {
                $file    = $_FILES['media_file'];
                $ext     = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
                $allowed = $media_type === 'video' ? ['mp4','mov','avi','webm'] : ['jpg','jpeg','png','gif','webp'];

                if (!in_array($ext, $allowed)) {
                    $msg = 'Invalid file type. Allowed: ' . implode(', ', $allowed);
                    $msgType = 'error';
                } elseif ($file['size'] > 20 * 1024 * 1024) {
                    $msg = 'File too large. Max 20MB.';
                    $msgType = 'error';
                } else {
                    $filename = 'ad_' . time() . '_' . mt_rand(1000,9999) . '.' . $ext;
                    $destPath = $uploadDir . $filename;

                    if (!is_dir($uploadDir)) {
                        @mkdir($uploadDir, 0755, true);
                    }

                    if (move_uploaded_file($file['tmp_name'], $destPath)) {
                        if ($act === 'edit' && $media_url) {
                            $old = $uploadDir . basename($media_url);
                            if (file_exists($old)) @unlink($old);
                        }
                        $media_url = $uploadUrl . $filename;
                    } else {
                        $msg = 'Upload failed. Dir: ' . $uploadDir . ' | Writable: ' . (is_writable($uploadDir) ? 'YES' : 'NO');
                        $msgType = 'error';
                    }
                }
            }

            if ($msgType !== 'error') {
                if ($media_url === '' && $act === 'add') {
                    $msg = 'Please upload a media file.'; $msgType = 'error';
                } else {
                    if ($act === 'add') {
                        $db->prepare("INSERT INTO advertisements
                            (title,description,media_type,media_url,click_url,advertiser,phone,ad_price,advertiser_note,position,is_active,starts_at,ends_at)
                            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)")
                           ->execute([$title,$description,$media_type,$media_url,$click_url,$advertiser,$phone,$ad_price,$advertiser_note,$position,$is_active,$starts_at,$ends_at]);
                        $msg = '✅ Advertisement added!'; $msgType = 'success';
                    } else {
                        $db->prepare("UPDATE advertisements SET
                            title=?,description=?,media_type=?,media_url=?,click_url=?,advertiser=?,phone=?,
                            ad_price=?,advertiser_note=?,position=?,is_active=?,starts_at=?,ends_at=?,updated_at=NOW()
                            WHERE id=?")
                           ->execute([$title,$description,$media_type,$media_url,$click_url,$advertiser,$phone,$ad_price,$advertiser_note,$position,$is_active,$starts_at,$ends_at,$id]);
                        $msg = '✅ Advertisement updated!'; $msgType = 'success';
                    }
                }
            }
        }
    }

    if ($act === 'delete') {
        $id = (int)($_POST['del_id'] ?? 0);
        if ($id > 0) {
            $row = $db->prepare("SELECT media_url FROM advertisements WHERE id=?");
            $row->execute([$id]); $r = $row->fetch();
            if ($r && $r['media_url']) { $f = $uploadDir . basename($r['media_url']); if (file_exists($f)) @unlink($f); }
            $db->prepare("DELETE FROM advertisements WHERE id=?")->execute([$id]);
            $msg = 'Advertisement deleted.'; $msgType = 'success';
        }
    }

    if ($act === 'toggle') {
        $db->prepare("UPDATE advertisements SET is_active = 1 - is_active WHERE id=?")->execute([(int)($_POST['toggle_id'] ?? 0)]);
        header('Location: advertisements.php'); exit();
    }
}

// ── Fetch ───────────────────────────────────────────────────────────────────
$ads              = $db->query("SELECT * FROM advertisements ORDER BY created_at DESC")->fetchAll();
$total            = count($ads);
$activeCount      = count(array_filter($ads, fn($a) => $a['is_active']));
$totalImpressions = array_sum(array_column($ads, 'impressions'));
$totalClicks      = array_sum(array_column($ads, 'clicks'));
$totalRevenue     = array_sum(array_column($ads, 'ad_price'));

$editAd = null;
if (isset($_GET['edit'])) {
    $s = $db->prepare("SELECT * FROM advertisements WHERE id=?");
    $s->execute([(int)$_GET['edit']]); $editAd = $s->fetch();
}

include 'layout.php';
?>

<style>
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.form-row-3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px}
@media(max-width:700px){.form-row,.form-row-3{grid-template-columns:1fr}}
.media-preview{max-width:100%;max-height:180px;border-radius:10px;margin-top:8px;object-fit:contain;border:1px solid #eee}
.price-badge{background:#dcfce7;color:#166534;padding:2px 8px;border-radius:10px;font-size:12px;font-weight:700}
.expiry-ok{color:#16a34a;font-size:11px}
.expiry-warn{color:#dc2626;font-size:11px}
</style>

<?php if ($msg): ?>
<div class="alert alert-<?= $msgType === 'success' ? 'success' : 'error' ?>"><?= htmlspecialchars($msg) ?></div>
<?php endif; ?>

<!-- Stats -->
<div class="stats-row" style="grid-template-columns:repeat(5,minmax(0,1fr));margin-bottom:24px">
  <div class="stat"><div class="stat-ico" style="background:#fce4ec">📢</div>
    <div class="stat-info"><h3><?= $total ?></h3><p>Total Ads</p></div></div>
  <div class="stat"><div class="stat-ico" style="background:#dcfce7">✅</div>
    <div class="stat-info"><h3><?= $activeCount ?></h3><p>Active</p></div></div>
  <div class="stat"><div class="stat-ico" style="background:#dbeafe">👁️</div>
    <div class="stat-info"><h3><?= number_format($totalImpressions) ?></h3><p>Impressions</p></div></div>
  <div class="stat"><div class="stat-ico" style="background:#f3e8ff">🖱️</div>
    <div class="stat-info"><h3><?= number_format($totalClicks) ?></h3><p>Clicks</p></div></div>
  <div class="stat"><div class="stat-ico" style="background:#fef9c3">💰</div>
    <div class="stat-info"><h3>₹<?= number_format($totalRevenue, 0) ?></h3><p>Revenue</p></div></div>
</div>

<!-- Add / Edit Form -->
<div class="card" style="margin-bottom:24px">
  <div class="card-header">
    <h2><?= $editAd ? '✏️ Edit Advertisement' : '➕ Add New Advertisement' ?></h2>
    <?php if ($editAd): ?><a href="advertisements.php" class="btn btn-secondary btn-sm">Cancel</a><?php endif; ?>
  </div>
  <div class="card-body">
    <form method="POST" enctype="multipart/form-data">
      <input type="hidden" name="act" value="<?= $editAd ? 'edit' : 'add' ?>">
      <?php if ($editAd): ?>
        <input type="hidden" name="id" value="<?= $editAd['id'] ?>">
        <input type="hidden" name="existing_media_url" value="<?= htmlspecialchars($editAd['media_url'] ?? '') ?>">
      <?php endif; ?>

      <div class="form-row">
        <div class="form-group">
          <label>Ad Title *</label>
          <input type="text" name="title" required placeholder="e.g. 50% Off on Catering!"
            value="<?= htmlspecialchars($editAd['title'] ?? '') ?>">
        </div>
        <div class="form-group">
          <label>Advertiser Name / Company</label>
          <input type="text" name="advertiser" placeholder="e.g. Sharma Catering"
            value="<?= htmlspecialchars($editAd['advertiser'] ?? '') ?>">
        </div>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Advertiser Phone</label>
          <input type="text" name="phone" placeholder="+91 9XXXXXXXXX"
            value="<?= htmlspecialchars($editAd['phone'] ?? '') ?>">
        </div>
        <div class="form-group">
          <label>Amount Charged (₹) <span style="color:#888;font-size:11px">— Internal only</span></label>
          <input type="number" name="ad_price" min="0" step="1" placeholder="e.g. 5000"
            value="<?= htmlspecialchars($editAd['ad_price'] ?? '') ?>">
        </div>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Click URL (optional)</label>
          <input type="url" name="click_url" placeholder="https://..."
            value="<?= htmlspecialchars($editAd['click_url'] ?? '') ?>">
        </div>
        <div class="form-group">
          <label>Internal Notes</label>
          <input type="text" name="advertiser_note" placeholder="e.g. Paid via UPI on 19 Sep"
            value="<?= htmlspecialchars($editAd['advertiser_note'] ?? '') ?>">
        </div>
      </div>

      <div class="form-group">
        <label>Description (optional)</label>
        <textarea name="description" rows="2"
          style="width:100%;padding:10px 14px;border:1.5px solid #e0e0e0;border-radius:10px;font-size:14px;resize:vertical"
          placeholder="Short ad description..."><?= htmlspecialchars($editAd['description'] ?? '') ?></textarea>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Media Type *</label>
          <select name="media_type">
            <option value="image" <?= ($editAd['media_type'] ?? 'image') === 'image' ? 'selected' : '' ?>>🖼️ Image (JPG, PNG, GIF, WebP)</option>
            <option value="video" <?= ($editAd['media_type'] ?? '') === 'video' ? 'selected' : '' ?>>🎥 Video (MP4, MOV)</option>
          </select>
        </div>
        <div class="form-group">
          <label>Show After Every N Profiles</label>
          <input type="number" name="position" min="1" max="20" value="<?= $editAd['position'] ?? 4 ?>">
        </div>
      </div>

      <div class="form-group">
        <label>Upload Media File <?= $editAd ? '(Leave empty to keep current)' : '*' ?></label>
        <input type="file" name="media_file" accept="image/*,video/*" <?= $editAd ? '' : 'required' ?>
          onchange="previewMedia(this)">
        <?php if ($editAd && $editAd['media_url']): ?>
          <div style="margin-top:8px">
            <small style="color:#888">Current:</small><br>
            <?php if ($editAd['media_type'] === 'video'): ?>
              <video src="<?= htmlspecialchars($editAd['media_url']) ?>" style="max-height:120px;border-radius:8px;margin-top:4px" controls></video>
            <?php else: ?>
              <img src="<?= htmlspecialchars($editAd['media_url']) ?>" style="max-height:100px;border-radius:8px;margin-top:4px;border:1px solid #eee"
                onerror="this.style.display='none'">
            <?php endif; ?>
          </div>
        <?php endif; ?>
        <div id="mediaPreview"></div>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Start Date (optional — leave blank for immediate)</label>
          <input type="datetime-local" name="starts_at"
            value="<?= $editAd && $editAd['starts_at'] ? date('Y-m-d\TH:i', strtotime($editAd['starts_at'])) : '' ?>">
        </div>
        <div class="form-group">
          <label>End Date (optional — leave blank for no expiry)</label>
          <input type="datetime-local" name="ends_at"
            value="<?= $editAd && $editAd['ends_at'] ? date('Y-m-d\TH:i', strtotime($editAd['ends_at'])) : '' ?>">
        </div>
      </div>

      <div class="form-group">
        <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
          <input type="checkbox" name="is_active" value="1"
            <?= ($editAd ? $editAd['is_active'] : 1) ? 'checked' : '' ?> style="width:16px;height:16px">
          Active (show in app)
        </label>
      </div>

      <button type="submit" class="btn btn-primary">
        <?= $editAd ? '💾 Save Changes' : '➕ Add Advertisement' ?>
      </button>
    </form>
  </div>
</div>

<!-- Ads List -->
<?php if (empty($ads)): ?>
<div class="card"><div class="card-body" style="text-align:center;padding:40px;color:#9ca3af">
  <div style="font-size:36px;margin-bottom:10px">📢</div>
  <p>No advertisements yet. Add your first ad above!</p>
</div></div>
<?php else: ?>
<div class="card">
  <div class="card-header"><h2>📋 All Advertisements (<?= $total ?>)</h2></div>
  <div class="tbl-scroll">
    <table>
      <thead>
        <tr>
          <th>Preview</th>
          <th>Title / Advertiser</th>
          <th>Amount & Notes</th>
          <th>Stats</th>
          <th>Schedule & Expiry</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($ads as $ad):
          $now = time();
          $endTs = $ad['ends_at'] ? strtotime($ad['ends_at']) : null;
          $daysLeft = $endTs ? ceil(($endTs - $now) / 86400) : null;
          $isExpired = $endTs && $endTs < $now;
        ?>
        <tr>
          <!-- Preview -->
          <td>
            <?php if ($ad['media_type'] === 'video'): ?>
              <div style="width:80px;height:50px;background:#1a1a2e;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:20px">▶️</div>
            <?php elseif ($ad['media_url']): ?>
              <img src="<?= htmlspecialchars($ad['media_url']) ?>" alt=""
                style="width:80px;height:50px;object-fit:cover;border-radius:6px;border:1px solid #eee"
                onerror="this.src='';this.style.background='#f5f5f5'">
            <?php else: ?>
              <div style="width:80px;height:50px;background:#f5f5f5;border-radius:6px;display:flex;align-items:center;justify-content:center;color:#ccc">🖼️</div>
            <?php endif; ?>
          </td>

          <!-- Title / Advertiser -->
          <td>
            <div style="font-weight:600;font-size:13px"><?= htmlspecialchars($ad['title']) ?></div>
            <?php if ($ad['advertiser']): ?>
              <div style="font-size:11px;color:#888">🏢 <?= htmlspecialchars($ad['advertiser']) ?></div>
            <?php endif; ?>
            <?php if ($ad['phone']): ?>
              <div style="font-size:11px;color:#888">📞 <?= htmlspecialchars($ad['phone']) ?></div>
            <?php endif; ?>
          </td>

          <!-- Amount & Notes -->
          <td>
            <?php if ($ad['ad_price']): ?>
              <span class="price-badge">₹<?= number_format($ad['ad_price'], 0) ?></span>
            <?php else: ?>
              <span style="color:#ccc;font-size:12px">—</span>
            <?php endif; ?>
            <?php if ($ad['advertiser_note']): ?>
              <div style="font-size:11px;color:#6b7280;margin-top:3px">📝 <?= htmlspecialchars($ad['advertiser_note']) ?></div>
            <?php endif; ?>
          </td>

          <!-- Stats -->
          <td>
            <div style="font-size:12px">👁️ <?= number_format($ad['impressions']) ?> views</div>
            <div style="font-size:12px">🖱️ <?= number_format($ad['clicks']) ?> clicks</div>
            <?php if ($ad['impressions'] > 0): ?>
              <div style="font-size:11px;color:#888">CTR: <?= round($ad['clicks'] / $ad['impressions'] * 100, 1) ?>%</div>
            <?php endif; ?>
          </td>

          <!-- Schedule & Expiry -->
          <td style="font-size:11px">
            <?php if ($ad['starts_at']): ?>
              <div>▶ <?= date('d M Y', strtotime($ad['starts_at'])) ?></div>
            <?php else: ?>
              <div style="color:#888">▶ Immediate</div>
            <?php endif; ?>
            <?php if ($ad['ends_at']): ?>
              <div class="<?= $isExpired ? 'expiry-warn' : 'expiry-ok' ?>">
                ⏹ <?= date('d M Y', strtotime($ad['ends_at'])) ?>
                <?php if ($isExpired): ?>
                  <br><strong>⚠ EXPIRED</strong>
                <?php elseif ($daysLeft <= 3): ?>
                  <br><strong>⚠ <?= $daysLeft ?>d left</strong>
                <?php else: ?>
                  <br><?= $daysLeft ?> days left
                <?php endif; ?>
              </div>
            <?php else: ?>
              <div style="color:#888">⏹ No expiry</div>
            <?php endif; ?>
          </td>

          <!-- Status -->
          <td>
            <form method="POST" style="display:inline">
              <input type="hidden" name="act" value="toggle">
              <input type="hidden" name="toggle_id" value="<?= $ad['id'] ?>">
              <button type="submit" style="cursor:pointer;border:none;padding:4px 10px;border-radius:10px;font-size:11px;font-weight:700;
                background:<?= $ad['is_active'] ? '#dcfce7' : '#fee2e2' ?>;
                color:<?= $ad['is_active'] ? '#166534' : '#991b1b' ?>">
                <?= $ad['is_active'] ? '✅ Active' : '❌ Paused' ?>
              </button>
            </form>
            <?php if ($isExpired): ?>
              <div style="font-size:10px;color:#dc2626;margin-top:3px">Expired</div>
            <?php endif; ?>
          </td>

          <!-- Actions -->
          <td>
            <a href="?edit=<?= $ad['id'] ?>" class="btn btn-info btn-sm">✏️</a>
            <form method="POST" style="display:inline" onsubmit="return confirm('Delete this ad?')">
              <input type="hidden" name="act" value="delete">
              <input type="hidden" name="del_id" value="<?= $ad['id'] ?>">
              <button type="submit" class="btn btn-danger btn-sm">🗑️</button>
            </form>
          </td>
        </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>
</div>
<?php endif; ?>

<script>
function previewMedia(input) {
  const wrap = document.getElementById('mediaPreview');
  wrap.innerHTML = '';
  if (!input.files[0]) return;
  const file = input.files[0];
  const url = URL.createObjectURL(file);
  if (file.type.startsWith('video/')) {
    wrap.innerHTML = `<video src="${url}" controls style="max-height:150px;border-radius:10px;margin-top:8px;max-width:100%"></video>`;
  } else {
    wrap.innerHTML = `<img src="${url}" style="max-height:150px;border-radius:10px;margin-top:8px;max-width:100%;object-fit:contain;border:1px solid #eee">`;
  }
}
</script>

<?php include 'layout_end.php'; ?>
