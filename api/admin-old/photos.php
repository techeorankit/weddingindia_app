<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Photos';

$db = getDB();

// Delete photo
if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    $photo = $db->prepare("SELECT photo_path FROM user_photos WHERE id=?");
    $photo->execute([$_GET['delete']]);
    $ph = $photo->fetch();
    if ($ph) {
        $file = __DIR__ . '/../uploads/' . $ph['photo_path'];
        if (file_exists($file)) unlink($file);
        $db->prepare("DELETE FROM user_photos WHERE id=?")->execute([$_GET['delete']]);
    }
    header('Location: photos.php?msg=deleted');
    exit();
}

$page   = max(1, (int)($_GET['page'] ?? 1));
$limit  = 30;
$offset = ($page - 1) * $limit;

$total = $db->query("SELECT COUNT(*) FROM user_photos")->fetchColumn();
$totalPages = ceil($total / $limit);

$photos = $db->prepare("
    SELECT up.*, p.full_name, u.phone
    FROM user_photos up
    JOIN users u ON u.id=up.user_id
    LEFT JOIN user_profiles p ON p.user_id=up.user_id
    ORDER BY up.created_at DESC
    LIMIT $limit OFFSET $offset
");
$photos->execute();
$photos = $photos->fetchAll();

include 'layout.php';
?>

<?php if (isset($_GET['msg'])): ?>
  <div class="alert alert-success">✅ Photo deleted</div>
<?php endif; ?>

<div class="table-card">
  <div class="table-header">
    <h2>All Photos (<?= $total ?>)</h2>
  </div>
  <div style="padding:20px;display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:16px">
    <?php foreach ($photos as $ph): ?>
    <div style="border-radius:12px;overflow:hidden;border:1px solid #f0f0f0;background:#fff">
      <div style="position:relative">
        <img src="../uploads/<?= htmlspecialchars($ph['photo_path']) ?>"
             style="width:100%;aspect-ratio:1;object-fit:cover"
             onerror="this.src='https://via.placeholder.com/180?text=No+Image'">
        <?php if ($ph['is_primary']): ?>
          <span style="position:absolute;top:8px;left:8px;background:#E91E63;color:#fff;font-size:10px;padding:2px 8px;border-radius:10px">Primary</span>
        <?php endif; ?>
      </div>
      <div style="padding:10px">
        <div style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
          <?= htmlspecialchars($ph['full_name'] ?? $ph['phone']) ?>
        </div>
        <div style="font-size:11px;color:#aaa;margin-top:2px"><?= date('d M Y', strtotime($ph['created_at'])) ?></div>
        <div style="display:flex;gap:6px;margin-top:8px">
          <a href="user_detail.php?id=<?= $ph['user_id'] ?>" class="btn btn-info" style="font-size:11px;padding:4px 10px">View User</a>
          <a href="photos.php?delete=<?= $ph['id'] ?>" class="btn btn-danger" style="font-size:11px;padding:4px 10px"
             onclick="return confirm('Delete this photo?')">Delete</a>
        </div>
      </div>
    </div>
    <?php endforeach; ?>
    <?php if (empty($photos)): ?>
      <div style="grid-column:1/-1;text-align:center;color:#aaa;padding:40px">No photos found</div>
    <?php endif; ?>
  </div>
  <?php if ($totalPages > 1): ?>
  <div class="pagination">
    <?php for ($pg = 1; $pg <= $totalPages; $pg++): ?>
      <a href="?page=<?= $pg ?>" class="page-btn <?= $pg === $page ? 'active' : '' ?>"><?= $pg ?></a>
    <?php endfor; ?>
  </div>
  <?php endif; ?>
</div>

<?php include 'layout_end.php'; ?>
