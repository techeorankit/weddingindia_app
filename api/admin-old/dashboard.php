<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Dashboard';

$db = getDB();

// Stats
$totalUsers    = $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
$verifiedUsers = $db->query("SELECT COUNT(*) FROM users WHERE is_verified=1")->fetchColumn();
$totalProfiles = $db->query("SELECT COUNT(*) FROM user_profiles WHERE full_name IS NOT NULL")->fetchColumn();
$todayUsers    = $db->query("SELECT COUNT(*) FROM users WHERE DATE(created_at)=CURDATE()")->fetchColumn();

// Recent users
$recentUsers = $db->query("
    SELECT u.id, u.phone, u.country_code, u.is_verified, u.created_at,
           p.full_name, p.gender, p.profile_photo
    FROM users u
    LEFT JOIN user_profiles p ON p.user_id = u.id
    ORDER BY u.created_at DESC LIMIT 10
")->fetchAll();

include 'layout.php';
?>

<div class="stats-grid">
  <div class="stat-card">
    <div class="stat-icon" style="background:#fce4ec">👥</div>
    <div class="stat-info">
      <h3><?= $totalUsers ?></h3>
      <p>Total Users</p>
    </div>
  </div>
  <div class="stat-card">
    <div class="stat-icon" style="background:#e8f5e9">✅</div>
    <div class="stat-info">
      <h3><?= $verifiedUsers ?></h3>
      <p>Verified Users</p>
    </div>
  </div>
  <div class="stat-card">
    <div class="stat-icon" style="background:#e3f2fd">👤</div>
    <div class="stat-info">
      <h3><?= $totalProfiles ?></h3>
      <p>Complete Profiles</p>
    </div>
  </div>
  <div class="stat-card">
    <div class="stat-icon" style="background:#fff3e0">🆕</div>
    <div class="stat-info">
      <h3><?= $todayUsers ?></h3>
      <p>Today's Signups</p>
    </div>
  </div>
</div>

<div class="table-card">
  <div class="table-header">
    <h2>Recent Users</h2>
    <a href="users.php" class="btn btn-primary">View All</a>
  </div>
  <table>
    <thead>
      <tr>
        <th>User</th>
        <th>Phone</th>
        <th>Gender</th>
        <th>Status</th>
        <th>Joined</th>
        <th>Action</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($recentUsers as $u): ?>
      <tr>
        <td>
          <div style="display:flex;align-items:center;gap:10px">
            <div class="avatar">
              <?php if ($u['profile_photo']): ?>
                <img src="../uploads/<?= htmlspecialchars($u['profile_photo']) ?>">
              <?php else: ?>
                <?= strtoupper(substr($u['full_name'] ?? $u['phone'], 0, 1)) ?>
              <?php endif; ?>
            </div>
            <span><?= htmlspecialchars($u['full_name'] ?? 'No Name') ?></span>
          </div>
        </td>
        <td><?= htmlspecialchars($u['country_code'] . ' ' . $u['phone']) ?></td>
        <td><?= $u['gender'] ?? '-' ?></td>
        <td>
          <span class="badge <?= $u['is_verified'] ? 'badge-green' : 'badge-orange' ?>">
            <?= $u['is_verified'] ? 'Verified' : 'Pending' ?>
          </span>
        </td>
        <td><?= date('d M Y', strtotime($u['created_at'])) ?></td>
        <td>
          <a href="user_detail.php?id=<?= $u['id'] ?>" class="btn btn-info">View</a>
        </td>
      </tr>
      <?php endforeach; ?>
    </tbody>
  </table>
</div>

<?php include 'layout_end.php'; ?>
