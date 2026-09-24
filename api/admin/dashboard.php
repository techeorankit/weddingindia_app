<?php
require_once 'config.php';
requireLogin();
$pageTitle='Dashboard';
$db=getDB();

$totalUsers    = $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
$verifiedUsers = $db->query("SELECT COUNT(*) FROM users WHERE is_verified=1")->fetchColumn();
$totalProfiles = $db->query("SELECT COUNT(*) FROM user_profiles WHERE full_name IS NOT NULL")->fetchColumn();
$todayUsers    = $db->query("SELECT COUNT(*) FROM users WHERE DATE(created_at)=CURDATE()")->fetchColumn();
$totalPhotos   = $db->query("SELECT COUNT(*) FROM user_photos")->fetchColumn();
$weekUsers     = $db->query("SELECT COUNT(*) FROM users WHERE created_at>=DATE_SUB(NOW(),INTERVAL 7 DAY)")->fetchColumn();
$maleCount     = $db->query("SELECT COUNT(*) FROM user_profiles WHERE gender='Male'")->fetchColumn();
$femaleCount   = $db->query("SELECT COUNT(*) FROM user_profiles WHERE gender='Female'")->fetchColumn();
$totalInteract = $db->query("SELECT COUNT(*) FROM user_interactions")->fetchColumn();

// 7-day chart
$chartRows=$db->query("SELECT DATE(created_at) as d,COUNT(*) as c FROM users WHERE created_at>=DATE_SUB(NOW(),INTERVAL 7 DAY) GROUP BY DATE(created_at)")->fetchAll(PDO::FETCH_KEY_PAIR);
$labels=[];$vals=[];
for($i=6;$i>=0;$i--){$d=date('Y-m-d',strtotime("-$i days"));$labels[]=date('d M',strtotime($d));$vals[]=(int)($chartRows[$d]??0);}

// Religion distribution
$relStats=$db->query("SELECT r.name,COUNT(*) as c FROM user_religion ur JOIN religions r ON r.id=ur.religion_id GROUP BY r.id ORDER BY c DESC LIMIT 5")->fetchAll();

// Recent users
$recent=$db->query("SELECT u.id,u.phone,u.country_code,u.is_verified,u.created_at,p.full_name,p.gender,p.profile_photo FROM users u LEFT JOIN user_profiles p ON p.user_id=u.id ORDER BY u.created_at DESC LIMIT 8")->fetchAll();

include 'layout.php';
?>

<style>
.dash-hero{background:linear-gradient(135deg,#e91e63 0%,#880e4f 100%);border-radius:16px;padding:26px 30px;margin-bottom:22px;display:flex;align-items:center;justify-content:space-between;box-shadow:0 6px 24px rgba(233,30,99,.3)}
.dh-text h2{color:#fff;font-size:21px;font-weight:800;margin-bottom:4px}
.dh-text p{color:rgba(255,255,255,.7);font-size:13px}
.dh-emoji{font-size:60px;line-height:1}
.quick-btns{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:22px}
.qb{display:flex;align-items:center;gap:7px;padding:9px 16px;border-radius:10px;text-decoration:none;font-size:13px;font-weight:600;transition:all .15s;border:1.5px solid transparent}
.qb:hover{transform:translateY(-2px);box-shadow:0 4px 14px rgba(0,0,0,.12)}
.qb.p{background:#fce4ec;color:#c2185b;border-color:#f48fb1}
.qb.b{background:#dbeafe;color:#1e40af;border-color:#93c5fd}
.qb.g{background:#dcfce7;color:#166534;border-color:#86efac}
.qb.o{background:#ffedd5;color:#9a3412;border-color:#fdba74}
.dash-grid{display:grid;grid-template-columns:1fr 320px;gap:20px;margin-bottom:22px}
.chart-card{background:#fff;border-radius:14px;padding:22px;box-shadow:0 1px 4px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.04)}
.chart-card h3{font-size:14px;font-weight:700;color:#1a1a2e;margin-bottom:16px}
.chart-wrap{height:210px;position:relative}
.side-cards{display:flex;flex-direction:column;gap:16px}
.gender-card,.rel-card{background:#fff;border-radius:14px;padding:20px;box-shadow:0 1px 4px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.04)}
.gender-card h3,.rel-card h3{font-size:14px;font-weight:700;color:#1a1a2e;margin-bottom:14px}
.g-bar{margin-bottom:12px}
.g-bar-top{display:flex;justify-content:space-between;font-size:12.5px;margin-bottom:5px;color:#374151}
.g-track{height:8px;background:#f3f4f6;border-radius:8px;overflow:hidden}
.g-fill{height:100%;border-radius:8px}
.g-fill.m{background:linear-gradient(90deg,#1e88e5,#64b5f6)}
.g-fill.f{background:linear-gradient(90deg,#e91e63,#f48fb1)}
.rel-item{display:flex;align-items:center;justify-content:space-between;padding:6px 0;border-bottom:1px solid #f4f6fb;font-size:13px}
.rel-item:last-child{border-bottom:none}
@media(max-width:900px){.dash-grid{grid-template-columns:1fr}}
</style>

<!-- Hero -->
<div class="dash-hero">
  <div class="dh-text">
    <h2>Welcome back, <?=htmlspecialchars(currentAdmin()['name'])?>! 👋</h2>
    <p>Here's your Wedding India overview — <?=date('l, d F Y')?></p>
  </div>
  <div class="dh-emoji">💍</div>
</div>

<!-- Quick Buttons -->
<div class="quick-btns">
  <a href="users.php" class="qb p">👥 Manage Users</a>
  <a href="profiles.php" class="qb b">👤 Profiles</a>
  <a href="photos.php" class="qb g">🖼️ Photos</a>
  <a href="interactions.php" class="qb o">💬 Interactions</a>
  <a href="upgrade_plans.php" class="qb" style="background:#f3e8ff;color:#6b21a8;border-color:#d8b4fe">💎 Plans</a>
</div>

<!-- Stats -->
<div class="stats-row">
  <div class="stat c1">
    <div class="stat-ico" style="background:#fce4ec">👥</div>
    <div class="stat-info"><h3><?=number_format($totalUsers)?></h3><p>Total Users</p><small>+<?=$weekUsers?> this week</small></div>
  </div>
  <div class="stat c2">
    <div class="stat-ico" style="background:#dcfce7">✅</div>
    <div class="stat-info"><h3><?=number_format($verifiedUsers)?></h3><p>Verified</p><small><?=$totalUsers>0?round($verifiedUsers/$totalUsers*100):0?>% rate</small></div>
  </div>
  <div class="stat c3">
    <div class="stat-ico" style="background:#dbeafe">👤</div>
    <div class="stat-info"><h3><?=number_format($totalProfiles)?></h3><p>Profiles</p><small><?=$totalUsers>0?round($totalProfiles/$totalUsers*100):0?>% complete</small></div>
  </div>
  <div class="stat c4">
    <div class="stat-ico" style="background:#ffedd5">🆕</div>
    <div class="stat-info"><h3><?=$todayUsers?></h3><p>Today's Signups</p><small><?=date('d M Y')?></small></div>
  </div>
  <div class="stat c5">
    <div class="stat-ico" style="background:#f3e8ff">🖼️</div>
    <div class="stat-info"><h3><?=number_format($totalPhotos)?></h3><p>Photos</p><small>Uploaded</small></div>
  </div>
  <div class="stat c6">
    <div class="stat-ico" style="background:#ccfbf1">💬</div>
    <div class="stat-info"><h3><?=number_format($totalInteract)?></h3><p>Interactions</p><small>Total actions</small></div>
  </div>
</div>

<!-- Chart + Side -->
<div class="dash-grid">
  <div class="chart-card">
    <h3>📈 New Signups — Last 7 Days</h3>
    <div class="chart-wrap"><canvas id="sc"></canvas></div>
  </div>
  <div class="side-cards">
    <div class="gender-card">
      <h3>⚧ Gender Split</h3>
      <?php $tg=$maleCount+$femaleCount?:1; ?>
      <div class="g-bar">
        <div class="g-bar-top"><span>👨 Male</span><span><?=$maleCount?> (<?=round($maleCount/$tg*100)?>%)</span></div>
        <div class="g-track"><div class="g-fill m" style="width:<?=round($maleCount/$tg*100)?>%"></div></div>
      </div>
      <div class="g-bar">
        <div class="g-bar-top"><span>👩 Female</span><span><?=$femaleCount?> (<?=round($femaleCount/$tg*100)?>%)</span></div>
        <div class="g-track"><div class="g-fill f" style="width:<?=round($femaleCount/$tg*100)?>%"></div></div>
      </div>
    </div>
    <div class="rel-card">
      <h3>🛕 Top Religions</h3>
      <?php foreach($relStats as $r):?>
      <div class="rel-item">
        <span><?=htmlspecialchars($r['name'])?></span>
        <span class="badge bg-blue"><?=$r['c']?></span>
      </div>
      <?php endforeach;?>
      <?php if(empty($relStats)):?><p style="color:#9ca3af;font-size:13px">No data</p><?php endif;?>
    </div>
  </div>
</div>

<!-- Recent Users -->
<div class="card">
  <div class="card-header">
    <h2>🕐 Recent Registrations</h2>
    <a href="users.php" class="btn btn-primary btn-sm">View All →</a>
  </div>
  <div class="tbl-scroll">
    <table>
      <thead><tr><th>User</th><th>Phone</th><th>Gender</th><th>Status</th><th>Joined</th><th>Action</th></tr></thead>
      <tbody>
        <?php foreach($recent as $u):?>
        <tr>
          <td>
            <div style="display:flex;align-items:center;gap:10px">
              <div class="avatar">
                <?php if($u['profile_photo']):?><img src="../uploads/<?=htmlspecialchars($u['profile_photo'])?>"><?php else:?><?=strtoupper(substr($u['full_name']??$u['phone'],0,1))?><?php endif;?>
              </div>
              <div>
                <div style="font-weight:600;font-size:13.5px"><?=htmlspecialchars($u['full_name']??'No Name')?></div>
                <div style="font-size:11px;color:#9ca3af">ID #<?=$u['id']?></div>
              </div>
            </div>
          </td>
          <td style="color:#6b7280"><?=htmlspecialchars($u['country_code'].' '.$u['phone'])?></td>
          <td><?=$u['gender']??'—'?></td>
          <td><span class="badge <?=$u['is_verified']?'bg-green':'bg-orange'?>"><?=$u['is_verified']?'✅ Verified':'⏳ Pending'?></span></td>
          <td style="color:#9ca3af;font-size:13px"><?=date('d M Y',strtotime($u['created_at']))?></td>
          <td><a href="user_detail.php?id=<?=$u['id']?>" class="btn btn-info btn-sm">View</a></td>
        </tr>
        <?php endforeach;?>
      </tbody>
    </table>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
new Chart(document.getElementById('sc'),{
  type:'bar',
  data:{
    labels:<?=json_encode($labels)?>,
    datasets:[{label:'Signups',data:<?=json_encode($vals)?>,backgroundColor:'rgba(233,30,99,.12)',borderColor:'#e91e63',borderWidth:2,borderRadius:8,hoverBackgroundColor:'rgba(233,30,99,.25)'}]
  },
  options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},scales:{y:{beginAtZero:true,ticks:{stepSize:1,precision:0},grid:{color:'#f4f6fb'}},x:{grid:{display:false}}}}
});
</script>

<?php include 'layout_end.php';?>
