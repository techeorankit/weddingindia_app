<?php
require_once 'config.php';
requireLogin();
$pageTitle='Photos';
$db=getDB();

if(isset($_GET['delete'])&&is_numeric($_GET['delete'])){
    $ph=$db->prepare("SELECT photo_path FROM user_photos WHERE id=?");
    $ph->execute([$_GET['delete']]);$ph=$ph->fetch();
    if($ph){$f=__DIR__.'/../uploads/'.$ph['photo_path'];if(file_exists($f))unlink($f);$db->prepare("DELETE FROM user_photos WHERE id=?")->execute([$_GET['delete']]);}
    header('Location: photos.php?msg=deleted');exit();
}

$page=max(1,(int)($_GET['page']??1));$limit=30;$offset=($page-1)*$limit;
$total=$db->query("SELECT COUNT(*) FROM user_photos")->fetchColumn();
$totalPages=max(1,ceil($total/$limit));

$stmt=$db->prepare("SELECT up.*,p.full_name,u.phone FROM user_photos up JOIN users u ON u.id=up.user_id LEFT JOIN user_profiles p ON p.user_id=up.user_id ORDER BY up.created_at DESC LIMIT $limit OFFSET $offset");
$stmt->execute();$photos=$stmt->fetchAll();

include 'layout.php';
?>

<?php if(isset($_GET['msg'])):?><div class="alert alert-success">✅ Photo deleted successfully</div><?php endif;?>

<div class="card">
  <div class="card-header">
    <h2>All Photos <span class="badge bg-blue" style="font-size:13px"><?=$total?></span></h2>
    <span style="font-size:13px;color:#9ca3af">Page <?=$page?> of <?=$totalPages?></span>
  </div>
  <div style="padding:20px">
    <?php if(empty($photos)):?>
    <div class="empty"><div class="e-ico">🖼️</div><p>No photos uploaded yet</p></div>
    <?php else:?>
    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:16px">
      <?php foreach($photos as $ph):?>
      <div style="border-radius:12px;overflow:hidden;border:1px solid #eaecf0;background:#fff;box-shadow:0 1px 4px rgba(0,0,0,.05);transition:transform .15s" onmouseover="this.style.transform='translateY(-3px)'" onmouseout="this.style.transform=''">
        <div style="position:relative">
          <img src="../uploads/<?=htmlspecialchars($ph['photo_path'])?>" style="width:100%;aspect-ratio:1;object-fit:cover;display:block" onerror="this.src='https://placehold.co/180x180?text=No+Image'">
          <?php if($ph['is_primary']):?><span style="position:absolute;top:8px;left:8px;background:#e91e63;color:#fff;font-size:10px;padding:2px 8px;border-radius:8px;font-weight:700">★ Primary</span><?php endif;?>
        </div>
        <div style="padding:10px">
          <div style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:#1a1a2e"><?=htmlspecialchars($ph['full_name']??$ph['phone'])?></div>
          <div style="font-size:11px;color:#9ca3af;margin-top:2px"><?=date('d M Y',strtotime($ph['created_at']))?></div>
          <div style="display:flex;gap:6px;margin-top:8px">
            <a href="user_detail.php?id=<?=$ph['user_id']?>" class="btn btn-info btn-sm" style="flex:1;justify-content:center">View</a>
            <a href="photos.php?delete=<?=$ph['id']?>" class="btn btn-danger btn-sm" onclick="return confirm('Delete this photo?')">🗑</a>
          </div>
        </div>
      </div>
      <?php endforeach;?>
    </div>
    <?php endif;?>
  </div>
  <?php if($totalPages>1):?>
  <div class="pagination">
    <a href="?page=<?=$page-1?>" class="pg-btn <?=$page<=1?'disabled':''?>">‹ Prev</a>
    <?php for($p=max(1,$page-2);$p<=min($totalPages,$page+2);$p++) echo '<a href="?page='.$p.'" class="pg-btn '.($p===$page?'active':'').'">'.$p.'</a>';?>
    <a href="?page=<?=$page+1?>" class="pg-btn <?=$page>=$totalPages?'disabled':''?>">Next ›</a>
  </div>
  <?php endif;?>
</div>

<?php include 'layout_end.php';?>
