<?php
require_once 'config.php';
requireLogin();
$pageTitle='Users';
$db=getDB();

// CSV Export
if(isset($_GET['export'])){
    header('Content-Type: text/csv');
    header('Content-Disposition: attachment; filename="users_'.date('Y-m-d').'.csv"');
    $out=fopen('php://output','w');
    fputcsv($out,['ID','Name','Phone','Gender','Verified','Profile Complete','Joined']);
    $all=$db->query("SELECT u.id,p.full_name,CONCAT(u.country_code,' ',u.phone) as phone,p.gender,u.is_verified,p.is_profile_complete,u.created_at FROM users u LEFT JOIN user_profiles p ON p.user_id=u.id ORDER BY u.created_at DESC")->fetchAll();
    foreach($all as $r) fputcsv($out,[$r['id'],$r['full_name'],$r['phone'],$r['gender'],$r['is_verified']?'Yes':'No',$r['is_profile_complete']?'Yes':'No',$r['created_at']]);
    fclose($out);exit();
}

// Delete
if(isset($_GET['delete'])&&is_numeric($_GET['delete'])){
    $db->prepare("DELETE FROM users WHERE id=?")->execute([$_GET['delete']]);
    header('Location: users.php?msg=deleted');exit();
}

// Toggle verify
if(isset($_GET['toggle'])&&is_numeric($_GET['toggle'])){
    $db->prepare("UPDATE users SET is_verified=1-is_verified WHERE id=?")->execute([$_GET['toggle']]);
    header('Location: users.php?msg=updated');exit();
}

$search=trim($_GET['search']??'');
$filter=$_GET['filter']??'';
$page=max(1,(int)($_GET['page']??1));
$limit=20;$offset=($page-1)*$limit;

$conds=[];$params=[];
if($search){$conds[]="(u.phone LIKE ? OR p.full_name LIKE ?)";$params[]="%$search%";$params[]="%$search%";}
if($filter==='verified'){$conds[]="u.is_verified=1";}
elseif($filter==='unverified'){$conds[]="u.is_verified=0";}
elseif($filter==='complete'){$conds[]="p.is_profile_complete=1";}
$where=$conds?"WHERE ".implode(" AND ",$conds):"";

$total=$db->prepare("SELECT COUNT(*) FROM users u LEFT JOIN user_profiles p ON p.user_id=u.id $where");
$total->execute($params);
$totalCount=$total->fetchColumn();
$totalPages=max(1,ceil($totalCount/$limit));

$stmt=$db->prepare("SELECT u.id,u.phone,u.country_code,u.is_verified,u.created_at,p.full_name,p.gender,p.profile_photo,p.is_profile_complete FROM users u LEFT JOIN user_profiles p ON p.user_id=u.id $where ORDER BY u.created_at DESC LIMIT $limit OFFSET $offset");
$stmt->execute($params);
$users=$stmt->fetchAll();

include 'layout.php';
?>

<?php if(isset($_GET['msg'])):?>
<div class="alert alert-success">✅ <?=$_GET['msg']==='deleted'?'User deleted successfully':'User updated successfully'?></div>
<?php endif;?>

<div class="card">
  <div class="card-header">
    <h2>All Users <span class="badge bg-blue" style="font-size:13px"><?=$totalCount?></span></h2>
    <div style="display:flex;gap:10px;flex-wrap:wrap;align-items:center">
      <form method="GET" style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
        <div class="search-wrap">
          <span class="s-ico">🔍</span>
          <input type="text" name="search" class="form-control" placeholder="Search name or phone..." value="<?=htmlspecialchars($search)?>" style="padding-left:34px;width:220px">
        </div>
        <select name="filter" class="form-control" style="width:150px" onchange="this.form.submit()">
          <option value="">All Users</option>
          <option value="verified" <?=$filter==='verified'?'selected':''?>>✅ Verified</option>
          <option value="unverified" <?=$filter==='unverified'?'selected':''?>>⏳ Unverified</option>
          <option value="complete" <?=$filter==='complete'?'selected':''?>>👤 Profile Complete</option>
        </select>
        <button type="submit" class="btn btn-primary btn-sm">Search</button>
        <?php if($search||$filter):?><a href="users.php" class="btn btn-secondary btn-sm">Clear</a><?php endif;?>
      </form>
      <a href="users.php?export=1" class="btn btn-success btn-sm">📥 Export CSV</a>
    </div>
  </div>
  <div class="tbl-scroll">
    <table>
      <thead>
        <tr><th>#</th><th>User</th><th>Phone</th><th>Gender</th><th>Profile</th><th>Verification</th><th>Joined</th><th>Actions</th></tr>
      </thead>
      <tbody>
        <?php foreach($users as $i=>$u):?>
        <tr>
          <td style="color:#9ca3af;font-size:12px"><?=$offset+$i+1?></td>
          <td>
            <div style="display:flex;align-items:center;gap:10px">
              <div class="avatar">
                <?php if($u['profile_photo']):?><img src="../uploads/<?=htmlspecialchars($u['profile_photo'])?>"><?php else:?><?=strtoupper(substr($u['full_name']??$u['phone'],0,1))?><?php endif;?>
              </div>
              <div>
                <div style="font-weight:600"><?=htmlspecialchars($u['full_name']??'No Name')?></div>
                <div style="font-size:11px;color:#9ca3af">ID #<?=$u['id']?></div>
              </div>
            </div>
          </td>
          <td style="color:#6b7280"><?=htmlspecialchars($u['country_code'].' '.$u['phone'])?></td>
          <td><?=$u['gender']??'—'?></td>
          <td><span class="badge <?=$u['is_profile_complete']?'bg-green':'bg-orange'?>"><?=$u['is_profile_complete']?'Complete':'Incomplete'?></span></td>
          <td>
            <a href="users.php?toggle=<?=$u['id']?>&search=<?=urlencode($search)?>&filter=<?=urlencode($filter)?>&page=<?=$page?>"
               class="badge <?=$u['is_verified']?'bg-green':'bg-red'?>" style="cursor:pointer;text-decoration:none" title="Click to toggle">
              <?=$u['is_verified']?'✅ Verified':'❌ Unverified'?>
            </a>
          </td>
          <td style="color:#9ca3af;font-size:13px"><?=date('d M Y',strtotime($u['created_at']))?></td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="user_detail.php?id=<?=$u['id']?>" class="btn btn-info btn-sm">👁 View</a>
              <a href="users.php?delete=<?=$u['id']?>&search=<?=urlencode($search)?>&filter=<?=urlencode($filter)?>&page=<?=$page?>"
                 class="btn btn-danger btn-sm" onclick="return confirm('Delete this user permanently?')">🗑</a>
            </div>
          </td>
        </tr>
        <?php endforeach;?>
        <?php if(empty($users)):?>
        <tr><td colspan="8"><div class="empty"><div class="e-ico">🔍</div><p>No users found</p></div></td></tr>
        <?php endif;?>
      </tbody>
    </table>
  </div>
  <?php if($totalPages>1):?>
  <div class="pagination">
    <a href="?page=<?=$page-1?>&search=<?=urlencode($search)?>&filter=<?=urlencode($filter)?>" class="pg-btn <?=$page<=1?'disabled':''?>">‹</a>
    <?php
    $start=max(1,$page-2);$end=min($totalPages,$page+2);
    if($start>1){echo '<a href="?page=1&search='.urlencode($search).'&filter='.urlencode($filter).'" class="pg-btn">1</a>';if($start>2)echo '<span class="pg-btn disabled">…</span>';}
    for($p=$start;$p<=$end;$p++) echo '<a href="?page='.$p.'&search='.urlencode($search).'&filter='.urlencode($filter).'" class="pg-btn '.($p===$page?'active':'').'">'.$p.'</a>';
    if($end<$totalPages){if($end<$totalPages-1)echo '<span class="pg-btn disabled">…</span>';echo '<a href="?page='.$totalPages.'&search='.urlencode($search).'&filter='.urlencode($filter).'" class="pg-btn">'.$totalPages.'</a>';}
    ?>
    <a href="?page=<?=$page+1?>&search=<?=urlencode($search)?>&filter=<?=urlencode($filter)?>" class="pg-btn <?=$page>=$totalPages?'disabled':''?>">›</a>
    <span style="font-size:12px;color:#9ca3af;margin-left:8px">Page <?=$page?> of <?=$totalPages?> &nbsp;·&nbsp; <?=$totalCount?> total</span>
  </div>
  <?php endif;?>
</div>

<?php include 'layout_end.php';?>
