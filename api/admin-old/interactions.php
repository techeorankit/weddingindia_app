<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Interactions';

$db = getDB();

$type  = $_GET['type'] ?? '';
$page  = max(1, (int)($_GET['page'] ?? 1));
$limit = 25;
$offset = ($page - 1) * $limit;

$where = $type ? "WHERE i.type=?" : "";
$params = $type ? [$type] : [];

$total = $db->prepare("SELECT COUNT(*) FROM interactions i $where");
$total->execute($params);
$totalCount = $total->fetchColumn();
$totalPages = ceil($totalCount / $limit);

// Check if interactions table exists
try {
    $stmt = $db->prepare("
        SELECT i.*, i.type,
               p1.full_name as from_name, u1.phone as from_phone,
               p2.full_name as to_name, u2.phone as to_phone
        FROM interactions i
        JOIN users u1 ON u1.id=i.from_user_id
        LEFT JOIN user_profiles p1 ON p1.user_id=i.from_user_id
        JOIN users u2 ON u2.id=i.to_user_id
        LEFT JOIN user_profiles p2 ON p2.user_id=i.to_user_id
        $where
        ORDER BY i.created_at DESC
        LIMIT $limit OFFSET $offset
    ");
    $stmt->execute($params);
    $interactions = $stmt->fetchAll();
} catch (Exception $e) {
    $interactions = [];
    $totalCount = 0;
}

// Type counts
$typeCounts = [];
try {
    $tc = $db->query("SELECT type, COUNT(*) as cnt FROM interactions GROUP BY type")->fetchAll();
    foreach ($tc as $t) $typeCounts[$t['type']] = $t['cnt'];
} catch (Exception $e) {}

include 'layout.php';
?>

<div class="stats-grid" style="margin-bottom:20px">
  <?php
  $typeIcons = ['like'=>'❤️','interest'=>'💌','view'=>'👁️','block'=>'🚫','message'=>'💬'];
  foreach ($typeIcons as $t => $icon): ?>
  <a href="?type=<?= $t ?>" style="text-decoration:none">
    <div class="stat-card" style="<?= $type===$t ? 'border:2px solid #E91E63' : '' ?>">
      <div class="stat-icon" style="background:#fce4ec;font-size:22px"><?= $icon ?></div>
      <div class="stat-info">
        <h3><?= $typeCounts[$t] ?? 0 ?></h3>
        <p><?= ucfirst($t) ?>s</p>
      </div>
    </div>
  </a>
  <?php endforeach; ?>
</div>

<div class="table-card">
  <div class="table-header">
    <h2>Interactions <?= $type ? "($type)" : '' ?> (<?= $totalCount ?>)</h2>
    <?php if ($type): ?><a href="interactions.php" class="btn" style="background:#f5f5f5">Clear Filter</a><?php endif; ?>
  </div>
  <table>
    <thead>
      <tr><th>From</th><th>Type</th><th>To</th><th>Date</th></tr>
    </thead>
    <tbody>
      <?php foreach ($interactions as $i): ?>
      <tr>
        <td>
          <div style="font-weight:600"><?= htmlspecialchars($i['from_name'] ?? 'Unknown') ?></div>
          <div style="font-size:11px;color:#aaa"><?= $i['from_phone'] ?></div>
        </td>
        <td>
          <?php
          $colors = ['like'=>'badge-red','interest'=>'badge-blue','view'=>'badge-orange','block'=>'badge-red','message'=>'badge-green'];
          $icons  = ['like'=>'❤️','interest'=>'💌','view'=>'👁️','block'=>'🚫','message'=>'💬'];
          ?>
          <span class="badge <?= $colors[$i['type']] ?? 'badge-blue' ?>">
            <?= ($icons[$i['type']] ?? '') . ' ' . ucfirst($i['type']) ?>
          </span>
        </td>
        <td>
          <div style="font-weight:600"><?= htmlspecialchars($i['to_name'] ?? 'Unknown') ?></div>
          <div style="font-size:11px;color:#aaa"><?= $i['to_phone'] ?></div>
        </td>
        <td style="color:#888;font-size:13px"><?= date('d M Y, h:i A', strtotime($i['created_at'])) ?></td>
      </tr>
      <?php endforeach; ?>
      <?php if (empty($interactions)): ?>
        <tr><td colspan="4" style="text-align:center;color:#aaa;padding:40px">No interactions found</td></tr>
      <?php endif; ?>
    </tbody>
  </table>
  <?php if ($totalPages > 1): ?>
  <div class="pagination">
    <?php for ($pg = 1; $pg <= $totalPages; $pg++): ?>
      <a href="?page=<?= $pg ?>&type=<?= urlencode($type) ?>"
         class="page-btn <?= $pg === $page ? 'active' : '' ?>"><?= $pg ?></a>
    <?php endfor; ?>
  </div>
  <?php endif; ?>
</div>

<?php include 'layout_end.php'; ?>
