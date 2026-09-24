<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Profiles';

$db = getDB();

$gender  = $_GET['gender'] ?? '';
$search  = trim($_GET['search'] ?? '');
$page    = max(1, (int)($_GET['page'] ?? 1));
$limit   = 20;
$offset  = ($page - 1) * $limit;

$conditions = ["p.full_name IS NOT NULL"];
$params = [];
if ($gender) { $conditions[] = "p.gender=?"; $params[] = $gender; }
if ($search) { $conditions[] = "(p.full_name LIKE ? OR u.phone LIKE ?)"; $params[] = "%$search%"; $params[] = "%$search%"; }
$where = "WHERE " . implode(" AND ", $conditions);

$total = $db->prepare("SELECT COUNT(*) FROM user_profiles p JOIN users u ON u.id=p.user_id $where");
$total->execute($params);
$totalCount = $total->fetchColumn();
$totalPages = ceil($totalCount / $limit);

$stmt = $db->prepare("
    SELECT p.*, u.phone, u.country_code, u.is_verified,
           r.name as religion, s.name as state, el.name as education
    FROM user_profiles p
    JOIN users u ON u.id=p.user_id
    LEFT JOIN user_religion ur ON ur.user_id=p.user_id
    LEFT JOIN religions r ON r.id=ur.religion_id
    LEFT JOIN user_location ul ON ul.user_id=p.user_id
    LEFT JOIN states s ON s.id=ul.state_id
    LEFT JOIN user_education ue ON ue.user_id=p.user_id
    LEFT JOIN education_levels el ON el.id=ue.education_id
    $where
    ORDER BY p.updated_at DESC
    LIMIT $limit OFFSET $offset
");
$stmt->execute($params);
$profiles = $stmt->fetchAll();

include 'layout.php';
?>

<div class="table-card">
  <div class="table-header">
    <h2>Profiles (<?= $totalCount ?>)</h2>
    <form method="GET" style="display:flex;gap:10px;flex-wrap:wrap">
      <input type="text" name="search" class="search-box" placeholder="Search name or phone..." value="<?= htmlspecialchars($search) ?>">
      <select name="gender" style="padding:9px 14px;border:1.5px solid #e0e0e0;border-radius:10px;font-size:14px;outline:none">
        <option value="">All Genders</option>
        <option value="Male" <?= $gender==='Male'?'selected':'' ?>>Male</option>
        <option value="Female" <?= $gender==='Female'?'selected':'' ?>>Female</option>
        <option value="Other" <?= $gender==='Other'?'selected':'' ?>>Other</option>
      </select>
      <button type="submit" class="btn btn-primary">Filter</button>
      <a href="profiles.php" class="btn" style="background:#f5f5f5">Clear</a>
    </form>
  </div>
  <table>
    <thead>
      <tr>
        <th>#</th><th>Profile</th><th>Phone</th><th>Religion</th>
        <th>State</th><th>Education</th><th>Status</th><th>Action</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($profiles as $i => $p): ?>
      <tr>
        <td style="color:#aaa"><?= $offset + $i + 1 ?></td>
        <td>
          <div style="display:flex;align-items:center;gap:10px">
            <div class="avatar">
              <?php if ($p['profile_photo']): ?>
                <img src="../uploads/<?= htmlspecialchars($p['profile_photo']) ?>">
              <?php else: ?>
                <?= strtoupper(substr($p['full_name'], 0, 1)) ?>
              <?php endif; ?>
            </div>
            <div>
              <div style="font-weight:600"><?= htmlspecialchars($p['full_name']) ?></div>
              <div style="font-size:11px;color:#aaa"><?= $p['gender'] ?> <?= $p['dob'] ? '• ' . (date('Y') - date('Y', strtotime($p['dob']))) . ' yrs' : '' ?></div>
            </div>
          </div>
        </td>
        <td><?= htmlspecialchars($p['country_code'] . ' ' . $p['phone']) ?></td>
        <td><?= $p['religion'] ?? '-' ?></td>
        <td><?= $p['state'] ?? '-' ?></td>
        <td><?= $p['education'] ?? '-' ?></td>
        <td>
          <span class="badge <?= $p['is_profile_complete'] ? 'badge-green' : 'badge-orange' ?>">
            <?= $p['is_profile_complete'] ? 'Complete' : 'Incomplete' ?>
          </span>
        </td>
        <td><a href="user_detail.php?id=<?= $p['user_id'] ?>" class="btn btn-info">View</a></td>
      </tr>
      <?php endforeach; ?>
      <?php if (empty($profiles)): ?>
        <tr><td colspan="8" style="text-align:center;color:#aaa;padding:40px">No profiles found</td></tr>
      <?php endif; ?>
    </tbody>
  </table>
  <?php if ($totalPages > 1): ?>
  <div class="pagination">
    <?php for ($pg = 1; $pg <= $totalPages; $pg++): ?>
      <a href="?page=<?= $pg ?>&search=<?= urlencode($search) ?>&gender=<?= urlencode($gender) ?>"
         class="page-btn <?= $pg === $page ? 'active' : '' ?>"><?= $pg ?></a>
    <?php endfor; ?>
  </div>
  <?php endif; ?>
</div>

<?php include 'layout_end.php'; ?>
