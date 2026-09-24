<?php
// layout.php - include at top of every admin page
// Usage: include 'layout.php'; ... content ... include 'layout_end.php';
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= $pageTitle ?? 'Admin' ?> - Wedding India</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; display: flex; min-height: 100vh; }

  /* Sidebar */
  .sidebar {
    width: 220px; min-height: 100vh;
    background: linear-gradient(180deg, #E91E63 0%, #880E4F 100%);
    color: #fff; flex-shrink: 0; position: fixed; top: 0; left: 0; bottom: 0;
    display: flex; flex-direction: column; overflow: hidden;
  }
  .sidebar-logo {
    padding: 24px 20px; border-bottom: 1px solid rgba(255,255,255,.15);
    display: flex; align-items: center; gap: 12px;
  }
  .sidebar-logo .icon { font-size: 28px; }
  .sidebar-logo h2 { font-size: 16px; font-weight: 700; line-height: 1.2; }
  .sidebar-logo p { font-size: 11px; opacity: .7; }
  .sidebar-nav { padding: 16px 0; flex: 1; overflow-y: auto; }
  .nav-item {
    display: flex; align-items: center; gap: 10px;
    padding: 10px 20px; color: rgba(255,255,255,.85);
    text-decoration: none; font-size: 13px; font-weight: 500;
    transition: all .2s; border-left: 3px solid transparent;
    white-space: nowrap; overflow: hidden;
  }
  .nav-item:hover, .nav-item.active {
    background: rgba(255,255,255,.15);
    color: #fff; border-left-color: #fff;
  }
  .nav-item .icon {
    font-size: 16px;
    width: 20px; min-width: 20px;
    text-align: center;
    display: inline-flex; align-items: center; justify-content: center;
    line-height: 1;
  }
  .nav-section {
    padding: 10px 20px 3px;
    font-size: 10px; font-weight: 700; letter-spacing: 1px;
    opacity: .5; text-transform: uppercase;
  }
  .sidebar-footer {
    padding: 16px 20px; border-top: 1px solid rgba(255,255,255,.15);
  }
  .logout-btn {
    display: flex; align-items: center; gap: 10px;
    color: rgba(255,255,255,.8); text-decoration: none;
    font-size: 14px; padding: 8px 0;
  }
  .logout-btn:hover { color: #fff; }

  /* Main content */
  .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; }
  .topbar {
    background: #fff; padding: 16px 28px;
    border-bottom: 1px solid #eee;
    display: flex; align-items: center; justify-content: space-between;
    position: sticky; top: 0; z-index: 10;
  }
  .topbar h1 { font-size: 20px; font-weight: 700; color: #1a1a1a; }
  .topbar .admin-badge {
    background: #fce4ec; color: #E91E63;
    padding: 6px 14px; border-radius: 20px;
    font-size: 13px; font-weight: 600;
  }
  .content { padding: 28px; flex: 1; }

  /* Cards */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: 16px; margin-bottom: 28px;
  }
  .stat-card {
    background: #fff; border-radius: 16px; padding: 20px;
    box-shadow: 0 2px 8px rgba(0,0,0,.06);
    display: flex; align-items: center; gap: 14px;
  }
  .stat-icon {
    width: 48px; height: 48px; min-width: 48px; border-radius: 14px;
    display: flex; align-items: center; justify-content: center; font-size: 22px;
  }
  .stat-info h3 { font-size: 24px; font-weight: 700; color: #1a1a1a; line-height: 1.1; }
  .stat-info p { font-size: 12px; color: #888; margin-top: 3px; }

  /* Table */
  .table-card { background: #fff; border-radius: 16px; box-shadow: 0 2px 8px rgba(0,0,0,.06); overflow: hidden; }
  .table-header {
    padding: 20px 24px; border-bottom: 1px solid #f0f0f0;
    display: flex; align-items: center; justify-content: space-between;
  }
  .table-header h2 { font-size: 16px; font-weight: 700; }
  table { width: 100%; border-collapse: collapse; }
  th {
    background: #fafafa; padding: 12px 16px;
    text-align: left; font-size: 12px; font-weight: 600;
    color: #888; text-transform: uppercase; letter-spacing: .5px;
    border-bottom: 1px solid #f0f0f0;
  }
  td { padding: 14px 16px; border-bottom: 1px solid #f8f8f8; font-size: 14px; color: #333; vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #fafafa; }

  /* Badges */
  .badge {
    display: inline-block; padding: 3px 10px; border-radius: 20px;
    font-size: 11px; font-weight: 600;
  }
  .badge-green { background: #e8f5e9; color: #2e7d32; }
  .badge-red { background: #fce4ec; color: #c62828; }
  .badge-blue { background: #e3f2fd; color: #1565c0; }
  .badge-orange { background: #fff3e0; color: #e65100; }

  /* Buttons */
  .btn { padding: 8px 16px; border-radius: 8px; border: none; cursor: pointer; font-size: 13px; font-weight: 600; text-decoration: none; display: inline-block; }
  .btn-primary { background: #E91E63; color: #fff; }
  .btn-danger { background: #fce4ec; color: #c62828; }
  .btn-info { background: #e3f2fd; color: #1565c0; }
  .btn:hover { opacity: .85; }

  /* Search */
  .search-box {
    padding: 9px 14px; border: 1.5px solid #e0e0e0; border-radius: 10px;
    font-size: 14px; outline: none; width: 240px;
  }
  .search-box:focus { border-color: #E91E63; }

  /* Alert */
  .alert { padding: 12px 16px; border-radius: 10px; margin-bottom: 20px; font-size: 14px; }
  .alert-success { background: #e8f5e9; color: #2e7d32; border: 1px solid #c8e6c9; }
  .alert-error { background: #fce4ec; color: #c62828; border: 1px solid #ffcdd2; }

  /* Avatar */
  .avatar {
    width: 36px; height: 36px; border-radius: 50%;
    background: #fce4ec; color: #E91E63;
    display: inline-flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 14px; overflow: hidden;
  }
  .avatar img { width: 100%; height: 100%; object-fit: cover; }

  /* Pagination */
  .pagination { display: flex; gap: 6px; align-items: center; padding: 16px 24px; }
  .page-btn {
    padding: 6px 12px; border-radius: 8px; border: 1px solid #e0e0e0;
    background: #fff; cursor: pointer; font-size: 13px; text-decoration: none; color: #333;
  }
  .page-btn.active { background: #E91E63; color: #fff; border-color: #E91E63; }
  .page-btn:hover:not(.active) { background: #fce4ec; }

  /* Modal */
  .modal-overlay {
    display: none; position: fixed; inset: 0;
    background: rgba(0,0,0,.5); z-index: 100;
    align-items: center; justify-content: center;
  }
  .modal-overlay.open { display: flex; }
  .modal {
    background: #fff; border-radius: 16px; padding: 28px;
    width: 100%; max-width: 500px; max-height: 90vh; overflow-y: auto;
  }
  .modal h2 { font-size: 18px; font-weight: 700; margin-bottom: 20px; }
  .form-group { margin-bottom: 16px; }
  .form-group label { display: block; font-size: 13px; font-weight: 600; color: #444; margin-bottom: 6px; }
  .form-group input, .form-group select, .form-group textarea {
    width: 100%; padding: 10px 14px;
    border: 1.5px solid #e0e0e0; border-radius: 10px;
    font-size: 14px; outline: none;
  }
  .form-group input:focus, .form-group select:focus { border-color: #E91E63; }
  .modal-footer { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; }
</style>
</head>
<body>

<div class="sidebar">
  <div class="sidebar-logo">
    <div class="icon">💍</div>
    <div>
      <h2>Wedding India</h2>
      <p>Admin Panel</p>
    </div>
  </div>
  <nav class="sidebar-nav">
    <div class="nav-section">Main</div>
    <a href="dashboard.php" class="nav-item <?= ($pageTitle ?? '') === 'Dashboard' ? 'active' : '' ?>">
      <span class="icon">📊</span> Dashboard
    </a>
    <div class="nav-section">Users</div>
    <a href="users.php" class="nav-item <?= ($pageTitle ?? '') === 'Users' ? 'active' : '' ?>">
      <span class="icon">👥</span> All Users
    </a>
    <a href="profiles.php" class="nav-item <?= ($pageTitle ?? '') === 'Profiles' ? 'active' : '' ?>">
      <span class="icon">👤</span> Profiles
    </a>
    <div class="nav-section">Master Data</div>
    <a href="manage_table.php?table=religions" class="nav-item <?= (($_GET['table'] ?? '') === 'religions') ? 'active' : '' ?>">
      <span class="icon">🕉️</span> Religions
    </a>
    <a href="manage_table.php?table=mother_tongues" class="nav-item <?= (($_GET['table'] ?? '') === 'mother_tongues') ? 'active' : '' ?>">
      <span class="icon">🗣️</span> Mother Tongues
    </a>
    <a href="manage_table.php?table=states" class="nav-item <?= (($_GET['table'] ?? '') === 'states') ? 'active' : '' ?>">
      <span class="icon">🗺️</span> States
    </a>
    <a href="manage_table.php?table=education_levels" class="nav-item <?= (($_GET['table'] ?? '') === 'education_levels') ? 'active' : '' ?>">
      <span class="icon">🎓</span> Education
    </a>
    <a href="manage_table.php?table=income_ranges" class="nav-item <?= (($_GET['table'] ?? '') === 'income_ranges') ? 'active' : '' ?>">
      <span class="icon">💰</span> Income Ranges
    </a>
    <a href="manage_table.php?table=marital_statuses" class="nav-item <?= (($_GET['table'] ?? '') === 'marital_statuses') ? 'active' : '' ?>">
      <span class="icon">💍</span> Marital Status
    </a>
    <a href="manage_table.php?table=profile_for_options" class="nav-item <?= (($_GET['table'] ?? '') === 'profile_for_options') ? 'active' : '' ?>">
      <span class="icon">👤</span> Profile For
    </a>
    <a href="manage_table.php?table=heights" class="nav-item <?= (($_GET['table'] ?? '') === 'heights') ? 'active' : '' ?>">
      <span class="icon">📏</span> Heights
    </a>
    <a href="manage_table.php?table=eating_habits" class="nav-item <?= (($_GET['table'] ?? '') === 'eating_habits') ? 'active' : '' ?>">
      <span class="icon">🍽️</span> Eating Habits
    </a>
    <a href="manage_table.php?table=smoking_habits" class="nav-item <?= (($_GET['table'] ?? '') === 'smoking_habits') ? 'active' : '' ?>">
      <span class="icon">🚬</span> Smoking Habits
    </a>
    <a href="manage_table.php?table=drinking_habits" class="nav-item <?= (($_GET['table'] ?? '') === 'drinking_habits') ? 'active' : '' ?>">
      <span class="icon">🍺</span> Drinking Habits
    </a>
    <a href="manage_table.php?table=body_types" class="nav-item <?= (($_GET['table'] ?? '') === 'body_types') ? 'active' : '' ?>">
      <span class="icon">💪</span> Body Types
    </a>
    <a href="manage_table.php?table=complexions" class="nav-item <?= (($_GET['table'] ?? '') === 'complexions') ? 'active' : '' ?>">
      <span class="icon">🎨</span> Complexions
    </a>
    <a href="manage_table.php?table=blood_groups" class="nav-item <?= (($_GET['table'] ?? '') === 'blood_groups') ? 'active' : '' ?>">
      <span class="icon">🩸</span> Blood Groups
    </a>
    <a href="manage_table.php?table=disabilities" class="nav-item <?= (($_GET['table'] ?? '') === 'disabilities') ? 'active' : '' ?>">
      <span class="icon">♿</span> Disabilities
    </a>
    <a href="manage_table.php?table=country_codes" class="nav-item <?= (($_GET['table'] ?? '') === 'country_codes') ? 'active' : '' ?>">
      <span class="icon">🌍</span> Country Codes
    </a>
    <a href="manage_table.php?table=upgrade_plans" class="nav-item <?= (($_GET['table'] ?? '') === 'upgrade_plans') ? 'active' : '' ?>">
      <span class="icon">💎</span> Upgrade Plans
    </a>
    <a href="manage_table.php?table=upgrade_features" class="nav-item <?= (($_GET['table'] ?? '') === 'upgrade_features') ? 'active' : '' ?>">
      <span class="icon">⭐</span> Upgrade Features
    </a>
    <a href="manage_table.php?table=admins" class="nav-item <?= (($_GET['table'] ?? '') === 'admins') ? 'active' : '' ?>">
      <span class="icon">👑</span> Admins
    </a>
    <div class="nav-section">Content</div>
    <a href="content.php" class="nav-item <?= ($pageTitle ?? '') === 'App Content' ? 'active' : '' ?>">
      <span class="icon">📄</span> App Content
    </a>
    <a href="photos.php" class="nav-item <?= ($pageTitle ?? '') === 'Photos' ? 'active' : '' ?>">
      <span class="icon">🖼️</span> Photos
    </a>
    <a href="interactions.php" class="nav-item <?= ($pageTitle ?? '') === 'Interactions' ? 'active' : '' ?>">
      <span class="icon">💬</span> Interactions
    </a>
    <div class="nav-section">Settings</div>
    <a href="cashfree_settings.php" class="nav-item <?= ($pageTitle ?? '') === 'Payment Gateway' ? 'active' : '' ?>">
      <span class="icon">💳</span> Payment Gateway
    </a>
    <a href="settings.php" class="nav-item <?= ($pageTitle ?? '') === 'Settings' ? 'active' : '' ?>">
      <span class="icon">⚙️</span> Settings
    </a>
  </nav>
  <div class="sidebar-footer">
    <a href="logout.php" class="logout-btn">
      <span>🚪</span> Logout
    </a>
  </div>
</div>

<div class="main">
  <div class="topbar">
    <h1><?= $pageTitle ?? 'Admin' ?></h1>
    <span class="admin-badge">👑 <?= htmlspecialchars(currentAdmin()['name']) ?></span>
  </div>
  <div class="content">
