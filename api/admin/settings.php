<?php
require_once 'config.php';
requireLogin();
$pageTitle='Settings';
$db=getDB();
$msg='';$err='';

// Password change
if($_SERVER['REQUEST_METHOD']==='POST'&&($_POST['action']??'')==='change_password'){
    $admin=currentAdmin();
    $row=$db->prepare("SELECT password FROM admins WHERE id=?");$row->execute([$admin['id']]);$row=$row->fetch();
    if(!$row||!password_verify($_POST['current']??'',$row['password'])){$err='Current password is incorrect.';}
    elseif(strlen($_POST['new_pass']??'')<6){$err='New password must be at least 6 characters.';}
    elseif(($_POST['new_pass']??'')!==($_POST['confirm_pass']??'')){$err='Passwords do not match.';}
    else{
        $db->prepare("UPDATE admins SET password=? WHERE id=?")->execute([password_hash($_POST['new_pass'],PASSWORD_BCRYPT),$admin['id']]);
        $msg='Password updated! Please login again.';
        session_destroy();header('refresh:2;url=index.php');
    }
}

// Lookup table CRUD
$lookupTables=[
    'religions'=>['name'],'states'=>['name'],'marital_statuses'=>['name'],
    'education_levels'=>['name'],'income_ranges'=>['name'],'mother_tongues'=>['name'],
    'eating_habits'=>['name'],'smoking_habits'=>['name'],'drinking_habits'=>['name'],
    'body_types'=>['name'],'complexions'=>['name'],'blood_groups'=>['name'],
    'disabilities'=>['name'],'profile_for_options'=>['name'],
];
$activeLookup=$_GET['lookup']??'';
$lookupRows=[];
if($activeLookup&&isset($lookupTables[$activeLookup])){
    // Add
    if($_SERVER['REQUEST_METHOD']==='POST'&&($_POST['action']??'')==='add_lookup'){
        $n=trim($_POST['name']??'');
        if($n){$db->prepare("INSERT INTO `$activeLookup`(name,sort_order,is_active) VALUES(?,?,1)")->execute([$n,(int)($_POST['sort_order']??0)]);}
        header("Location: settings.php?lookup=$activeLookup&msg=added");exit();
    }
    // Delete
    if(isset($_GET['del_lookup'])&&is_numeric($_GET['del_lookup'])){
        $db->prepare("DELETE FROM `$activeLookup` WHERE id=?")->execute([$_GET['del_lookup']]);
        header("Location: settings.php?lookup=$activeLookup&msg=deleted");exit();
    }
    // Toggle
    if(isset($_GET['tog_lookup'])&&is_numeric($_GET['tog_lookup'])){
        $db->prepare("UPDATE `$activeLookup` SET is_active=1-is_active WHERE id=?")->execute([$_GET['tog_lookup']]);
        header("Location: settings.php?lookup=$activeLookup");exit();
    }
    $lookupRows=$db->query("SELECT * FROM `$activeLookup` ORDER BY sort_order,id")->fetchAll();
}

include 'layout.php';
?>

<?php if($msg):?><div class="alert alert-success">✅ <?=htmlspecialchars($msg)?></div><?php endif;?>
<?php if($err):?><div class="alert alert-error">⚠️ <?=htmlspecialchars($err)?></div><?php endif;?>
<?php if(isset($_GET['msg'])&&!$msg):?><div class="alert alert-success">✅ Done!</div><?php endif;?>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:24px">

  <!-- Password Change -->
  <div class="card card-body">
    <div class="sec-title">🔐 Change Password</div>
    <form method="POST">
      <input type="hidden" name="action" value="change_password">
      <div class="form-group"><label>Current Password</label><input type="password" name="current" class="form-control" required></div>
      <div class="form-group"><label>New Password</label><input type="password" name="new_pass" class="form-control" required minlength="6"></div>
      <div class="form-group"><label>Confirm New Password</label><input type="password" name="confirm_pass" class="form-control" required></div>
      <button type="submit" class="btn btn-primary" style="width:100%">🔒 Update Password</button>
    </form>
  </div>

  <!-- Admin Info -->
  <div class="card card-body">
    <div class="sec-title">👑 Admin Info</div>
    <div class="info-row"><span class="lbl">Username</span><span class="val"><?=htmlspecialchars(currentAdmin()['username'])?></span></div>
    <div class="info-row"><span class="lbl">Name</span><span class="val"><?=htmlspecialchars(currentAdmin()['name'])?></span></div>
    <div class="info-row"><span class="lbl">Panel Version</span><span class="val">2.0.0</span></div>
    <div class="info-row"><span class="lbl">App</span><span class="val">Wedding India</span></div>
    <div class="info-row"><span class="lbl">PHP Version</span><span class="val"><?=PHP_VERSION?></span></div>
    <div class="info-row"><span class="lbl">Server Time</span><span class="val"><?=date('d M Y, h:i A')?></span></div>
  </div>
</div>

<!-- Lookup Table Manager -->
<div class="card" style="margin-bottom:20px">
  <div class="card-header"><h2>📋 Lookup Table Manager</h2></div>
  <div style="padding:16px 22px;display:flex;gap:8px;flex-wrap:wrap;border-bottom:1px solid #f0f2f5">
    <?php foreach(array_keys($lookupTables) as $t):?>
    <a href="settings.php?lookup=<?=$t?>" class="btn btn-sm <?=$activeLookup===$t?'btn-primary':'btn-secondary'?>"><?=$t?></a>
    <?php endforeach;?>
  </div>

  <?php if($activeLookup&&isset($lookupTables[$activeLookup])):?>
  <div style="padding:16px 22px;border-bottom:1px solid #f0f2f5">
    <form method="POST" style="display:flex;gap:10px;align-items:flex-end;flex-wrap:wrap">
      <input type="hidden" name="action" value="add_lookup">
      <div class="form-group" style="margin:0;flex:1;min-width:180px">
        <label>Add New Entry to <strong><?=$activeLookup?></strong></label>
        <input type="text" name="name" class="form-control" placeholder="Enter name..." required>
      </div>
      <div class="form-group" style="margin:0;width:100px">
        <label>Sort Order</label>
        <input type="number" name="sort_order" class="form-control" value="0">
      </div>
      <button type="submit" class="btn btn-primary">➕ Add</button>
    </form>
  </div>
  <div class="tbl-scroll">
    <table>
      <thead><tr><th>ID</th><th>Name</th><th>Sort</th><th>Status</th><th>Actions</th></tr></thead>
      <tbody>
        <?php foreach($lookupRows as $r):?>
        <tr>
          <td style="color:#9ca3af"><?=$r['id']?></td>
          <td style="font-weight:600"><?=htmlspecialchars($r['name'])?></td>
          <td><?=$r['sort_order']?></td>
          <td><span class="badge <?=$r['is_active']?'bg-green':'bg-red'?>"><?=$r['is_active']?'Active':'Inactive'?></span></td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="settings.php?lookup=<?=$activeLookup?>&tog_lookup=<?=$r['id']?>" class="btn btn-sm <?=$r['is_active']?'btn-danger':'btn-success'?>"><?=$r['is_active']?'Disable':'Enable'?></a>
              <a href="settings.php?lookup=<?=$activeLookup?>&del_lookup=<?=$r['id']?>" class="btn btn-danger btn-sm" onclick="return confirm('Delete this entry?')">🗑</a>
            </div>
          </td>
        </tr>
        <?php endforeach;?>
        <?php if(empty($lookupRows)):?><tr><td colspan="5" style="text-align:center;color:#9ca3af;padding:30px">No entries found</td></tr><?php endif;?>
      </tbody>
    </table>
  </div>
  <?php else:?>
  <div class="empty"><div class="e-ico">📋</div><p>Select a lookup table above to manage its entries</p></div>
  <?php endif;?>
</div>

<?php include 'layout_end.php';?>
