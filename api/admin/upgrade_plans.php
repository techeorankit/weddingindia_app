<?php
require_once 'config.php';
requireLogin();
$pageTitle='Upgrade Plans';
$db=getDB();
$msg='';$err='';

if(isset($_GET['delete'])&&is_numeric($_GET['delete'])){
    $db->prepare("DELETE FROM upgrade_plans WHERE id=?")->execute([$_GET['delete']]);
    header('Location: upgrade_plans.php?msg=deleted');exit();
}
if(isset($_GET['toggle'])&&is_numeric($_GET['toggle'])){
    $db->prepare("UPDATE upgrade_plans SET is_active=1-is_active WHERE id=?")->execute([$_GET['toggle']]);
    header('Location: upgrade_plans.php?msg=updated');exit();
}

if($_SERVER['REQUEST_METHOD']==='POST'){
    $label=trim($_POST['label']??'');
    $price=trim($_POST['price']??'');
    $orig=trim($_POST['original_price']??'');
    $disc=trim($_POST['discount']??'');
    $best=isset($_POST['is_best_value'])?1:0;
    $sort=(int)($_POST['sort_order']??0);
    if(!$label||!$price){$err='Label and price are required.';}
    elseif(isset($_POST['edit_id'])&&is_numeric($_POST['edit_id'])){
        $db->prepare("UPDATE upgrade_plans SET label=?,price=?,original_price=?,discount=?,is_best_value=?,sort_order=? WHERE id=?")->execute([$label,$price,$orig,$disc,$best,$sort,$_POST['edit_id']]);
        header('Location: upgrade_plans.php?msg=updated');exit();
    }else{
        $db->prepare("INSERT INTO upgrade_plans(label,price,original_price,discount,is_best_value,sort_order,is_active) VALUES(?,?,?,?,?,?,1)")->execute([$label,$price,$orig,$disc,$best,$sort]);
        header('Location: upgrade_plans.php?msg=added');exit();
    }
}

$plans=$db->query("SELECT * FROM upgrade_plans ORDER BY sort_order,id")->fetchAll();
$features=$db->query("SELECT * FROM upgrade_features ORDER BY sort_order,id")->fetchAll();

$editPlan=null;
if(isset($_GET['edit'])&&is_numeric($_GET['edit'])){
    $ep=$db->prepare("SELECT * FROM upgrade_plans WHERE id=?");$ep->execute([$_GET['edit']]);$editPlan=$ep->fetch();
}

include 'layout.php';
?>

<style>
.plans-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:20px;margin-bottom:28px}
.plan-card{background:#fff;border-radius:16px;padding:24px;box-shadow:0 1px 4px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.04);border:2px solid #eaecf0;position:relative;transition:transform .15s,box-shadow .15s}
.plan-card:hover{transform:translateY(-3px);box-shadow:0 8px 28px rgba(0,0,0,.1)}
.plan-card.best{border-color:#e91e63}
.plan-card.inactive{opacity:.55}
.best-tag{position:absolute;top:-12px;left:50%;transform:translateX(-50%);background:#e91e63;color:#fff;font-size:11px;font-weight:700;padding:3px 14px;border-radius:20px;white-space:nowrap}
.plan-label{font-size:16px;font-weight:700;color:#1a1a2e;margin-bottom:8px}
.plan-price{font-size:34px;font-weight:900;color:#e91e63;line-height:1}
.plan-orig{font-size:14px;color:#9ca3af;text-decoration:line-through;margin-top:2px}
.plan-disc{display:inline-block;background:#dcfce7;color:#166534;font-size:12px;font-weight:700;padding:2px 10px;border-radius:20px;margin-top:6px}
.plan-actions{display:flex;gap:8px;margin-top:16px;flex-wrap:wrap}
</style>

<?php if(isset($_GET['msg'])):?>
<div class="alert alert-success">✅ <?=['added'=>'Plan added!','updated'=>'Plan updated!','deleted'=>'Plan deleted!'][$_GET['msg']]??'Done!'?></div>
<?php endif;?>
<?php if($err):?><div class="alert alert-error">⚠️ <?=htmlspecialchars($err)?></div><?php endif;?>

<!-- Add/Edit Form -->
<div class="card" style="margin-bottom:24px">
  <div class="card-header"><h2><?=$editPlan?'✏️ Edit Plan':'➕ Add New Plan'?></h2></div>
  <div class="card-body">
    <form method="POST">
      <?php if($editPlan):?><input type="hidden" name="edit_id" value="<?=$editPlan['id']?>"><?php endif;?>
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px">
        <div class="form-group" style="margin:0">
          <label>Label *</label>
          <input type="text" name="label" class="form-control" placeholder="e.g. 3 Months" value="<?=htmlspecialchars($editPlan['label']??'')?>">
        </div>
        <div class="form-group" style="margin:0">
          <label>Price *</label>
          <input type="text" name="price" class="form-control" placeholder="₹1,999" value="<?=htmlspecialchars($editPlan['price']??'')?>">
        </div>
        <div class="form-group" style="margin:0">
          <label>Original Price</label>
          <input type="text" name="original_price" class="form-control" placeholder="₹5,499" value="<?=htmlspecialchars($editPlan['original_price']??'')?>">
        </div>
        <div class="form-group" style="margin:0">
          <label>Discount Label</label>
          <input type="text" name="discount" class="form-control" placeholder="22% OFF" value="<?=htmlspecialchars($editPlan['discount']??'')?>">
        </div>
        <div class="form-group" style="margin:0">
          <label>Sort Order</label>
          <input type="number" name="sort_order" class="form-control" value="<?=$editPlan['sort_order']??0?>">
        </div>
      </div>
      <div style="margin-top:14px;display:flex;align-items:center;gap:20px;flex-wrap:wrap">
        <label style="display:flex;align-items:center;gap:8px;font-size:13px;cursor:pointer;font-weight:600">
          <input type="checkbox" name="is_best_value" <?=($editPlan['is_best_value']??0)?'checked':''?>> ⭐ Mark as Best Value
        </label>
        <button type="submit" class="btn btn-primary"><?=$editPlan?'💾 Update Plan':'➕ Add Plan'?></button>
        <?php if($editPlan):?><a href="upgrade_plans.php" class="btn btn-secondary">Cancel</a><?php endif;?>
      </div>
    </form>
  </div>
</div>

<!-- Plans Grid -->
<?php if($plans):?>
<div class="plans-grid">
  <?php foreach($plans as $p):?>
  <div class="plan-card <?=$p['is_best_value']?'best':''?> <?=!$p['is_active']?'inactive':''?>">
    <?php if($p['is_best_value']):?><div class="best-tag">⭐ Best Value</div><?php endif;?>
    <?php if(!$p['is_active']):?><span class="badge bg-gray" style="margin-bottom:8px;display:inline-block">Inactive</span><?php endif;?>
    <div class="plan-label"><?=htmlspecialchars($p['label'])?></div>
    <div class="plan-price"><?=htmlspecialchars($p['price'])?></div>
    <?php if($p['original_price']):?><div class="plan-orig"><?=htmlspecialchars($p['original_price'])?></div><?php endif;?>
    <?php if($p['discount']):?><div class="plan-disc"><?=htmlspecialchars($p['discount'])?></div><?php endif;?>
    <div class="plan-actions">
      <a href="upgrade_plans.php?edit=<?=$p['id']?>" class="btn btn-info btn-sm">✏️ Edit</a>
      <a href="upgrade_plans.php?toggle=<?=$p['id']?>" class="btn btn-sm <?=$p['is_active']?'btn-danger':'btn-success'?>"><?=$p['is_active']?'⏸ Deactivate':'▶ Activate'?></a>
      <a href="upgrade_plans.php?delete=<?=$p['id']?>" class="btn btn-danger btn-sm" onclick="return confirm('Delete this plan?')">🗑</a>
    </div>
  </div>
  <?php endforeach;?>
</div>
<?php else:?>
<div class="card"><div class="empty"><div class="e-ico">💎</div><p>No plans yet. Add your first plan above.</p></div></div>
<?php endif;?>

<!-- Features Table -->
<div class="card">
  <div class="card-header"><h2>⭐ Upgrade Features</h2></div>
  <div class="tbl-scroll">
    <table>
      <thead><tr><th>#</th><th>Title</th><th>Description</th><th>Icon</th><th>Sort</th><th>Status</th></tr></thead>
      <tbody>
        <?php foreach($features as $i=>$f):?>
        <tr>
          <td style="color:#9ca3af"><?=$i+1?></td>
          <td style="font-weight:600"><?=htmlspecialchars($f['title'])?></td>
          <td style="color:#6b7280"><?=htmlspecialchars($f['description'])?></td>
          <td><?=htmlspecialchars($f['icon'])?></td>
          <td><?=$f['sort_order']?></td>
          <td><span class="badge <?=$f['is_active']?'bg-green':'bg-red'?>"><?=$f['is_active']?'Active':'Inactive'?></span></td>
        </tr>
        <?php endforeach;?>
        <?php if(empty($features)):?><tr><td colspan="6" style="text-align:center;color:#9ca3af;padding:30px">No features found</td></tr><?php endif;?>
      </tbody>
    </table>
  </div>
</div>

<?php include 'layout_end.php';?>
