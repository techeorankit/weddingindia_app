<?php
require_once 'config.php';
requireLogin();

$allowedTables = [
    'religions','mother_tongues','states','education_levels','income_ranges',
    'marital_statuses','profile_for_options','heights','eating_habits',
    'smoking_habits','drinking_habits','body_types','complexions','blood_groups',
    'disabilities','country_codes','upgrade_plans','upgrade_features','admins'
];

$labels = [
    'religions'=>'Religions','mother_tongues'=>'Mother Tongues','states'=>'States',
    'education_levels'=>'Education Levels','income_ranges'=>'Income Ranges',
    'marital_statuses'=>'Marital Status','profile_for_options'=>'Profile For',
    'heights'=>'Heights','eating_habits'=>'Eating Habits','smoking_habits'=>'Smoking Habits',
    'drinking_habits'=>'Drinking Habits','body_types'=>'Body Types','complexions'=>'Complexions',
    'blood_groups'=>'Blood Groups','disabilities'=>'Disabilities','country_codes'=>'Country Codes',
    'upgrade_plans'=>'Upgrade Plans','upgrade_features'=>'Upgrade Features','admins'=>'Admins'
];
$icons = [
    'religions'=>'🛕','mother_tongues'=>'🗣️','states'=>'🗺️','education_levels'=>'🎓',
    'income_ranges'=>'💰','marital_statuses'=>'💍','profile_for_options'=>'👤','heights'=>'📏',
    'eating_habits'=>'🍽️','smoking_habits'=>'🚬','drinking_habits'=>'🍷','body_types'=>'💪',
    'complexions'=>'🎨','blood_groups'=>'🩸','disabilities'=>'♿','country_codes'=>'🌍',
    'upgrade_plans'=>'💎','upgrade_features'=>'⭐','admins'=>'👑'
];

$table = $_GET['table'] ?? 'religions';
if (!in_array($table, $allowedTables, true)) {
    $table = 'religions';
}

$pageTitle = $labels[$table] ?? ucwords(str_replace('_',' ',$table));
$db = getDB();
$error = '';
$success = '';

function getTableColumns(PDO $db, string $table): array {
    return $db->query("SHOW COLUMNS FROM `{$table}`")->fetchAll();
}

$columns = getTableColumns($db, $table);
$columnMap = [];
foreach ($columns as $c) $columnMap[$c['Field']] = $c;

$primary = 'id';
foreach ($columns as $c) {
    if (($c['Key'] ?? '') === 'PRI') { $primary = $c['Field']; break; }
}

if (empty($_SESSION['admin_csrf'])) $_SESSION['admin_csrf'] = bin2hex(random_bytes(16));
$csrf = $_SESSION['admin_csrf'];

$action = $_POST['action'] ?? $_GET['action'] ?? '';
$editId = isset($_GET['edit']) ? (int)$_GET['edit'] : 0;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (!hash_equals($_SESSION['admin_csrf'] ?? '', $_POST['csrf'] ?? '')) {
            if (empty($_SESSION['admin_csrf'])) {
                $_SESSION['admin_csrf'] = bin2hex(random_bytes(16));
            }
            throw new Exception('Security token expired. Please try again.');
        }

        if ($action === 'delete') {
            $id = (int)($_POST['id'] ?? 0);
            if (!$id) throw new Exception('Invalid record.');
            $stmt = $db->prepare("DELETE FROM `{$table}` WHERE `{$primary}` = ? LIMIT 1");
            $stmt->execute([$id]);
            $success = $stmt->rowCount() ? 'Record deleted successfully.' : 'Record not found.';
        } elseif ($action === 'toggle') {
            $id = (int)($_POST['id'] ?? 0);
            if (!$id || !isset($columnMap['is_active'])) throw new Exception('This table does not support active/inactive status.');
            $stmt = $db->prepare("UPDATE `{$table}` SET `is_active` = 1 - `is_active` WHERE `{$primary}` = ? LIMIT 1");
            $stmt->execute([$id]);
            $success = 'Status updated successfully.';
        } elseif ($action === 'save') {
            $id = (int)($_POST['id'] ?? 0);
            $data = [];
            foreach ($columns as $c) {
                $field = $c['Field'];
                if ($field === $primary && (($c['Extra'] ?? '') === 'auto_increment' || $field === 'id')) continue;
                if ($field === 'created_at' || $field === 'updated_at' || $field === 'last_login') continue;
                if (!array_key_exists($field, $_POST)) {
                    if (in_array($field, ['is_active','is_best_value'], true)) $data[$field] = 0;
                    continue;
                }
                $value = $_POST[$field];
                if (is_array($value)) $value = '';
                if ($field === 'password' && $table === 'admins') {
                    if ($id > 0 && trim((string)$value) === '') continue;
                    if (trim((string)$value) !== '') $value = password_hash((string)$value, PASSWORD_DEFAULT);
                }
                $data[$field] = ($value === '' && ($c['Null'] ?? 'NO') === 'YES') ? null : $value;
            }

            if (!$data) throw new Exception('Nothing to save.');

            if ($id > 0) {
                $sets=[]; $vals=[];
                foreach ($data as $field=>$value) { $sets[]="`{$field}` = ?"; $vals[]=$value; }
                $vals[]=$id;
                $stmt=$db->prepare("UPDATE `{$table}` SET ".implode(', ',$sets)." WHERE `{$primary}` = ? LIMIT 1");
                $stmt->execute($vals);
                $success='Record updated successfully.';
            } else {
                $fields=array_keys($data);
                $placeholders=implode(',',array_fill(0,count($fields),'?'));
                $stmt=$db->prepare("INSERT INTO `{$table}` (`".implode('`,`',$fields)."`) VALUES ({$placeholders})");
                $stmt->execute(array_values($data));
                $success='Record added successfully.';
            }
            $editId = 0;
        }
    } catch (Throwable $e) {
        $error = $e->getCode() === '23000' ? 'This record cannot be changed because it is being used elsewhere.' : $e->getMessage();
    }
}

$editRow = null;
if ($editId) {
    $stmt=$db->prepare("SELECT * FROM `{$table}` WHERE `{$primary}` = ? LIMIT 1");
    $stmt->execute([$editId]);
    $editRow=$stmt->fetch() ?: null;
}

$search = trim($_GET['q'] ?? '');
$page = max(1,(int)($_GET['page'] ?? 1));
$perPage = 25;
$where=''; $params=[];
$searchable=[];
foreach ($columns as $c) {
    $type=strtolower($c['Type']);
    if (strpos($type,'char')!==false || strpos($type,'text')!==false) $searchable[]=$c['Field'];
}
if ($search && $searchable) {
    $parts=[];
    foreach ($searchable as $field) { $parts[]="`{$field}` LIKE ?"; $params[]='%'.$search.'%'; }
    $where=' WHERE '.implode(' OR ',$parts);
}

$totalStmt=$db->prepare("SELECT COUNT(*) FROM `{$table}`{$where}");
$totalStmt->execute($params);
$total=(int)$totalStmt->fetchColumn();
$totalPages=max(1,(int)ceil($total/$perPage));
if ($page>$totalPages) $page=$totalPages;
$offset=($page-1)*$perPage;
$order = $primary;
if (isset($columnMap['sort_order'])) $order='sort_order, '.$primary;
if (isset($columnMap['sort_order'])) {
    $orderSql = '`sort_order` ASC, `'.$primary.'` ASC';
} else {
    $orderSql = '`'.$primary.'` DESC';
}
$rowsStmt=$db->prepare("SELECT * FROM `{$table}`{$where} ORDER BY {$orderSql} LIMIT {$perPage} OFFSET {$offset}");
$rowsStmt->execute($params);
$rows=$rowsStmt->fetchAll();

function humanField(string $field): string {
    return ucwords(str_replace('_',' ',preg_replace('/([a-z])([A-Z])/','$1 $2',$field)));
}
function inputType(array $c): string {
    $f=$c['Field']; $t=strtolower($c['Type']);
    if ($f==='password') return 'password';
    if (strpos($t,'int')!==false || strpos($t,'decimal')!==false || strpos($t,'float')!==false) return 'number';
    if (strpos($t,'text')!==false) return 'textarea';
    return 'text';
}
function displayValue(string $field, $value): string {
    if ($field==='password') return '••••••••';
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

include 'layout.php';
?>

<style>
.manager-hero{background:linear-gradient(135deg,#e91e63,#8b0d50);border-radius:18px;padding:24px 26px;color:#fff;display:flex;align-items:center;justify-content:space-between;gap:20px;margin-bottom:18px;box-shadow:0 10px 28px rgba(233,30,99,.20)}
.manager-hero .left{display:flex;align-items:center;gap:14px}.manager-icon{width:54px;height:54px;border-radius:15px;background:rgba(255,255,255,.16);display:grid;place-items:center;font-size:26px}.manager-hero h2{font-size:20px;margin:0 0 3px}.manager-hero p{font-size:12px;opacity:.78;margin:0}.hero-count{text-align:right}.hero-count strong{display:block;font-size:25px}.hero-count span{font-size:11px;opacity:.75}
.manager-toolbar{background:#fff;border:1px solid #eef0f5;border-radius:14px;padding:14px;display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:16px;box-shadow:0 4px 15px rgba(16,24,40,.04)}
.search-form{display:flex;gap:8px;flex:1;max-width:520px}.search-form .search-box{width:100%}.manager-actions{display:flex;gap:8px;align-items:center}.btn-success{background:#dcfce7;color:#166534}.btn-secondary{background:#f3f4f6;color:#374151}.btn-sm{padding:7px 11px;font-size:12px;border-radius:7px}
.manager-table-wrap{overflow:auto}.manager-table{min-width:760px}.manager-table td,.manager-table th{white-space:nowrap}.manager-table td.value-cell{max-width:280px;overflow:hidden;text-overflow:ellipsis}.actions-cell{display:flex;gap:6px;align-items:center}.inline-form{display:inline;margin:0}.status-active{background:#dcfce7;color:#166534;padding:4px 9px;border-radius:999px;font-size:11px;font-weight:700}.status-off{background:#fee2e2;color:#991b1b;padding:4px 9px;border-radius:999px;font-size:11px;font-weight:700}
.form-panel{background:#fff;border:1px solid #eef0f5;border-radius:14px;padding:20px;margin-bottom:16px;box-shadow:0 4px 15px rgba(16,24,40,.04)}.form-panel h3{font-size:16px;margin-bottom:16px}.form-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}.form-grid .full{grid-column:1/-1}.form-group textarea{min-height:90px;resize:vertical}.form-check{display:flex;align-items:center;gap:8px;height:42px}.form-check input{width:18px!important;height:18px}.pagination{padding:16px 0 0}
@media(max-width:700px){.manager-hero{padding:18px}.hero-count{display:none}.manager-toolbar{align-items:stretch;flex-direction:column}.search-form{max-width:none}.manager-actions{justify-content:flex-start}.form-grid{grid-template-columns:1fr}.content{padding:16px}}
</style>

<div class="manager-hero">
  <div class="left"><div class="manager-icon"><?=$icons[$table]??'🗄️'?></div><div><h2><?=htmlspecialchars($pageTitle)?></h2><p>Manage <?=htmlspecialchars(strtolower($pageTitle))?> from your admin panel</p></div></div>
  <div class="hero-count"><strong><?=number_format($total)?></strong><span>Total Records</span></div>
</div>

<?php if($success):?><div class="alert alert-success">✅ <?=htmlspecialchars($success)?></div><?php endif;?>
<?php if($error):?><div class="alert alert-error">⚠️ <?=htmlspecialchars($error)?></div><?php endif;?>

<?php if($editRow || isset($_GET['add'])): ?>
<div class="form-panel" id="editor">
  <h3><?= $editRow ? '✏️ Edit '.$pageTitle : '➕ Add New '.rtrim($pageTitle,'s') ?></h3>
  <form method="post">
    <input type="hidden" name="csrf" value="<?=htmlspecialchars($csrf)?>">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?=$editRow ? (int)$editRow[$primary] : 0?>">
    <div class="form-grid">
      <?php foreach($columns as $c): $field=$c['Field']; if($field===$primary && (($c['Extra']??'')==='auto_increment' || $field==='id')) continue; if(in_array($field,['created_at','updated_at','last_login'],true)) continue; $val=$editRow[$field]??''; $type=inputType($c); $isBool=in_array($field,['is_active','is_best_value'],true); ?>
        <div class="form-group <?=($type==='textarea'?'full':'')?>">
          <label><?=htmlspecialchars(humanField($field))?></label>
          <?php if($isBool): ?>
            <label class="form-check"><input type="checkbox" name="<?=htmlspecialchars($field)?>" value="1" <?=$val?'checked':''?>> <span>Enabled</span></label>
          <?php elseif($type==='textarea'): ?>
            <textarea name="<?=htmlspecialchars($field)?>" placeholder="<?=htmlspecialchars(humanField($field))?>"><?=htmlspecialchars((string)$val)?></textarea>
          <?php else: ?>
            <input type="<?=$type==='number'?'number':'text'?>" name="<?=htmlspecialchars($field)?>" value="<?=htmlspecialchars((string)$val)?>" <?=($table==='admins'&&$field==='password'&&$editRow)?'placeholder="Leave blank to keep current password"':''?> <?=($c['Null']==='NO' && $field!=='password')?'required':''?>>
          <?php endif; ?>
        </div>
      <?php endforeach; ?>
    </div>
    <div class="modal-footer" style="margin-top:16px">
      <?php if($editRow):?><a href="manage_table.php?table=<?=urlencode($table)?>" class="btn btn-secondary">Cancel</a><?php endif;?>
      <button type="submit" class="btn btn-primary"><?= $editRow ? 'Update Record' : 'Save Record' ?></button>
    </div>
  </form>
</div>
<?php endif; ?>

<div class="manager-toolbar">
  <form class="search-form" method="get">
    <input type="hidden" name="table" value="<?=htmlspecialchars($table)?>">
    <input class="search-box" name="q" value="<?=htmlspecialchars($search)?>" placeholder="Search <?=htmlspecialchars(strtolower($pageTitle))?>...">
    <button class="btn btn-info" type="submit">🔎 Search</button>
  </form>
  <div class="manager-actions">
    <?php if($search):?><a class="btn btn-secondary btn-sm" href="manage_table.php?table=<?=urlencode($table)?>">Clear</a><?php endif;?>
    <a class="btn btn-primary" href="manage_table.php?table=<?=urlencode($table)?>&add=1#editor">➕ Add New</a>
  </div>
</div>

<div class="card">
  <div class="card-header"><h2><?=htmlspecialchars($pageTitle)?> <span class="badge bg-blue"><?=number_format($total)?></span></h2><span style="font-size:12px;color:#9ca3af">Page <?=$page?> of <?=$totalPages?></span></div>
  <?php if(!$rows): ?>
    <div class="empty"><div class="e-ico">📭</div><p>No records found.</p></div>
  <?php else: ?>
    <div class="tbl-scroll manager-table-wrap">
      <table class="manager-table">
        <thead><tr>
          <?php foreach($columns as $c): ?><th><?=htmlspecialchars(humanField($c['Field']))?></th><?php endforeach; ?><th>Actions</th>
        </tr></thead>
        <tbody>
        <?php foreach($rows as $row): ?>
          <tr>
            <?php foreach($columns as $c): $field=$c['Field']; $v=$row[$field]??null; ?>
              <td class="value-cell">
                <?php if($field==='password'): ?>••••••••<?php elseif($field==='is_active'): ?><span class="<?=$v?'status-active':'status-off'?>"><?=$v?'Active':'Inactive'?></span><?php elseif($field==='is_best_value'): ?><span class="badge <?=$v?'bg-green':'bg-gray'?>"><?=$v?'Yes':'No'?></span><?php elseif($v===null || $v===''): ?><span class="null-v">—</span><?php else: ?><?=displayValue($field,$v)?><?php endif; ?>
              </td>
            <?php endforeach; ?>
            <td><div class="actions-cell">
              <a class="btn btn-info btn-sm" href="manage_table.php?table=<?=urlencode($table)?>&edit=<?=urlencode($row[$primary])?>#editor">✏️ Edit</a>
              <?php if(isset($columnMap['is_active'])): ?><form class="inline-form" method="post"><input type="hidden" name="csrf" value="<?=htmlspecialchars($csrf)?>"><input type="hidden" name="action" value="toggle"><input type="hidden" name="id" value="<?=htmlspecialchars($row[$primary])?>"><button class="btn btn-secondary btn-sm" type="submit"><?=$row['is_active']?'Disable':'Enable'?></button></form><?php endif; ?>
              <form class="inline-form" method="post" onsubmit="return confirm('Delete this record? This cannot be undone.');"><input type="hidden" name="csrf" value="<?=htmlspecialchars($csrf)?>"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="<?=htmlspecialchars($row[$primary])?>"><button class="btn btn-danger btn-sm" type="submit">🗑</button></form>
            </div></td>
          </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>
    <div class="pagination">
      <?php $base='manage_table.php?table='.urlencode($table).'&q='.urlencode($search); ?>
      <a class="pg-btn <?=$page<=1?'disabled':''?>" href="<?=$page>1?$base.'&page='.($page-1):'#'?>">‹</a>
      <?php $start=max(1,$page-2); $end=min($totalPages,$page+2); if($start>1): ?><a class="pg-btn" href="<?=$base?>&page=1">1</a><?php if($start>2):?><span class="pg-btn disabled">…</span><?php endif; endif; ?>
      <?php for($p=$start;$p<=$end;$p++): ?><a class="pg-btn <?=$p===$page?'active':''?>" href="<?=$base?>&page=<?=$p?>"><?=$p?></a><?php endfor; ?>
      <?php if($end<$totalPages): ?><?php if($end<$totalPages-1):?><span class="pg-btn disabled">…</span><?php endif;?><a class="pg-btn" href="<?=$base?>&page=<?=$totalPages?>"><?=$totalPages?></a><?php endif; ?>
      <a class="pg-btn <?=$page>=$totalPages?'disabled':''?>" href="<?=$page<$totalPages?$base.'&page='.($page+1):'#'?>">›</a>
    </div>
  <?php endif; ?>
</div>

<?php include 'layout_end.php'; ?>
