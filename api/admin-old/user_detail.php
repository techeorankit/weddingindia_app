<?php
require_once 'config.php';
requireLogin();

$id = (int)($_GET['id'] ?? 0);
if (!$id) { header('Location: users.php'); exit(); }

$db = getDB();

// Handle profile update from admin
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $db->prepare("UPDATE user_profiles SET full_name=?, gender=?, dob=?, bio=? WHERE user_id=?")
       ->execute([$_POST['full_name'], $_POST['gender'], $_POST['dob'] ?: null, $_POST['bio'], $id]);
    $db->prepare("UPDATE user_religion SET religion_id=?, caste=? WHERE user_id=?")
       ->execute([$_POST['religion_id'] ?: null, $_POST['caste'], $id]);
    $db->prepare("UPDATE user_location SET state_id=?, city=? WHERE user_id=?")
       ->execute([$_POST['state_id'] ?: null, $_POST['city'], $id]);
    $db->prepare("UPDATE user_education SET education_id=?, profession=?, income_id=? WHERE user_id=?")
       ->execute([$_POST['education_id'] ?: null, $_POST['profession'], $_POST['income_id'] ?: null, $id]);
    header("Location: user_detail.php?id=$id&msg=saved");
    exit();
}

// Fetch full profile
$user = $db->prepare("SELECT u.*, p.full_name, p.gender, p.dob, p.bio, p.profile_photo, p.is_profile_complete
    FROM users u LEFT JOIN user_profiles p ON p.user_id=u.id WHERE u.id=?");
$user->execute([$id]);
$user = $user->fetch();
if (!$user) { header('Location: users.php'); exit(); }

$religion = $db->prepare("SELECT ur.*, r.name as religion_name, mt.name as mother_tongue_name
    FROM user_religion ur
    LEFT JOIN religions r ON r.id=ur.religion_id
    LEFT JOIN mother_tongues mt ON mt.id=ur.mother_tongue_id
    WHERE ur.user_id=?");
$religion->execute([$id]);
$religion = $religion->fetch();

$location = $db->prepare("SELECT ul.*, s.name as state_name FROM user_location ul LEFT JOIN states s ON s.id=ul.state_id WHERE ul.user_id=?");
$location->execute([$id]);
$location = $location->fetch();

$education = $db->prepare("SELECT ue.*, el.name as edu_name, ir.name as income_name
    FROM user_education ue
    LEFT JOIN education_levels el ON el.id=ue.education_id
    LEFT JOIN income_ranges ir ON ir.id=ue.income_id
    WHERE ue.user_id=?");
$education->execute([$id]);
$education = $education->fetch();

$habits = $db->prepare("SELECT uh.*, h.name as height_name, ms.name as marital_name,
    eh.name as eating_name, sh.name as smoking_name, dh.name as drinking_name,
    bt.name as body_name, c.name as complexion_name, bg.name as blood_name, d.name as disability_name
    FROM user_habits uh
    LEFT JOIN heights h ON h.id=uh.height_id
    LEFT JOIN marital_statuses ms ON ms.id=uh.marital_status_id
    LEFT JOIN eating_habits eh ON eh.id=uh.eating_habit_id
    LEFT JOIN smoking_habits sh ON sh.id=uh.smoking_habit_id
    LEFT JOIN drinking_habits dh ON dh.id=uh.drinking_habit_id
    LEFT JOIN body_types bt ON bt.id=uh.body_type_id
    LEFT JOIN complexions c ON c.id=uh.complexion_id
    LEFT JOIN blood_groups bg ON bg.id=uh.blood_group_id
    LEFT JOIN disabilities d ON d.id=uh.disability_id
    WHERE uh.user_id=?");
$habits->execute([$id]);
$habits = $habits->fetch();

$photos = $db->prepare("SELECT * FROM user_photos WHERE user_id=? ORDER BY is_primary DESC");
$photos->execute([$id]);
$photos = $photos->fetchAll();

// Dropdowns for edit form
$religions   = $db->query("SELECT id, name FROM religions ORDER BY sort_order")->fetchAll();
$states      = $db->query("SELECT id, name FROM states ORDER BY sort_order")->fetchAll();
$educations  = $db->query("SELECT id, name FROM education_levels ORDER BY sort_order")->fetchAll();
$incomes     = $db->query("SELECT id, name FROM income_ranges ORDER BY sort_order")->fetchAll();

$pageTitle = 'User Detail';
include 'layout.php';
?>

<?php if (isset($_GET['msg'])): ?>
  <div class="alert alert-success">✅ Profile updated successfully</div>
<?php endif; ?>

<div style="display:flex;gap:8px;margin-bottom:20px">
  <a href="users.php" class="btn" style="background:#f5f5f5">← Back</a>
  <button onclick="document.getElementById('editModal').classList.add('open')" class="btn btn-primary">✏️ Edit Profile</button>
  <a href="users.php?delete=<?= $id ?>" class="btn btn-danger" onclick="return confirm('Delete this user?')">🗑️ Delete User</a>
</div>

<div style="display:grid;grid-template-columns:300px 1fr;gap:20px">

  <!-- Left: Profile Card -->
  <div>
    <div class="table-card" style="padding:24px;text-align:center">
      <div style="width:90px;height:90px;border-radius:50%;background:#fce4ec;color:#E91E63;font-size:36px;font-weight:700;display:flex;align-items:center;justify-content:center;margin:0 auto 12px;overflow:hidden">
        <?php if ($user['profile_photo']): ?>
          <img src="../uploads/<?= htmlspecialchars($user['profile_photo']) ?>" style="width:100%;height:100%;object-fit:cover">
        <?php else: ?>
          <?= strtoupper(substr($user['full_name'] ?? $user['phone'], 0, 1)) ?>
        <?php endif; ?>
      </div>
      <h2 style="font-size:18px;font-weight:700"><?= htmlspecialchars($user['full_name'] ?? 'No Name') ?></h2>
      <p style="color:#888;font-size:13px;margin-top:4px"><?= $user['country_code'] . ' ' . $user['phone'] ?></p>
      <div style="margin-top:12px;display:flex;gap:8px;justify-content:center;flex-wrap:wrap">
        <span class="badge <?= $user['is_verified'] ? 'badge-green' : 'badge-red' ?>">
          <?= $user['is_verified'] ? '✅ Verified' : '❌ Unverified' ?>
        </span>
        <span class="badge <?= $user['is_profile_complete'] ? 'badge-blue' : 'badge-orange' ?>">
          <?= $user['is_profile_complete'] ? 'Profile Complete' : 'Incomplete' ?>
        </span>
      </div>
      <div style="margin-top:16px;font-size:12px;color:#aaa">
        Joined: <?= date('d M Y', strtotime($user['created_at'])) ?>
      </div>
    </div>

    <?php if ($photos): ?>
    <div class="table-card" style="padding:16px;margin-top:16px">
      <div style="font-weight:700;margin-bottom:12px">Photos (<?= count($photos) ?>)</div>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:6px">
        <?php foreach ($photos as $ph): ?>
          <img src="../uploads/<?= htmlspecialchars($ph['photo_path']) ?>"
               style="width:100%;aspect-ratio:1;object-fit:cover;border-radius:8px">
        <?php endforeach; ?>
      </div>
    </div>
    <?php endif; ?>
  </div>

  <!-- Right: Details -->
  <div style="display:flex;flex-direction:column;gap:16px">

    <?php
    function infoRow($label, $value) {
        if (!$value) return;
        echo "<div style='display:flex;padding:10px 0;border-bottom:1px solid #f5f5f5'>
            <span style='width:160px;color:#888;font-size:13px'>$label</span>
            <span style='font-size:14px;font-weight:500'>" . htmlspecialchars($value) . "</span>
          </div>";
    }
    ?>

    <div class="table-card" style="padding:20px">
      <div style="font-weight:700;color:#E91E63;margin-bottom:12px">Basic Info</div>
      <?php infoRow('Full Name', $user['full_name']); ?>
      <?php infoRow('Gender', $user['gender']); ?>
      <?php infoRow('Date of Birth', $user['dob'] ? date('d M Y', strtotime($user['dob'])) : null); ?>
      <?php infoRow('Bio', $user['bio']); ?>
    </div>

    <?php if ($religion): ?>
    <div class="table-card" style="padding:20px">
      <div style="font-weight:700;color:#E91E63;margin-bottom:12px">Religion & Community</div>
      <?php infoRow('Religion', $religion['religion_name']); ?>
      <?php infoRow('Caste', $religion['caste']); ?>
      <?php infoRow('Mother Tongue', $religion['mother_tongue_name']); ?>
    </div>
    <?php endif; ?>

    <?php if ($location): ?>
    <div class="table-card" style="padding:20px">
      <div style="font-weight:700;color:#E91E63;margin-bottom:12px">Location</div>
      <?php infoRow('State', $location['state_name']); ?>
      <?php infoRow('City', $location['city']); ?>
    </div>
    <?php endif; ?>

    <?php if ($education): ?>
    <div class="table-card" style="padding:20px">
      <div style="font-weight:700;color:#E91E63;margin-bottom:12px">Education & Career</div>
      <?php infoRow('Education', $education['edu_name']); ?>
      <?php infoRow('Profession', $education['profession']); ?>
      <?php infoRow('Income', $education['income_name']); ?>
    </div>
    <?php endif; ?>

    <?php if ($habits): ?>
    <div class="table-card" style="padding:20px">
      <div style="font-weight:700;color:#E91E63;margin-bottom:12px">Physical & Lifestyle</div>
      <?php infoRow('Height', $habits['height_name']); ?>
      <?php infoRow('Weight', $habits['weight']); ?>
      <?php infoRow('Marital Status', $habits['marital_name']); ?>
      <?php infoRow('Eating Habit', $habits['eating_name']); ?>
      <?php infoRow('Smoking', $habits['smoking_name']); ?>
      <?php infoRow('Drinking', $habits['drinking_name']); ?>
      <?php infoRow('Body Type', $habits['body_name']); ?>
      <?php infoRow('Complexion', $habits['complexion_name']); ?>
      <?php infoRow('Blood Group', $habits['blood_name']); ?>
      <?php infoRow('Disability', $habits['disability_name']); ?>
    </div>
    <?php endif; ?>

  </div>
</div>

<!-- Edit Modal -->
<div class="modal-overlay" id="editModal">
  <div class="modal" style="max-width:600px">
    <h2>Edit Profile</h2>
    <form method="POST">
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
        <div class="form-group">
          <label>Full Name</label>
          <input type="text" name="full_name" value="<?= htmlspecialchars($user['full_name'] ?? '') ?>">
        </div>
        <div class="form-group">
          <label>Gender</label>
          <select name="gender">
            <option value="">Select</option>
            <?php foreach (['Male','Female','Other'] as $g): ?>
              <option value="<?= $g ?>" <?= $user['gender'] === $g ? 'selected' : '' ?>><?= $g ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="form-group">
          <label>Date of Birth</label>
          <input type="date" name="dob" value="<?= $user['dob'] ?? '' ?>">
        </div>
        <div class="form-group">
          <label>Religion</label>
          <select name="religion_id">
            <option value="">Select</option>
            <?php foreach ($religions as $r): ?>
              <option value="<?= $r['id'] ?>" <?= ($religion['religion_id'] ?? '') == $r['id'] ? 'selected' : '' ?>><?= $r['name'] ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="form-group">
          <label>Caste</label>
          <input type="text" name="caste" value="<?= htmlspecialchars($religion['caste'] ?? '') ?>">
        </div>
        <div class="form-group">
          <label>State</label>
          <select name="state_id">
            <option value="">Select</option>
            <?php foreach ($states as $s): ?>
              <option value="<?= $s['id'] ?>" <?= ($location['state_id'] ?? '') == $s['id'] ? 'selected' : '' ?>><?= $s['name'] ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="form-group">
          <label>City</label>
          <input type="text" name="city" value="<?= htmlspecialchars($location['city'] ?? '') ?>">
        </div>
        <div class="form-group">
          <label>Education</label>
          <select name="education_id">
            <option value="">Select</option>
            <?php foreach ($educations as $e): ?>
              <option value="<?= $e['id'] ?>" <?= ($education['education_id'] ?? '') == $e['id'] ? 'selected' : '' ?>><?= $e['name'] ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="form-group">
          <label>Profession</label>
          <input type="text" name="profession" value="<?= htmlspecialchars($education['profession'] ?? '') ?>">
        </div>
        <div class="form-group">
          <label>Income</label>
          <select name="income_id">
            <option value="">Select</option>
            <?php foreach ($incomes as $inc): ?>
              <option value="<?= $inc['id'] ?>" <?= ($education['income_id'] ?? '') == $inc['id'] ? 'selected' : '' ?>><?= $inc['name'] ?></option>
            <?php endforeach; ?>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label>Bio</label>
        <textarea name="bio" rows="3"><?= htmlspecialchars($user['bio'] ?? '') ?></textarea>
      </div>
      <div class="modal-footer">
        <button type="button" onclick="document.getElementById('editModal').classList.remove('open')"
                class="btn" style="background:#f5f5f5">Cancel</button>
        <button type="submit" class="btn btn-primary">Save Changes</button>
      </div>
    </form>
  </div>
</div>

<?php include 'layout_end.php'; ?>
