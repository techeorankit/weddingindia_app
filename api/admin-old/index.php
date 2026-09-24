<?php
require_once 'config.php';

if (isLoggedIn()) {
    header('Location: dashboard.php');
    exit();
}

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $admin = checkAdminLogin($_POST['username'] ?? '', $_POST['password'] ?? '');
    if ($admin) {
        $_SESSION['admin_logged_in'] = true;
        $_SESSION['admin_data'] = $admin;
        header('Location: dashboard.php');
        exit();
    }
    $error = 'Invalid username or password';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Wedding India - Admin Login</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    min-height: 100vh;
    background: linear-gradient(135deg, #E91E63 0%, #AD1457 100%);
    display: flex; align-items: center; justify-content: center;
    font-family: 'Segoe UI', sans-serif;
  }
  .card {
    background: #fff;
    border-radius: 20px;
    padding: 48px 40px;
    width: 100%; max-width: 400px;
    box-shadow: 0 20px 60px rgba(0,0,0,0.2);
  }
  .logo { text-align: center; margin-bottom: 32px; }
  .logo-icon {
    width: 72px; height: 72px;
    background: linear-gradient(135deg, #E91E63, #AD1457);
    border-radius: 50%; display: inline-flex;
    align-items: center; justify-content: center;
    font-size: 32px; margin-bottom: 12px;
  }
  .logo h1 { font-size: 22px; color: #1a1a1a; font-weight: 700; }
  .logo p { color: #888; font-size: 13px; margin-top: 4px; }
  .form-group { margin-bottom: 20px; }
  label { display: block; font-size: 13px; font-weight: 600; color: #444; margin-bottom: 8px; }
  input {
    width: 100%; padding: 13px 16px;
    border: 1.5px solid #e0e0e0; border-radius: 12px;
    font-size: 15px; outline: none; transition: border-color .2s;
  }
  input:focus { border-color: #E91E63; }
  .btn {
    width: 100%; padding: 14px;
    background: linear-gradient(135deg, #E91E63, #AD1457);
    color: #fff; border: none; border-radius: 12px;
    font-size: 16px; font-weight: 600; cursor: pointer;
    transition: opacity .2s;
  }
  .btn:hover { opacity: .9; }
  .error {
    background: #ffeef2; color: #c62828;
    border: 1px solid #ffcdd2; border-radius: 10px;
    padding: 12px 16px; font-size: 13px; margin-bottom: 20px;
  }
</style>
</head>
<body>
<div class="card">
  <div class="logo">
    <div class="logo-icon">💍</div>
    <h1>Wedding India</h1>
    <p>Admin Panel</p>
  </div>
  <?php if ($error): ?>
    <div class="error">⚠️ <?= htmlspecialchars($error) ?></div>
  <?php endif; ?>
  <form method="POST">
    <div class="form-group">
      <label>Username</label>
      <input type="text" name="username" placeholder="Enter username" required autofocus>
    </div>
    <div class="form-group">
      <label>Password</label>
      <input type="password" name="password" placeholder="Enter password" required>
    </div>
    <button type="submit" class="btn">Login to Admin Panel</button>
  </form>
</div>
</body>
</html>
