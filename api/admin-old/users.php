<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Users';

$db = getDB();

// Delete user
if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    $db->prepare("DELETE FROM users WHERE id=?")->execute([$_GET['delete']]);
    header('Location: users.php?msg=deleted');
    exit();
}

// Toggle verify
if (isset($_GET['toggle_verify']) && is_numeric($_GET['toggle_verify'])) {
    $db->prepare("UPDATE users SET is_verified = 1 - is_verified WHERE id=?")->execute([$_GET['toggle_verify']]);
    header('Location: users.php?msg=updated');
    exit();
}

$search = trim($_GET['search'] ?? '');
$page   = max(1, (int)($_GET['page'] ?? 1));
$limit  = 20;
$offset = ($page - 1) * $limit;

$where = $search ? "WHERE u.phone LIKE ? OR p.full_name LIKE ?" : "";
$params = $search ? ["%$search%", "%$search%"] : [];

$total = $db->prepare("SELECT COUNT(*) FROM users u LEFT JOIN user_profiles p ON p.user_id=u.id $where");
$total->execute($params);
$totalCount = $total->fetchColumn();
$totalPages = ceil($totalCount / $limit);

$stmt = $db->prepare("
    SELECT u.id, u.phone, u.country_code, u.is_verified, u.created_at,
           p.full_name, p.gender, p.profile_photo, p.is_profile_complete
    FROM users u
    LEFT JOIN user_profiles p ON p.user_id = u.id
    $where
    ORDER BY u.created_at DESC
    LIMIT $limit OFFSET $offset
");
$stmt->execute($params);
$users = $stmt->fetchAll();

include 'layout.php';
?>

<?php if (isset($_GET['msg'])): ?>
  <div class="alert alert-success">
    <?= $_GET['msg'] === 'deleted' ? '✅ User deleted successfully' : '✅ User updated successfully' ?>
  </div>
<?php endif; ?>

<div class="table-card">
  <div class="table-header">
    <h2>All Users (<?= $totalCount ?>)</h2>
    <form method="GET" style="display:flex;gap:10px">
      <input type="text" name="search" class="search-box" placeholder="Search by name or phone..." value="<?= htmlspecialchars($search) ?>">
      <button type="submit" class="btn btn-primary">Search</button>
      <?php if ($search): ?><a href="users.php" class="btn" style="background:#f5f5f5">Clear</a><?php endif; ?>
    </form>
  </div>
  <table>
    <thead>
      <tr>
        <th>#</th>
        <th>User</th>
        <th>Phone</th>
        <th>Gender</th>
        <th>Profile</th>
        <th>Status</th>
        <th>Joined</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($users as $i => $u): ?>
      <tr>
        <td style="color:#aaa"><?= $offset + $i + 1 ?></td>
        <td>
          <div style="display:flex;align-items:center;gap:10px">
            <div class="avatar">
              <?php if ($u['profile_photo']): ?>
                <img src="../uploads/<?= htmlspecialchars($u['profile_photo']) ?>">
              <?php else: ?>
                <?= strtoupper(substr($u['full_name'] ?? $u['phone'], 0, 1)) ?>
              <?php endif; ?>
            </div>
            <div>
              <div style="font-weight:600"><?= htmlspecialchars($u['full_name'] ?? 'No Name') ?></div>
              <div style="font-size:11px;color:#aaa">ID: <?= $u['id'] ?></div>
            </div>
          </div>
        </td>
        <td><?= htmlspecialchars($u['country_code'] . ' ' . $u['phone']) ?></td>
        <td><?= $u['gender'] ?? '-' ?></td>
        <td>
          <span class="badge <?= $u['is_profile_complete'] ? 'badge-green' : 'badge-orange' ?>">
            <?= $u['is_profile_complete'] ? 'Complete' : 'Incomplete' ?>
          </span>
        </td>
        <td>
          <a href="users.php?toggle_verify=<?= $u['id'] ?>" onclick="return confirm('Toggle verification?')"
             class="badge <?= $u['is_verified'] ? 'badge-green' : 'badge-red' ?>" style="cursor:pointer;text-decoration:none">
            <?= $u['is_verified'] ? '✅ Verified' : '❌ Unverified' ?>
          </a>
        </td>
        <td><?= date('d M Y', strtotime($u['created_at'])) ?></td>
        <td style="display:flex;gap:6px;flex-wrap:wrap">
          <a href="user_detail.php?id=<?= $u['id'] ?>" class="btn btn-info">View</a>
          <a href="users.php?delete=<?= $u['id'] ?>" class="btn btn-danger"
             onclick="return confirm('Delete this user permanently?')">Delete</a>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (empty($users)): ?>
        <tr><td colspan="8" style="text-align:center;color:#aaa;padding:40px">No users found</td></tr>
      <?php endif; ?>
    </tbody>
  </table>

  <?php if ($totalPages > 1): ?>
  <div class="pagination">
    <?php for ($p = 1; $p <= $totalPages; $p++): ?>
      <a href="?page=<?= $p ?>&search=<?= urlencode($search) ?>"
         class="page-btn <?= $p === $page ? 'active' : '' ?>"><?= $p ?></a>
    <?php endfor; ?>
  </div>
  <?php endif; ?>
</div>

<?php include 'layout_end.php'; ?>
