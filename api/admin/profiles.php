<?php
require_once 'config.php';
requireLogin();
$pageTitle='Profiles';
$db=getDB();

$search=trim($_GET['search']??'');
$gender=$_GET['gender']??'';
$page=max(1,(int)($_GET['page']??1));
$limit=20;$offset=($page-1)*$limit;

$conds=["p.full_name IS NOT NULL"];$params=[];
if($gender){$conds[]="p.gender=?";$params[]=$gender;}
if($search){$conds[]="(p.full_name LIKE ? OR u.phone LIKE ?)";$params[]="%$search%";$params[]="%$search%";}
$where="WHERE ".implode(" AND ",$conds);

$total=$db->prepare("SELECT COUNT(*) FROM user_profiles p JOIN users u ON u.id=p.user_id $where");
$total->execute($params);$totalCount=$total->fetchColumn();$totalPages=max(1,ceil($totalCount/$limit));

$stmt=$db->prepare("SELECT p.*,u.phone,u.country_code,u.is_verified,r.name as religion,s.name as state,el.name as education,ir.name as income FROM user_profiles p JOIN users u ON u.id=p.user_id LEFT JOIN user_religion ur ON ur.user_id=p.user_id LEFT JOIN religions r ON r.id=ur.religion_id LEFT JOIN user_location ul ON ul.user_id=p.user_id LEFT JOIN states s ON s.id=ul.state_id LEFT JOIN user_education ue ON ue.user_id=p.user_id LEFT JOIN education_levels el ON el.id=ue.education_id LEFT JOIN income_ranges ir ON ir.id=ue.income_id $where ORDER BY p.updated_at DESC LIMIT $limit OFFSET $offset");
$stmt->execute($params);$profiles=$stmt->fetchAll();

include 'layout.php';
?>

<div class="card">
  <div class="card-header">
    <h2>Profiles <span class="badge bg-blue" style="font-size:13px"><?=$totalCount?></span></h2>
    <form method="GET" style="display:flex;gap:8px;flex-wrap:wrap;align-items:center">
      <div class="search-wrap">
        <span class="s-ico">🔍</span>
        <input type="text" name="search" class="form-control" placeholder="Search name or phone..." value="<?=htmlspecialchars($search)?>" style="padding-left:34px;width:210px">
      </div>
      <select name="gender" class="form-control" style="width:140px" onchange="this.form.submit()">
        <option value="">All Genders</option>
        <option value="Male" <?=$gender==='Male'?'selected':''?>>👨 Male</option>
        <option value="Female" <?=$gender==='Female'?'selected':''?>>👩 Female</option>
        <option value="Other" <?=$gender==='Other'?'selected':''?>>Other</option>
      </select>
      <button type="submit" class="btn btn-primary btn-sm">Filter</button>
      <?php if($search||$gender):?><a href="profiles.php" class="btn btn-secondary btn-sm">Clear</a><?php endif;?>
    </form>
  </div>
  <div class="tbl-scroll">
    <table>
      <thead><tr><th>#</th><th>Profile</th><th>Phone</th><th>Religion</th><th>State</th><th>Education</th><th>Income</th><th>Status</th><th>Action</th></tr></thead>
      <tbody>
        <?php foreach($profiles as $i=>$p):?>
        <tr>
          <td style="color:#9ca3af;font-size:12px"><?=$offset+$i+1?></td>
          <td>
            <div style="display:flex;align-items:center;gap:10px">
              <div class="avatar">
                <?php if($p['profile_photo']):?><img src="../uploads/<?=htmlspecialchars($p['profile_photo'])?>"><?php else:?><?=strtoupper(substr($p['full_name'],0,1))?><?php endif;?>
              </div>
              <div>
                <div style="font-weight:600"><?=htmlspecialchars($p['full_name'])?></div>
                <div style="font-size:11px;color:#9ca3af"><?=$p['gender']?> <?=$p['dob']?'· '.(date('Y')-date('Y',strtotime($p['dob']))).' yrs':''?></div>
              </div>
            </div>
          </td>
          <td style="color:#6b7280"><?=htmlspecialchars($p['country_code'].' '.$p['phone'])?></td>
          <td><?=$p['religion']??'—'?></td>
          <td><?=$p['state']??'—'?></td>
          <td><?=$p['education']??'—'?></td>
          <td><?=$p['income']??'—'?></td>
          <td><span class="badge <?=$p['is_profile_complete']?'bg-green':'bg-orange'?>"><?=$p['is_profile_complete']?'Complete':'Incomplete'?></span></td>
          <td><a href="user_detail.php?id=<?=$p['user_id']?>" class="btn btn-info btn-sm">View</a></td>
        </tr>
        <?php endforeach;?>
        <?php if(empty($profiles)):?>
        <tr><td colspan="9"><div class="empty"><div class="e-ico">👤</div><p>No profiles found</p></div></td></tr>
        <?php endif;?>
      </tbody>
    </table>
  </div>
  <?php if($totalPages>1):?>
  <div class="pagination">
    <a href="?page=<?=$page-1?>&search=<?=urlencode($search)?>&gender=<?=urlencode($gender)?>" class="pg-btn <?=$page<=1?'disabled':''?>">‹</a>
    <?php for($p2=max(1,$page-2);$p2<=min($totalPages,$page+2);$p2++) echo '<a href="?page='.$p2.'&search='.urlencode($search).'&gender='.urlencode($gender).'" class="pg-btn '.($p2===$page?'active':'').'">'.$p2.'</a>';?>
    <a href="?page=<?=$page+1?>&search=<?=urlencode($search)?>&gender=<?=urlencode($gender)?>" class="pg-btn <?=$page>=$totalPages?'disabled':''?>">›</a>
    <span style="font-size:12px;color:#9ca3af;margin-left:8px"><?=$totalCount?> total profiles</span>
  </div>
  <?php endif;?>
</div>

<?php include 'layout_end.php';?>
