<?php
require_once 'config.php';
requireLogin();
$id=(int)($_GET['id']??0);
if(!$id){header('Location: users.php');exit();}
$db=getDB();

// Save edit
if($_SERVER['REQUEST_METHOD']==='POST'){
    $db->prepare("UPDATE user_profiles SET full_name=?,gender=?,dob=?,bio=? WHERE user_id=?")->execute([$_POST['full_name'],$_POST['gender'],$_POST['dob']?:null,$_POST['bio'],$id]);
    if($db->query("SELECT COUNT(*) FROM user_religion WHERE user_id=$id")->fetchColumn())
        $db->prepare("UPDATE user_religion SET religion_id=?,caste=? WHERE user_id=?")->execute([$_POST['religion_id']?:null,$_POST['caste'],$id]);
    else
        $db->prepare("INSERT INTO user_religion(user_id,religion_id,caste) VALUES(?,?,?)")->execute([$id,$_POST['religion_id']?:null,$_POST['caste']]);
    if($db->query("SELECT COUNT(*) FROM user_location WHERE user_id=$id")->fetchColumn())
        $db->prepare("UPDATE user_location SET state_id=?,city=? WHERE user_id=?")->execute([$_POST['state_id']?:null,$_POST['city'],$id]);
    else
        $db->prepare("INSERT INTO user_location(user_id,state_id,city) VALUES(?,?,?)")->execute([$id,$_POST['state_id']?:null,$_POST['city']]);
    if($db->query("SELECT COUNT(*) FROM user_education WHERE user_id=$id")->fetchColumn())
        $db->prepare("UPDATE user_education SET education_id=?,profession=?,income_id=? WHERE user_id=?")->execute([$_POST['education_id']?:null,$_POST['profession'],$_POST['income_id']?:null,$id]);
    else
        $db->prepare("INSERT INTO user_education(user_id,education_id,profession,income_id) VALUES(?,?,?,?)")->execute([$id,$_POST['education_id']?:null,$_POST['profession'],$_POST['income_id']?:null]);
    header("Location: user_detail.php?id=$id&msg=saved");exit();
}

$user=$db->prepare("SELECT u.*,p.full_name,p.gender,p.dob,p.bio,p.profile_photo,p.is_profile_complete,p.profile_for FROM users u LEFT JOIN user_profiles p ON p.user_id=u.id WHERE u.id=?");
$user->execute([$id]);$user=$user->fetch();
if(!$user){header('Location: users.php');exit();}

$rel=$db->prepare("SELECT ur.*,r.name as rname,mt.name as mtname FROM user_religion ur LEFT JOIN religions r ON r.id=ur.religion_id LEFT JOIN mother_tongues mt ON mt.id=ur.mother_tongue_id WHERE ur.user_id=?");
$rel->execute([$id]);$rel=$rel->fetch();

$loc=$db->prepare("SELECT ul.*,s.name as sname FROM user_location ul LEFT JOIN states s ON s.id=ul.state_id WHERE ul.user_id=?");
$loc->execute([$id]);$loc=$loc->fetch();

$edu=$db->prepare("SELECT ue.*,el.name as ename,ir.name as iname FROM user_education ue LEFT JOIN education_levels el ON el.id=ue.education_id LEFT JOIN income_ranges ir ON ir.id=ue.income_id WHERE ue.user_id=?");
$edu->execute([$id]);$edu=$edu->fetch();

$hab=$db->prepare("SELECT uh.*,h.name as hname,ms.name as msname,eh.name as ehname,sh.name as shname,dh.name as dhname,bt.name as btname,c.name as cname,bg.name as bgname,d.name as dname FROM user_habits uh LEFT JOIN heights h ON h.id=uh.height_id LEFT JOIN marital_statuses ms ON ms.id=uh.marital_status_id LEFT JOIN eating_habits eh ON eh.id=uh.eating_habit_id LEFT JOIN smoking_habits sh ON sh.id=uh.smoking_habit_id LEFT JOIN drinking_habits dh ON dh.id=uh.drinking_habit_id LEFT JOIN body_types bt ON bt.id=uh.body_type_id LEFT JOIN complexions c ON c.id=uh.complexion_id LEFT JOIN blood_groups bg ON bg.id=uh.blood_group_id LEFT JOIN disabilities d ON d.id=uh.disability_id WHERE uh.user_id=?");
$hab->execute([$id]);$hab=$hab->fetch();

$photos=$db->prepare("SELECT * FROM user_photos WHERE user_id=? ORDER BY is_primary DESC,created_at DESC");
$photos->execute([$id]);$photos=$photos->fetchAll();

$pref=$db->prepare("SELECT upp.*,r.name as rname,h1.name as hmin,h2.name as hmax,ir.name as iname FROM user_partner_preference upp LEFT JOIN religions r ON r.id=upp.religion_id LEFT JOIN heights h1 ON h1.id=upp.min_height_id LEFT JOIN heights h2 ON h2.id=upp.max_height_id LEFT JOIN income_ranges ir ON ir.id=upp.income_id WHERE upp.user_id=?");
$pref->execute([$id]);$pref=$pref->fetch();

$interactions=$db->prepare("SELECT ui.*,p2.full_name as to_name FROM user_interactions ui LEFT JOIN user_profiles p2 ON p2.user_id=ui.to_user_id WHERE ui.from_user_id=? ORDER BY ui.created_at DESC LIMIT 10");
$interactions->execute([$id]);$interactions=$interactions->fetchAll();

// Dropdowns
$religions=$db->query("SELECT id,name FROM religions ORDER BY sort_order")->fetchAll();
$states=$db->query("SELECT id,name FROM states ORDER BY sort_order")->fetchAll();
$educations=$db->query("SELECT id,name FROM education_levels ORDER BY sort_order")->fetchAll();
$incomes=$db->query("SELECT id,name FROM income_ranges ORDER BY sort_order")->fetchAll();

$pageTitle='User Detail';
include 'layout.php';
?>

<?php if(isset($_GET['msg'])):?>
<div class="alert alert-success">✅ Profile updated successfully</div>
<?php endif;?>

<!-- Top Actions -->
<div style="display:flex;gap:8px;margin-bottom:20px;flex-wrap:wrap">
  <a href="users.php" class="btn btn-secondary">← Back to Users</a>
  <button onclick="openModal('editModal')" class="btn btn-primary">✏️ Edit Profile</button>
  <a href="users.php?toggle=<?=$id?>" class="btn <?=$user['is_verified']?'btn-danger':'btn-success'?>" onclick="return confirm('Toggle verification status?')">
    <?=$user['is_verified']?'❌ Unverify':'✅ Verify'?>
  </a>
  <a href="users.php?delete=<?=$id?>" class="btn btn-danger" onclick="return confirm('Delete this user permanently? This cannot be undone.')">🗑️ Delete User</a>
</div>

<div style="display:grid;grid-template-columns:300px 1fr;gap:20px">

  <!-- LEFT COLUMN -->
  <div style="display:flex;flex-direction:column;gap:16px">

    <!-- Profile Card -->
    <div class="card card-body" style="text-align:center">
      <div style="width:90px;height:90px;border-radius:50%;margin:0 auto 14px;overflow:hidden;background:linear-gradient(135deg,#fce4ec,#f8bbd0);display:flex;align-items:center;justify-content:center;font-size:36px;font-weight:700;color:#c2185b">
        <?php if($user['profile_photo']):?><img src="../uploads/<?=htmlspecialchars($user['profile_photo'])?>" style="width:100%;height:100%;object-fit:cover"><?php else:?><?=strtoupper(substr($user['full_name']??$user['phone'],0,1))?><?php endif;?>
      </div>
      <h2 style="font-size:18px;font-weight:800;color:#1a1a2e"><?=htmlspecialchars($user['full_name']??'No Name')?></h2>
      <p style="color:#9ca3af;font-size:13px;margin-top:4px"><?=$user['country_code'].' '.$user['phone']?></p>
      <?php if($user['bio']):?><p style="font-size:13px;color:#6b7280;margin-top:10px;line-height:1.5"><?=htmlspecialchars($user['bio'])?></p><?php endif;?>
      <div style="display:flex;gap:8px;justify-content:center;flex-wrap:wrap;margin-top:14px">
        <span class="badge <?=$user['is_verified']?'bg-green':'bg-red'?>"><?=$user['is_verified']?'✅ Verified':'❌ Unverified'?></span>
        <span class="badge <?=$user['is_profile_complete']?'bg-blue':'bg-orange'?>"><?=$user['is_profile_complete']?'Complete':'Incomplete'?></span>
      </div>
      <div style="margin-top:14px;font-size:12px;color:#9ca3af;border-top:1px solid #f4f6fb;padding-top:12px">
        <div>Joined: <?=date('d M Y',strtotime($user['created_at']))?></div>
        <div>Profile For: <?=$user['profile_for']??'—'?></div>
        <div>User ID: #<?=$user['id']?></div>
      </div>
    </div>

    <!-- Photos -->
    <?php if($photos):?>
    <div class="card card-body">
      <div class="sec-title">📸 Photos (<?=count($photos)?>)</div>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:6px">
        <?php foreach($photos as $ph):?>
        <div style="position:relative">
          <img src="../uploads/<?=htmlspecialchars($ph['photo_path'])?>" style="width:100%;aspect-ratio:1;object-fit:cover;border-radius:8px" onerror="this.style.background='#f4f6fb'">
          <?php if($ph['is_primary']):?><span style="position:absolute;top:3px;left:3px;background:#e91e63;color:#fff;font-size:9px;padding:1px 5px;border-radius:6px">★</span><?php endif;?>
        </div>
        <?php endforeach;?>
      </div>
    </div>
    <?php endif;?>

    <!-- Recent Interactions -->
    <?php if($interactions):?>
    <div class="card card-body">
      <div class="sec-title">💬 Recent Activity</div>
      <?php
      $icolors=['interest'=>'bg-red','shortlist'=>'bg-blue','ignore'=>'bg-gray','chat'=>'bg-green'];
      foreach($interactions as $ia):?>
      <div style="display:flex;align-items:center;justify-content:space-between;padding:7px 0;border-bottom:1px solid #f4f6fb;font-size:12.5px">
        <span><?=htmlspecialchars($ia['to_name']??'Unknown')?></span>
        <span class="badge <?=$icolors[$ia['type']]??'bg-gray'?>" style="font-size:10px"><?=ucfirst($ia['type'])?></span>
      </div>
      <?php endforeach;?>
    </div>
    <?php endif;?>
  </div>

  <!-- RIGHT COLUMN -->
  <div style="display:flex;flex-direction:column;gap:16px">

    <!-- Basic Info -->
    <div class="card card-body">
      <div class="sec-title">👤 Basic Information</div>
      <div class="info-row"><span class="lbl">Full Name</span><span class="val"><?=htmlspecialchars($user['full_name']??'—')?></span></div>
      <div class="info-row"><span class="lbl">Gender</span><span class="val"><?=$user['gender']??'—'?></span></div>
      <div class="info-row"><span class="lbl">Date of Birth</span><span class="val"><?=$user['dob']?date('d M Y',strtotime($user['dob'])).' ('.( date('Y')-date('Y',strtotime($user['dob']))).' yrs)':'—'?></span></div>
      <div class="info-row"><span class="lbl">Phone</span><span class="val"><?=$user['country_code'].' '.$user['phone']?></span></div>
    </div>

    <!-- Religion -->
    <?php if($rel):?>
    <div class="card card-body">
      <div class="sec-title">🛕 Religion & Community</div>
      <div class="info-row"><span class="lbl">Religion</span><span class="val"><?=$rel['rname']??'—'?></span></div>
      <div class="info-row"><span class="lbl">Caste</span><span class="val"><?=htmlspecialchars($rel['caste']??'—')?></span></div>
      <div class="info-row"><span class="lbl">Mother Tongue</span><span class="val"><?=$rel['mtname']??'—'?></span></div>
    </div>
    <?php endif;?>

    <!-- Location + Education in 2 cols -->
    <div class="grid-2">
      <?php if($loc):?>
      <div class="card card-body">
        <div class="sec-title">📍 Location</div>
        <div class="info-row"><span class="lbl">State</span><span class="val"><?=$loc['sname']??'—'?></span></div>
        <div class="info-row"><span class="lbl">City</span><span class="val"><?=htmlspecialchars($loc['city']??'—')?></span></div>
      </div>
      <?php endif;?>
      <?php if($edu):?>
      <div class="card card-body">
        <div class="sec-title">🎓 Education & Career</div>
        <div class="info-row"><span class="lbl">Education</span><span class="val"><?=$edu['ename']??'—'?></span></div>
        <div class="info-row"><span class="lbl">Profession</span><span class="val"><?=htmlspecialchars($edu['profession']??'—')?></span></div>
        <div class="info-row"><span class="lbl">Income</span><span class="val"><?=$edu['iname']??'—'?></span></div>
      </div>
      <?php endif;?>
    </div>

    <!-- Habits -->
    <?php if($hab):?>
    <div class="card card-body">
      <div class="sec-title">🏃 Physical & Lifestyle</div>
      <div class="grid-2">
        <div>
          <div class="info-row"><span class="lbl">Height</span><span class="val"><?=$hab['hname']??'—'?></span></div>
          <div class="info-row"><span class="lbl">Weight</span><span class="val"><?=htmlspecialchars($hab['weight']??'—')?></span></div>
          <div class="info-row"><span class="lbl">Marital Status</span><span class="val"><?=$hab['msname']??'—'?></span></div>
          <div class="info-row"><span class="lbl">Body Type</span><span class="val"><?=$hab['btname']??'—'?></span></div>
          <div class="info-row"><span class="lbl">Complexion</span><span class="val"><?=$hab['cname']??'—'?></span></div>
        </div>
        <div>
          <div class="info-row"><span class="lbl">Blood Group</span><span class="val"><?=$hab['bgname']??'—'?></span></div>
          <div class="info-row"><span class="lbl">Eating Habit</span><span class="val"><?=$hab['ehname']??'—'?></span></div>
          <div class="info-row"><span class="lbl">Smoking</span><span class="val"><?=$hab['shname']??'—'?></span></div>
          <div class="info-row"><span class="lbl">Drinking</span><span class="val"><?=$hab['dhname']??'—'?></span></div>
          <div class="info-row"><span class="lbl">Disability</span><span class="val"><?=$hab['dname']??'—'?></span></div>
        </div>
      </div>
    </div>
    <?php endif;?>

    <!-- Partner Preference -->
    <?php if($pref):?>
    <div class="card card-body">
      <div class="sec-title">💑 Partner Preference</div>
      <div class="grid-2">
        <div>
          <div class="info-row"><span class="lbl">Age Range</span><span class="val"><?=$pref['age_min']?> – <?=$pref['age_max']?> yrs</span></div>
          <div class="info-row"><span class="lbl">Religion</span><span class="val"><?=$pref['rname']??'Any'?></span></div>
        </div>
        <div>
          <div class="info-row"><span class="lbl">Height Range</span><span class="val"><?=($pref['hmin']??'Any').' – '.($pref['hmax']??'Any')?></span></div>
          <div class="info-row"><span class="lbl">Income</span><span class="val"><?=$pref['iname']??'Any'?></span></div>
        </div>
      </div>
    </div>
    <?php endif;?>

  </div>
</div>

<!-- Edit Modal -->
<div class="modal-bg" id="editModal">
  <div class="modal">
    <div class="modal-head">
      <h3>✏️ Edit Profile — <?=htmlspecialchars($user['full_name']??'User')?></h3>
      <button class="modal-close" onclick="closeModal('editModal')">✕</button>
    </div>
    <form method="POST">
      <div class="modal-body">
        <div class="grid-2">
          <div class="form-group">
            <label>Full Name</label>
            <input type="text" name="full_name" class="form-control" value="<?=htmlspecialchars($user['full_name']??'')?>">
          </div>
          <div class="form-group">
            <label>Gender</label>
            <select name="gender" class="form-control">
              <option value="">Select</option>
              <?php foreach(['Male','Female','Other'] as $g):?><option value="<?=$g?>" <?=$user['gender']===$g?'selected':''?>><?=$g?></option><?php endforeach;?>
            </select>
          </div>
          <div class="form-group">
            <label>Date of Birth</label>
            <input type="date" name="dob" class="form-control" value="<?=$user['dob']??''?>">
          </div>
          <div class="form-group">
            <label>Religion</label>
            <select name="religion_id" class="form-control">
              <option value="">Select</option>
              <?php foreach($religions as $r):?><option value="<?=$r['id']?>" <?=($rel['religion_id']??'')==$r['id']?'selected':''?>><?=htmlspecialchars($r['name'])?></option><?php endforeach;?>
            </select>
          </div>
          <div class="form-group">
            <label>Caste</label>
            <input type="text" name="caste" class="form-control" value="<?=htmlspecialchars($rel['caste']??'')?>">
          </div>
          <div class="form-group">
            <label>State</label>
            <select name="state_id" class="form-control">
              <option value="">Select</option>
              <?php foreach($states as $s):?><option value="<?=$s['id']?>" <?=($loc['state_id']??'')==$s['id']?'selected':''?>><?=htmlspecialchars($s['name'])?></option><?php endforeach;?>
            </select>
          </div>
          <div class="form-group">
            <label>City</label>
            <input type="text" name="city" class="form-control" value="<?=htmlspecialchars($loc['city']??'')?>">
          </div>
          <div class="form-group">
            <label>Education</label>
            <select name="education_id" class="form-control">
              <option value="">Select</option>
              <?php foreach($educations as $e):?><option value="<?=$e['id']?>" <?=($edu['education_id']??'')==$e['id']?'selected':''?>><?=htmlspecialchars($e['name'])?></option><?php endforeach;?>
            </select>
          </div>
          <div class="form-group">
            <label>Profession</label>
            <input type="text" name="profession" class="form-control" value="<?=htmlspecialchars($edu['profession']??'')?>">
          </div>
          <div class="form-group">
            <label>Income Range</label>
            <select name="income_id" class="form-control">
              <option value="">Select</option>
              <?php foreach($incomes as $inc):?><option value="<?=$inc['id']?>" <?=($edu['income_id']??'')==$inc['id']?'selected':''?>><?=htmlspecialchars($inc['name'])?></option><?php endforeach;?>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label>Bio</label>
          <textarea name="bio" class="form-control" rows="3"><?=htmlspecialchars($user['bio']??'')?></textarea>
        </div>
      </div>
      <div class="modal-foot">
        <button type="button" onclick="closeModal('editModal')" class="btn btn-secondary">Cancel</button>
        <button type="submit" class="btn btn-primary">💾 Save Changes</button>
      </div>
    </form>
  </div>
</div>

<?php include 'layout_end.php';?>
