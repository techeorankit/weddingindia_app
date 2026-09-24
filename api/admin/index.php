<?php
require_once 'config.php';
if(isLoggedIn()){header('Location: dashboard.php');exit();}
$error='';
if($_SERVER['REQUEST_METHOD']==='POST'){
    $admin=checkAdminLogin($_POST['username']??'',$_POST['password']??'');
    if($admin){
        $_SESSION['admin_logged_in']=true;
        $_SESSION['admin_data']=$admin;
        header('Location: dashboard.php');exit();
    }
    $error='Invalid username or password';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Wedding India — Admin Login</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{min-height:100vh;font-family:'Segoe UI',system-ui,sans-serif;background:linear-gradient(135deg,#1a1a2e 0%,#16213e 50%,#0f3460 100%);display:flex;align-items:center;justify-content:center;padding:20px}
.wrap{display:flex;width:100%;max-width:900px;border-radius:24px;overflow:hidden;box-shadow:0 30px 80px rgba(0,0,0,.4)}
.left{flex:1;background:linear-gradient(135deg,#e91e63,#c2185b,#880e4f);padding:50px 40px;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center}
.left .big-icon{font-size:72px;margin-bottom:20px;filter:drop-shadow(0 8px 16px rgba(0,0,0,.3))}
.left h1{color:#fff;font-size:28px;font-weight:800;margin-bottom:10px}
.left p{color:rgba(255,255,255,.7);font-size:14px;line-height:1.6;max-width:260px}
.left .features{margin-top:32px;display:flex;flex-direction:column;gap:12px;width:100%}
.left .feat{display:flex;align-items:center;gap:10px;background:rgba(255,255,255,.12);border-radius:10px;padding:10px 14px;color:rgba(255,255,255,.85);font-size:13px}
.right{width:400px;background:#fff;padding:50px 40px;display:flex;flex-direction:column;justify-content:center}
.right .logo{text-align:center;margin-bottom:32px}
.right .logo .ico{width:60px;height:60px;background:linear-gradient(135deg,#e91e63,#c2185b);border-radius:16px;display:inline-flex;align-items:center;justify-content:center;font-size:28px;margin-bottom:12px;box-shadow:0 6px 20px rgba(233,30,99,.35)}
.right .logo h2{font-size:20px;font-weight:800;color:#1a1a2e}
.right .logo p{color:#9ca3af;font-size:13px;margin-top:3px}
.form-group{margin-bottom:18px}
label{display:block;font-size:12.5px;font-weight:700;color:#374151;margin-bottom:7px;text-transform:uppercase;letter-spacing:.5px}
input{width:100%;padding:12px 16px;border:1.5px solid #e5e7eb;border-radius:11px;font-size:14px;outline:none;transition:all .2s;color:#1a1a2e}
input:focus{border-color:#e91e63;box-shadow:0 0 0 3px rgba(233,30,99,.1)}
.btn-login{width:100%;padding:13px;background:linear-gradient(135deg,#e91e63,#c2185b);color:#fff;border:none;border-radius:11px;font-size:15px;font-weight:700;cursor:pointer;transition:all .2s;box-shadow:0 4px 16px rgba(233,30,99,.35);margin-top:4px}
.btn-login:hover{transform:translateY(-1px);box-shadow:0 8px 24px rgba(233,30,99,.4)}
.err{background:#fee2e2;color:#991b1b;border:1px solid #fecaca;border-radius:10px;padding:11px 14px;font-size:13px;margin-bottom:18px;display:flex;align-items:center;gap:8px}
.hint{text-align:center;margin-top:20px;font-size:12px;color:#9ca3af}
@media(max-width:700px){.left{display:none}.right{width:100%;border-radius:24px}}
</style>
</head>
<body>
<div class="wrap">
  <div class="left">
    <div class="big-icon">💍</div>
    <h1>Wedding India</h1>
    <p>Complete matrimonial platform management system</p>
    <div class="features">
      <div class="feat">📊 Real-time dashboard & analytics</div>
      <div class="feat">👥 User & profile management</div>
      <div class="feat">💎 Subscription plan control</div>
      <div class="feat">🗄️ Full database access</div>
    </div>
  </div>
  <div class="right">
    <div class="logo">
      <div class="ico">💍</div>
      <h2>Admin Login</h2>
      <p>Sign in to your admin account</p>
    </div>
    <?php if($error):?><div class="err">⚠️ <?=htmlspecialchars($error)?></div><?php endif;?>
    <form method="POST">
      <div class="form-group">
        <label>Username</label>
        <input type="text" name="username" placeholder="Enter username" required autofocus autocomplete="username">
      </div>
      <div class="form-group">
        <label>Password</label>
        <input type="password" name="password" placeholder="Enter password" required autocomplete="current-password">
      </div>
      <button type="submit" class="btn-login">🔐 Sign In to Admin Panel</button>
    </form>
    <div class="hint">Wedding India Admin Panel &copy; <?=date('Y')?></div>
  </div>
</div>
</body>
</html>
