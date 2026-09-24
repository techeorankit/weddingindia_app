<?php
require_once 'config.php';
requireLogin();
$pageTitle='Interactions';
$db=getDB();

$type=$_GET['type']??'';
$page=max(1,(int)($_GET['page']??1));
$limit=25;$offset=($page-1)*$limit;

$where=$type?"WHERE ui.type=?":"";
$params=$type?[$type]:[];

$total=$db->prepare("SELECT COUNT(*) FROM user_interactions ui $where");
$total->execute($params);$totalCount=$total->fetchColumn();$totalPages=max(1,ceil($totalCount/$limit));

try{
    $stmt=$db->prepare("SELECT ui.*,p1.full_name as fn,u1.phone as fp,p2.full_name as tn,u2.phone as tp FROM user_interactions ui JOIN users u1 ON u1.id=ui.from_user_id LEFT JOIN user_profiles p1 ON p1.user_id=ui.from_user_id JOIN users u2 ON u2.id=ui.to_user_id LEFT JOIN user_profiles p2 ON p2.user_id=ui.to_user_id $where ORDER BY ui.created_at DESC LIMIT $limit OFFSET $offset");
    $stmt->execute($params);$rows=$stmt->fetchAll();
}catch(Exception $e){$rows=[];}

$typeCounts=[];
try{$tc=$db->query("SELECT type,COUNT(*) as c FROM user_interactions GROUP BY type")->fetchAll();foreach($tc as $t)$typeCounts[$t['type']]=$t['c'];}catch(Exception $e){}

include 'layout.php';
?>

<style>
.type-cards{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:22px}
.tc{display:flex;align-items:center;gap:10px;padding:14px 20px;border-radius:12px;text-decoration:none;background:#fff;border:2px solid transparent;box-shadow:0 1px 4px rgba(0,0,0,.06);transition:all .15s;min-width:130px}
.tc:hover{transform:translateY(-2px);box-shadow:0 4px 16px rgba(0,0,0,.1)}
.tc.active{border-color:#e91e63;background:#fce4ec}
.tc .tc-ico{font-size:22px}
.tc .tc-info h4{font-size:18px;font-weight:800;color:#1a1a2e}
.tc .tc-info p{font-size:11px;color:#9ca3af;margin-top:1px}
</style>

<!-- Type Filter Cards -->
<div class="type-cards">
  <?php
  $types=['interest'=>['❤️','Interests'],'shortlist'=>['⭐','Shortlists'],'ignore'=>['🚫','Ignores'],'chat'=>['💬','Chats']];
  foreach($types as $t=>[$ico,$lbl]):?>
  <a href="?type=<?=$t?>" class="tc <?=$type===$t?'active':''?>">
    <div class="tc-ico"><?=$ico?></div>
    <div class="tc-info"><h4><?=$typeCounts[$t]??0?></h4><p><?=$lbl?></p></div>
  </a>
  <?php endforeach;?>
  <?php if($type):?><a href="interactions.php" class="tc" style="border-color:#e5e7eb"><div class="tc-ico">🔄</div><div class="tc-info"><h4>All</h4><p>Clear Filter</p></div></a><?php endif;?>
</div>

<div class="card">
  <div class="card-header">
    <h2><?=$type?ucfirst($type).'s':'All Interactions'?> <span class="badge bg-blue" style="font-size:13px"><?=$totalCount?></span></h2>
  </div>
  <div class="tbl-scroll">
    <table>
      <thead><tr><th>From User</th><th>Action</th><th>To User</th><th>Date & Time</th></tr></thead>
      <tbody>
        <?php
        $tbadge=['interest'=>'bg-red','shortlist'=>'bg-purple','ignore'=>'bg-gray','chat'=>'bg-green'];
        $ticon=['interest'=>'❤️','shortlist'=>'⭐','ignore'=>'🚫','chat'=>'💬'];
        foreach($rows as $r):?>
        <tr>
          <td>
            <div style="font-weight:600"><?=htmlspecialchars($r['fn']??'Unknown')?></div>
            <div style="font-size:11px;color:#9ca3af"><?=$r['fp']?></div>
          </td>
          <td><span class="badge <?=$tbadge[$r['type']]??'bg-gray'?>"><?=($ticon[$r['type']]??'').' '.ucfirst($r['type'])?></span></td>
          <td>
            <div style="font-weight:600"><?=htmlspecialchars($r['tn']??'Unknown')?></div>
            <div style="font-size:11px;color:#9ca3af"><?=$r['tp']?></div>
          </td>
          <td style="color:#9ca3af;font-size:13px"><?=date('d M Y, h:i A',strtotime($r['created_at']))?></td>
        </tr>
        <?php endforeach;?>
        <?php if(empty($rows)):?>
        <tr><td colspan="4"><div class="empty"><div class="e-ico">💬</div><p>No interactions found</p></div></td></tr>
        <?php endif;?>
      </tbody>
    </table>
  </div>
  <?php if($totalPages>1):?>
  <div class="pagination">
    <a href="?page=<?=$page-1?>&type=<?=urlencode($type)?>" class="pg-btn <?=$page<=1?'disabled':''?>">‹</a>
    <?php for($p=max(1,$page-2);$p<=min($totalPages,$page+2);$p++) echo '<a href="?page='.$p.'&type='.urlencode($type).'" class="pg-btn '.($p===$page?'active':'').'">'.$p.'</a>';?>
    <a href="?page=<?=$page+1?>&type=<?=urlencode($type)?>" class="pg-btn <?=$page>=$totalPages?'disabled':''?>">›</a>
  </div>
  <?php endif;?>
</div>

<?php include 'layout_end.php';?>
