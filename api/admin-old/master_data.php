<?php
require_once 'config.php';
requireLogin();
$pageTitle = 'Master Data';

$db = getDB();

// All manageable tables config
$tables = [
    'religions'         => ['label' => 'Religions',        'icon' => '🕉️',  'fields' => ['name']],
    'mother_tongues'    => ['label' => 'Mother Tongues',   'icon' => '🗣️',  'fields' => ['name']],
    'states'            => ['label' => 'States',           'icon' => '🗺️',  'fields' => ['name']],
    'education_levels'  => ['label' => 'Education Levels', 'icon' => '🎓',  'fields' => ['name']],
    'income_ranges'     => ['label' => 'Income Ranges',    'icon' => '💰',  'fields' => ['name']],
    'marital_statuses'  => ['label' => 'Marital Statuses', 'icon' => '💍',  'fields' => ['name']],
    'profile_for_options'=> ['label'=> 'Profile For',      'icon' => '👤',  'fields' => ['name']],
    'heights'           => ['label' => 'Heights',          'icon' => '📏',  'fields' => ['name', 'cm_value']],
    'eating_habits'     => ['label' => 'Eating Habits',    'icon' => '🍽️',  'fields' => ['name']],
    'smoking_habits'    => ['label' => 'Smoking Habits',   'icon' => '🚬',  'fields' => ['name']],
    'drinking_habits'   => ['label' => 'Drinking Habits',  'icon' => '🍺',  'fields' => ['name']],
    'body_types'        => ['label' => 'Body Types',        'icon' => '💪',  'fields' => ['name']],
    'complexions'       => ['label' => 'Complexions',      'icon' => '🎨',  'fields' => ['name']],
    'blood_groups'      => ['label' => 'Blood Groups',     'icon' => '🩸',  'fields' => ['name']],
    'disabilities'      => ['label' => 'Disabilities',     'icon' => '♿',  'fields' => ['name']],
    'country_codes'     => ['label' => 'Country Codes',    'icon' => '🌍',  'fields' => ['country_name', 'code']],
    'admins'            => ['label' => 'Admins',           'icon' => '👑',  'fields' => ['username', 'name']],
    'upgrade_plans'     => ['label' => 'Upgrade Plans',    'icon' => '💎',  'fields' => ['label', 'price', 'original_price', 'discount', 'profile_limit', 'duration_months']],
    'upgrade_features'  => ['label' => 'Upgrade Features', 'icon' => '⭐',  'fields' => ['title', 'description', 'icon']],
];

$activeTable = $_GET['table'] ?? 'religions';
if (!isset($tables[$activeTable])) $activeTable = 'religions';
$tableConfig = $tables[$activeTable];

$msg = '';
$error = '';

// Handle actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'add') {
        if ($activeTable === 'upgrade_plans') {
            $db->prepare("INSERT INTO upgrade_plans (label, price, original_price, discount, profile_limit, duration_months, is_best_value, sort_order, is_active) VALUES (?,?,?,?,?,?,?,?,1)")
              ->execute([trim($_POST['label']), trim($_POST['price']), trim($_POST['original_price']), trim($_POST['discount']), max(1, (int)($_POST['profile_limit'] ?? 2)), max(1, (int)($_POST['duration_months'] ?? 1)), isset($_POST['is_best_value']) ? 1 : 0, (int)($_POST['sort_order'] ?? 0)]);
            $msg = 'Added successfully';
        } elseif ($activeTable === 'upgrade_features') {
            $db->prepare("INSERT INTO upgrade_features (title, description, icon, sort_order, is_active) VALUES (?,?,?,?,1)")
               ->execute([trim($_POST['title']), trim($_POST['description']), trim($_POST['icon']), (int)($_POST['sort_order'] ?? 0)]);
            $msg = 'Added successfully';
        } elseif ($activeTable === 'admins') {
            if (empty($_POST['username']) || empty($_POST['password'])) {
                $error = 'Username and password are required';
            } else {
                try {
                    $db->prepare("INSERT INTO admins (username, name, password, is_active) VALUES (?,?,?,1)")
                       ->execute([trim($_POST['username']), trim($_POST['name'] ?? ''), password_hash($_POST['password'], PASSWORD_BCRYPT)]);
                    $msg = 'Admin added successfully';
                } catch (Exception $e) {
                    $error = 'Username already exists';
                }
            }
        } elseif ($activeTable === 'heights') {
            $db->prepare("INSERT INTO heights (name, cm_value, sort_order, is_active) VALUES (?,?,?,1)")
               ->execute([trim($_POST['name']), (int)$_POST['cm_value'], (int)($_POST['sort_order'] ?? 0)]);
            $msg = 'Added successfully';
        } elseif ($activeTable === 'country_codes') {
            $db->prepare("INSERT INTO country_codes (country_name, code, sort_order, is_active) VALUES (?,?,?,1)")
               ->execute([trim($_POST['country_name']), trim($_POST['code']), (int)($_POST['sort_order'] ?? 0)]);
            $msg = 'Added successfully';
        } else {
            $db->prepare("INSERT INTO $activeTable (name, sort_order, is_active) VALUES (?,?,1)")
               ->execute([trim($_POST['name']), (int)($_POST['sort_order'] ?? 0)]);
            $msg = 'Added successfully';
        }
    }

    if ($action === 'edit') {
        $id = (int)$_POST['id'];
        if ($activeTable === 'upgrade_plans') {
            $db->prepare("UPDATE upgrade_plans SET label=?, price=?, original_price=?, discount=?, profile_limit=?, duration_months=?, is_best_value=?, sort_order=? WHERE id=?")
              ->execute([trim($_POST['label']), trim($_POST['price']), trim($_POST['original_price']), trim($_POST['discount']), max(1, (int)($_POST['profile_limit'] ?? 2)), max(1, (int)($_POST['duration_months'] ?? 1)), isset($_POST['is_best_value']) ? 1 : 0, (int)($_POST['sort_order'] ?? 0), $id]);
            $msg = 'Updated successfully';
        } elseif ($activeTable === 'upgrade_features') {
            $db->prepare("UPDATE upgrade_features SET title=?, description=?, icon=?, sort_order=? WHERE id=?")
               ->execute([trim($_POST['title']), trim($_POST['description']), trim($_POST['icon']), (int)($_POST['sort_order'] ?? 0), $id]);
            $msg = 'Updated successfully';
        } elseif ($activeTable === 'admins') {
            if (!empty($_POST['password'])) {
                $db->prepare("UPDATE admins SET username=?, name=?, password=? WHERE id=?")
                   ->execute([trim($_POST['username']), trim($_POST['name']), password_hash($_POST['password'], PASSWORD_BCRYPT), $id]);
            } else {
                $db->prepare("UPDATE admins SET username=?, name=? WHERE id=?")
                   ->execute([trim($_POST['username']), trim($_POST['name']), $id]);
            }
            $msg = 'Admin updated';
        } elseif ($activeTable === 'heights') {
            $db->prepare("UPDATE heights SET name=?, cm_value=?, sort_order=? WHERE id=?")
               ->execute([trim($_POST['name']), (int)$_POST['cm_value'], (int)($_POST['sort_order'] ?? 0), $id]);
            $msg = 'Updated successfully';
        } elseif ($activeTable === 'country_codes') {
            $db->prepare("UPDATE country_codes SET country_name=?, code=?, sort_order=? WHERE id=?")
               ->execute([trim($_POST['country_name']), trim($_POST['code']), (int)($_POST['sort_order'] ?? 0), $id]);
            $msg = 'Updated successfully';
        } else {
            $db->prepare("UPDATE $activeTable SET name=?, sort_order=? WHERE id=?")
               ->execute([trim($_POST['name']), (int)($_POST['sort_order'] ?? 0), $id]);
            $msg = 'Updated successfully';
        }
    }

    if ($action === 'toggle') {
        $id = (int)$_POST['id'];
        $db->prepare("UPDATE $activeTable SET is_active = 1 - is_active WHERE id=?")->execute([$id]);
        $msg = 'Status updated';
    }

    header("Location: master_data.php?table=$activeTable&msg=" . urlencode($msg ?: $error));
    exit();
}

if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    try {
        $db->prepare("DELETE FROM $activeTable WHERE id=?")->execute([$_GET['delete']]);
        $msg = 'Deleted successfully';
    } catch (Exception $e) {
        $msg = 'Cannot delete - record is in use';
    }
    header("Location: master_data.php?table=$activeTable&msg=" . urlencode($msg));
    exit();
}

if (isset($_GET['msg'])) $msg = $_GET['msg'];

// Fetch data
$orderBy = in_array($activeTable, ['admins']) ? 'id' : 'sort_order, id';
$rows = $db->query("SELECT * FROM $activeTable ORDER BY $orderBy")->fetchAll();

include 'layout.php';
?>

<?php if ($msg): ?>
  <div class="alert <?= str_contains($msg, 'Cannot') || str_contains($msg, 'required') || str_contains($msg, 'exists') ? 'alert-error' : 'alert-success' ?>">
    <?= str_contains($msg, 'Cannot') || str_contains($msg, 'required') || str_contains($msg, 'exists') ? '⚠️' : '✅' ?> <?= htmlspecialchars($msg) ?>
  </div>
<?php endif; ?>

<!-- Table Tabs -->
<div style="display:flex;flex-wrap:wrap;gap:8px;margin-bottom:20px">
  <?php foreach ($tables as $tKey => $tConf): ?>
    <a href="?table=<?= $tKey ?>"
       style="padding:7px 14px;border-radius:20px;font-size:13px;font-weight:600;text-decoration:none;
              background:<?= $activeTable===$tKey ? '#E91E63' : '#fff' ?>;
              color:<?= $activeTable===$tKey ? '#fff' : '#555' ?>;
              border:1.5px solid <?= $activeTable===$tKey ? '#E91E63' : '#e0e0e0' ?>">
      <?= $tConf['icon'] ?> <?= $tConf['label'] ?>
    </a>
  <?php endforeach; ?>
</div>

<div class="table-card">
  <div class="table-header">
    <h2><?= $tableConfig['icon'] ?> <?= $tableConfig['label'] ?> (<?= count($rows) ?>)</h2>
    <button onclick="document.getElementById('addModal').classList.add('open')" class="btn btn-primary">
      + Add New
    </button>
  </div>

  <table>
    <thead>
      <tr>
        <th>#</th>
        <?php if ($activeTable === 'upgrade_plans'): ?>
          <th>Label</th><th>Price</th><th>Profiles</th><th>Months</th><th>Original Price</th><th>Discount</th><th>Best Value</th><th>Sort</th><th>Status</th>
        <?php elseif ($activeTable === 'upgrade_features'): ?>
          <th>Title</th><th>Description</th><th>Icon</th><th>Sort</th><th>Status</th>
        <?php elseif ($activeTable === 'admins'): ?>
          <th>Username</th><th>Name</th><th>Last Login</th><th>Status</th>
        <?php elseif ($activeTable === 'heights'): ?>
          <th>Height</th><th>CM Value</th><th>Sort Order</th><th>Status</th>
        <?php elseif ($activeTable === 'country_codes'): ?>
          <th>Country</th><th>Code</th><th>Sort Order</th><th>Status</th>
        <?php else: ?>
          <th>Name</th><th>Sort Order</th><th>Status</th>
        <?php endif; ?>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($rows as $i => $row): ?>
      <tr>
        <td style="color:#aaa"><?= $i + 1 ?></td>

        <?php if ($activeTable === 'upgrade_plans'): ?>
          <td><strong><?= htmlspecialchars($row['label']) ?></strong></td>
          <td><?= htmlspecialchars($row['price']) ?></td>
          <td><?= (int)$row['profile_limit'] ?></td>
          <td><?= (int)$row['duration_months'] ?></td>
          <td><s style="color:#aaa"><?= htmlspecialchars($row['original_price']) ?></s></td>
          <td><span class="badge badge-blue"><?= htmlspecialchars($row['discount']) ?></span></td>
          <td><?= $row['is_best_value'] ? '<span class="badge badge-green">Yes</span>' : '-' ?></td>
          <td><?= $row['sort_order'] ?></td>
          <td><span class="badge <?= $row['is_active'] ? 'badge-green' : 'badge-red' ?>"><?= $row['is_active'] ? 'Active' : 'Inactive' ?></span></td>

        <?php elseif ($activeTable === 'upgrade_features'): ?>
          <td><strong><?= htmlspecialchars($row['title']) ?></strong></td>
          <td style="font-size:12px;color:#666"><?= htmlspecialchars($row['description']) ?></td>
          <td><span class="badge badge-blue"><?= htmlspecialchars($row['icon']) ?></span></td>
          <td><?= $row['sort_order'] ?></td>
          <td><span class="badge <?= $row['is_active'] ? 'badge-green' : 'badge-red' ?>"><?= $row['is_active'] ? 'Active' : 'Inactive' ?></span></td>

        <?php elseif ($activeTable === 'admins'): ?>
          <td><strong><?= htmlspecialchars($row['username']) ?></strong></td>
          <td><?= htmlspecialchars($row['name'] ?? '-') ?></td>
          <td style="font-size:12px;color:#888"><?= $row['last_login'] ? date('d M Y H:i', strtotime($row['last_login'])) : 'Never' ?></td>
          <td><span class="badge <?= $row['is_active'] ? 'badge-green' : 'badge-red' ?>"><?= $row['is_active'] ? 'Active' : 'Inactive' ?></span></td>

        <?php elseif ($activeTable === 'heights'): ?>
          <td><strong><?= htmlspecialchars($row['name']) ?></strong></td>
          <td><?= $row['cm_value'] ?> cm</td>
          <td><?= $row['sort_order'] ?></td>
          <td><span class="badge <?= $row['is_active'] ? 'badge-green' : 'badge-red' ?>"><?= $row['is_active'] ? 'Active' : 'Inactive' ?></span></td>

        <?php elseif ($activeTable === 'country_codes'): ?>
          <td><strong><?= htmlspecialchars($row['country_name']) ?></strong></td>
          <td><span class="badge badge-blue"><?= htmlspecialchars($row['code']) ?></span></td>
          <td><?= $row['sort_order'] ?></td>
          <td><span class="badge <?= $row['is_active'] ? 'badge-green' : 'badge-red' ?>"><?= $row['is_active'] ? 'Active' : 'Inactive' ?></span></td>

        <?php else: ?>
          <td><strong><?= htmlspecialchars($row['name']) ?></strong></td>
          <td><?= $row['sort_order'] ?></td>
          <td><span class="badge <?= $row['is_active'] ? 'badge-green' : 'badge-red' ?>"><?= $row['is_active'] ? 'Active' : 'Inactive' ?></span></td>
        <?php endif; ?>

        <td style="display:flex;gap:6px">
          <button onclick="openEdit(<?= htmlspecialchars(json_encode($row)) ?>)" class="btn btn-info">Edit</button>
          <form method="POST" style="display:inline">
            <input type="hidden" name="action" value="toggle">
            <input type="hidden" name="id" value="<?= $row['id'] ?>">
            <button type="submit" class="btn" style="background:#fff3e0;color:#e65100">
              <?= $row['is_active'] ? 'Disable' : 'Enable' ?>
            </button>
          </form>
          <?php if ($activeTable !== 'admins' || $row['id'] != currentAdmin()['id']): ?>
          <a href="?table=<?= $activeTable ?>&delete=<?= $row['id'] ?>" class="btn btn-danger"
             onclick="return confirm('Delete this record?')">Delete</a>
          <?php endif; ?>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (empty($rows)): ?>
        <tr><td colspan="6" style="text-align:center;color:#aaa;padding:40px">No records found</td></tr>
      <?php endif; ?>
    </tbody>
  </table>
</div>

<!-- Add Modal -->
<div class="modal-overlay" id="addModal">
  <div class="modal">
    <h2>Add New - <?= $tableConfig['label'] ?></h2>
    <form method="POST">
      <input type="hidden" name="action" value="add">
      <?php if ($activeTable === 'upgrade_plans'): ?>
        <div class="form-group"><label>Label (e.g. 1 Month)</label><input type="text" name="label" required></div>
        <div class="form-group"><label>Price (e.g. ₹999)</label><input type="text" name="price" required></div>
        <div class="form-group"><label>Original Price (e.g. ₹1,999)</label><input type="text" name="original_price" required></div>
        <div class="form-group"><label>Discount (e.g. 50% OFF)</label><input type="text" name="discount" required></div>
        <div class="form-group"><label>Profile Limit</label><input type="number" name="profile_limit" value="2" min="1" required></div>
        <div class="form-group"><label>Duration (months)</label><input type="number" name="duration_months" value="1" min="1" required></div>
        <div class="form-group"><label><input type="checkbox" name="is_best_value" value="1"> Best Value?</label></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" value="0"></div>
      <?php elseif ($activeTable === 'upgrade_features'): ?>
        <div class="form-group"><label>Title</label><input type="text" name="title" required></div>
        <div class="form-group"><label>Description</label><input type="text" name="description" required></div>
        <div class="form-group"><label>Icon (Material icon name, e.g. star)</label><input type="text" name="icon" required></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" value="0"></div>
      <?php elseif ($activeTable === 'admins'): ?>
        <div class="form-group"><label>Username *</label><input type="text" name="username" required></div>
        <div class="form-group"><label>Full Name</label><input type="text" name="name"></div>
        <div class="form-group"><label>Password *</label><input type="password" name="password" required></div>
      <?php elseif ($activeTable === 'heights'): ?>
        <div class="form-group"><label>Height (e.g. 5'6")</label><input type="text" name="name" required></div>
        <div class="form-group"><label>CM Value</label><input type="number" name="cm_value" required></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" value="0"></div>
      <?php elseif ($activeTable === 'country_codes'): ?>
        <div class="form-group"><label>Country Name</label><input type="text" name="country_name" required></div>
        <div class="form-group"><label>Code (e.g. +91)</label><input type="text" name="code" required></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" value="0"></div>
      <?php else: ?>
        <div class="form-group"><label>Name *</label><input type="text" name="name" required></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" value="0"></div>
      <?php endif; ?>
      <div class="modal-footer">
        <button type="button" onclick="document.getElementById('addModal').classList.remove('open')"
                class="btn" style="background:#f5f5f5">Cancel</button>
        <button type="submit" class="btn btn-primary">Add</button>
      </div>
    </form>
  </div>
</div>

<!-- Edit Modal -->
<div class="modal-overlay" id="editModal">
  <div class="modal">
    <h2>Edit - <?= $tableConfig['label'] ?></h2>
    <form method="POST" id="editForm">
      <input type="hidden" name="action" value="edit">
      <input type="hidden" name="id" id="editId">
      <?php if ($activeTable === 'upgrade_plans'): ?>
        <div class="form-group"><label>Label</label><input type="text" name="label" id="editLabel" required></div>
        <div class="form-group"><label>Price</label><input type="text" name="price" id="editPrice" required></div>
        <div class="form-group"><label>Original Price</label><input type="text" name="original_price" id="editOriginalPrice" required></div>
        <div class="form-group"><label>Discount</label><input type="text" name="discount" id="editDiscount" required></div>
        <div class="form-group"><label>Profile Limit</label><input type="number" name="profile_limit" id="editProfileLimit" min="1" required></div>
        <div class="form-group"><label>Duration (months)</label><input type="number" name="duration_months" id="editDurationMonths" min="1" required></div>
        <div class="form-group"><label><input type="checkbox" name="is_best_value" id="editBestValue" value="1"> Best Value?</label></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" id="editSort"></div>
      <?php elseif ($activeTable === 'upgrade_features'): ?>
        <div class="form-group"><label>Title</label><input type="text" name="title" id="editTitle" required></div>
        <div class="form-group"><label>Description</label><input type="text" name="description" id="editDescription" required></div>
        <div class="form-group"><label>Icon</label><input type="text" name="icon" id="editIcon" required></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" id="editSort"></div>
      <?php elseif ($activeTable === 'admins'): ?>
        <div class="form-group"><label>Username *</label><input type="text" name="username" id="editUsername" required></div>
        <div class="form-group"><label>Full Name</label><input type="text" name="name" id="editName"></div>
        <div class="form-group"><label>New Password <small style="color:#aaa">(leave blank to keep current)</small></label><input type="password" name="password" id="editPassword"></div>
      <?php elseif ($activeTable === 'heights'): ?>
        <div class="form-group"><label>Height</label><input type="text" name="name" id="editName" required></div>
        <div class="form-group"><label>CM Value</label><input type="number" name="cm_value" id="editCm" required></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" id="editSort"></div>
      <?php elseif ($activeTable === 'country_codes'): ?>
        <div class="form-group"><label>Country Name</label><input type="text" name="country_name" id="editCountry" required></div>
        <div class="form-group"><label>Code</label><input type="text" name="code" id="editCode" required></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" id="editSort"></div>
      <?php else: ?>
        <div class="form-group"><label>Name *</label><input type="text" name="name" id="editName" required></div>
        <div class="form-group"><label>Sort Order</label><input type="number" name="sort_order" id="editSort"></div>
      <?php endif; ?>
      <div class="modal-footer">
        <button type="button" onclick="document.getElementById('editModal').classList.remove('open')"
                class="btn" style="background:#f5f5f5">Cancel</button>
        <button type="submit" class="btn btn-primary">Save Changes</button>
      </div>
    </form>
  </div>
</div>

<script>
function openEdit(row) {
  document.getElementById('editId').value = row.id;
  if (document.getElementById('editName'))          document.getElementById('editName').value          = row.name || row.country_name || row.username || '';
  if (document.getElementById('editSort'))          document.getElementById('editSort').value          = row.sort_order || 0;
  if (document.getElementById('editCm'))            document.getElementById('editCm').value            = row.cm_value || '';
  if (document.getElementById('editCode'))          document.getElementById('editCode').value          = row.code || '';
  if (document.getElementById('editCountry'))       document.getElementById('editCountry').value       = row.country_name || '';
  if (document.getElementById('editUsername'))      document.getElementById('editUsername').value      = row.username || '';
  if (document.getElementById('editPassword'))      document.getElementById('editPassword').value      = '';
  if (document.getElementById('editLabel'))         document.getElementById('editLabel').value         = row.label || '';
  if (document.getElementById('editPrice'))         document.getElementById('editPrice').value         = row.price || '';
  if (document.getElementById('editOriginalPrice')) document.getElementById('editOriginalPrice').value = row.original_price || '';
  if (document.getElementById('editDiscount'))      document.getElementById('editDiscount').value      = row.discount || '';
  if (document.getElementById('editProfileLimit'))  document.getElementById('editProfileLimit').value  = row.profile_limit || 2;
  if (document.getElementById('editDurationMonths')) document.getElementById('editDurationMonths').value = row.duration_months || 1;
  if (document.getElementById('editBestValue'))     document.getElementById('editBestValue').checked   = row.is_best_value == 1;
  if (document.getElementById('editTitle'))         document.getElementById('editTitle').value         = row.title || '';
  if (document.getElementById('editDescription'))   document.getElementById('editDescription').value   = row.description || '';
  if (document.getElementById('editIcon'))          document.getElementById('editIcon').value          = row.icon || '';
  document.getElementById('editModal').classList.add('open');
}
// Close modal on overlay click
document.querySelectorAll('.modal-overlay').forEach(el => {
  el.addEventListener('click', function(e) {
    if (e.target === this) this.classList.remove('open');
  });
});
</script>

<?php include 'layout_end.php'; ?>
