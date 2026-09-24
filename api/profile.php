<?php

require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? '';
$userId = getAuthUserId(); 

switch ($action) {
    case 'save_profile_for': saveProfileFor($userId); break;
    case 'save_basic':       saveBasicDetails($userId); break;
    case 'save_religion':    saveReligion($userId); break;
    case 'save_location':    saveLocation($userId); break;
    case 'save_education':   saveEducation($userId); break;
    case 'save_habits':      saveHabits($userId); break;
    case 'save_preference':  savePartnerPreference($userId); break;
    case 'save_about':       saveAboutMe($userId); break;
    case 'update_profile':  updateProfile($userId); break;
    case 'upload_photo':     uploadPhoto($userId); break;
    case 'delete_photo':     deletePhoto($userId); break;
    case 'set_primary_photo': setPrimaryPhoto($userId); break;
    case 'get_phone':        getPhone($userId); break;
    case 'get':              getProfile($userId); break;
    default: sendError(404, 'Invalid action');
}

function saveProfileFor($userId) {
    $input = getInput();
    $profileFor = trim($input['profile_for'] ?? '');

    $allowed = ['Myself', 'Son', 'Daughter', 'Brother', 'Sister', 'Friend'];
    if (!in_array($profileFor, $allowed)) {
        sendError(400, 'Invalid profile_for value');
    }

    $db = getDB();
    $stmt = $db->prepare("INSERT INTO user_profiles (user_id, profile_for) VALUES (?, ?)
                          ON DUPLICATE KEY UPDATE profile_for = VALUES(profile_for)");
    $stmt->execute([$userId, $profileFor]);

    sendSuccess(['profile_for' => $profileFor], 'Profile For saved');
}

function saveBasicDetails($userId) {
    $input = getInput();
    $fullName = trim($input['full_name'] ?? '');
    $dob      = trim($input['dob'] ?? '');        // Format: YYYY-MM-DD
    $gender   = trim($input['gender'] ?? '');

    if (empty($fullName)) sendError(400, 'Full name is required');
    if (empty($dob) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $dob)) {
        sendError(400, 'Valid date of birth required (YYYY-MM-DD format)');
    }
    if (!in_array($gender, ['Male', 'Female', 'Other'])) {
        sendError(400, 'Gender must be Male, Female, or Other');
    }

    $db = getDB();
    $stmt = $db->prepare("INSERT INTO user_profiles (user_id, full_name, dob, gender)
                          VALUES (?, ?, ?, ?)
                          ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), dob = VALUES(dob), gender = VALUES(gender)");
    $stmt->execute([$userId, $fullName, $dob, $gender]);

    sendSuccess([], 'Basic details saved');
}

// ============================================================
// Religion & Community Save
// ============================================================
function saveReligion($userId) {
    $input = getInput();
    $religionId     = isset($input['religion_id']) ? (int)$input['religion_id'] : null;
    $caste          = trim($input['caste'] ?? '');
    $motherTongueId = isset($input['mother_tongue_id']) ? (int)$input['mother_tongue_id'] : null;

    $db = getDB();

    // Check existing record hai ya nahi
    $stmt = $db->prepare("SELECT id FROM user_religion WHERE user_id = ?");
    $stmt->execute([$userId]);
    $existing = $stmt->fetch();

    if ($existing) {
        // Sirf jo fields bheje gaye hain unhe update karo
        $updates = [];
        $params  = [];

        if ($religionId !== null && $religionId > 0) {
            $updates[] = 'religion_id = ?';
            $params[]  = $religionId;
        }
        if ($caste !== '') {
            $updates[] = 'caste = ?';
            $params[]  = $caste;
        }
        if ($motherTongueId !== null && $motherTongueId > 0) {
            $updates[] = 'mother_tongue_id = ?';
            $params[]  = $motherTongueId;
        }

        if (!empty($updates)) {
            $params[] = $userId;
            $sql = "UPDATE user_religion SET " . implode(', ', $updates) . " WHERE user_id = ?";
            $stmt = $db->prepare($sql);
            $stmt->execute($params);
        }
    } else {
        // Naya record insert karo
        if ($religionId === null || $religionId <= 0) {
            sendError(400, 'religion_id is required for first time');
        }
        $stmt = $db->prepare("INSERT INTO user_religion (user_id, religion_id, caste, mother_tongue_id)
                              VALUES (?, ?, ?, ?)");
        $stmt->execute([$userId, $religionId, $caste ?: null, $motherTongueId]);
    }

    sendSuccess([], 'Religion details saved');
}

// ============================================================
// Location Save
// ============================================================
function saveLocation($userId) {
    $input   = getInput();
    $stateId = (int)($input['state_id'] ?? 0);
    $city    = trim($input['city'] ?? '');

    if ($stateId <= 0) sendError(400, 'state_id is required');
    if (empty($city)) sendError(400, 'City is required');

    $db = getDB();
    $stmt = $db->prepare("SELECT id FROM states WHERE id = ? AND is_active = 1");
    $stmt->execute([$stateId]);
    if (!$stmt->fetch()) sendError(400, 'Invalid state_id');

    $stmt = $db->prepare("INSERT INTO user_location (user_id, state_id, city)
                          VALUES (?, ?, ?)
                          ON DUPLICATE KEY UPDATE state_id = VALUES(state_id), city = VALUES(city)");
    $stmt->execute([$userId, $stateId, $city]);

    sendSuccess([], 'Location saved');
}

// ============================================================
// Education & Career Save
// ============================================================
function saveEducation($userId) {
    $input       = getInput();
    $educationId = (int)($input['education_id'] ?? 0);
    $profession  = trim($input['profession'] ?? '');
    $incomeId    = isset($input['income_id']) ? (int)$input['income_id'] : null;

    if ($educationId <= 0) sendError(400, 'education_id is required');

    $db = getDB();
    $stmt = $db->prepare("SELECT id FROM education_levels WHERE id = ? AND is_active = 1");
    $stmt->execute([$educationId]);
    if (!$stmt->fetch()) sendError(400, 'Invalid education_id');

    $stmt = $db->prepare("INSERT INTO user_education (user_id, education_id, profession, income_id)
                          VALUES (?, ?, ?, ?)
                          ON DUPLICATE KEY UPDATE education_id = VALUES(education_id),
                          profession = VALUES(profession), income_id = VALUES(income_id)");
    $stmt->execute([$userId, $educationId, $profession ?: null, $incomeId]);

    sendSuccess([], 'Education details saved');
}

// ============================================================
// Habits & Physical Details Save
// ============================================================
function saveHabits($userId) {
    $input = getInput();

    $heightId        = isset($input['height_id'])         ? (int)$input['height_id']         : null;
    $weight          = trim($input['weight'] ?? '');
    $eatingHabitId   = isset($input['eating_habit_id'])   ? (int)$input['eating_habit_id']   : null;
    $smokingHabitId  = isset($input['smoking_habit_id'])  ? (int)$input['smoking_habit_id']  : null;
    $drinkingHabitId = isset($input['drinking_habit_id']) ? (int)$input['drinking_habit_id'] : null;
    $disabilityId    = isset($input['disability_id'])     ? (int)$input['disability_id']     : null;
    $maritalStatusId = isset($input['marital_status_id']) ? (int)$input['marital_status_id'] : null;
    $bodyTypeId      = isset($input['body_type_id'])      ? (int)$input['body_type_id']      : null;
    $complexionId    = isset($input['complexion_id'])     ? (int)$input['complexion_id']     : null;
    $bloodGroupId    = isset($input['blood_group_id'])    ? (int)$input['blood_group_id']    : null;

    $db = getDB();
    $stmt = $db->prepare("INSERT INTO user_habits
        (user_id, height_id, weight, eating_habit_id, smoking_habit_id, drinking_habit_id,
         disability_id, marital_status_id, body_type_id, complexion_id, blood_group_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        height_id = VALUES(height_id), weight = VALUES(weight),
        eating_habit_id = VALUES(eating_habit_id), smoking_habit_id = VALUES(smoking_habit_id),
        drinking_habit_id = VALUES(drinking_habit_id), disability_id = VALUES(disability_id),
        marital_status_id = VALUES(marital_status_id), body_type_id = VALUES(body_type_id),
        complexion_id = VALUES(complexion_id), blood_group_id = VALUES(blood_group_id)");

    $stmt->execute([
        $userId, $heightId, $weight ?: null, $eatingHabitId, $smokingHabitId,
        $drinkingHabitId, $disabilityId, $maritalStatusId, $bodyTypeId, $complexionId, $bloodGroupId
    ]);

    sendSuccess([], 'Habits & details saved');
}

// ============================================================
// Partner Preference Save
// ============================================================
function savePartnerPreference($userId) {
    $input = getInput();

    $ageMin      = max(18, (int)($input['age_min'] ?? 18));
    $ageMax      = min(60, (int)($input['age_max'] ?? 35));
    $religionId  = isset($input['religion_id'])   ? (int)$input['religion_id']  : null;
    $minHeightId = isset($input['min_height_id'])  ? (int)$input['min_height_id'] : null;
    $maxHeightId = isset($input['max_height_id'])  ? (int)$input['max_height_id'] : null;
    $incomeId    = isset($input['income_id'])      ? (int)$input['income_id']    : null;

    if ($ageMin > $ageMax) sendError(400, 'age_min cannot be greater than age_max');

    $db = getDB();
    $stmt = $db->prepare("INSERT INTO user_partner_preference
        (user_id, age_min, age_max, religion_id, min_height_id, max_height_id, income_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        age_min = VALUES(age_min), age_max = VALUES(age_max),
        religion_id = VALUES(religion_id), min_height_id = VALUES(min_height_id),
        max_height_id = VALUES(max_height_id), income_id = VALUES(income_id)");

    $stmt->execute([$userId, $ageMin, $ageMax, $religionId, $minHeightId, $maxHeightId, $incomeId]);

    sendSuccess([], 'Partner preference saved');
}

// ============================================================
// About Me / Bio Save
// ============================================================
function saveAboutMe($userId) {
    $input = getInput();
    $bio   = trim($input['bio'] ?? '');

    if (strlen($bio) < 20) sendError(400, 'Bio must be at least 20 characters');
    if (strlen($bio) > 500) sendError(400, 'Bio cannot exceed 500 characters');

    $db = getDB();
    $stmt = $db->prepare("INSERT INTO user_profiles (user_id, bio) VALUES (?, ?)
                          ON DUPLICATE KEY UPDATE bio = VALUES(bio)");
    $stmt->execute([$userId, $bio]);

    // Profile complete mark karo
    markProfileComplete($db, $userId);

    sendSuccess([], 'About me saved');
}

function updateProfile($userId) {
    $input = getInput();
    $fields = [];
    $params = [];

    if (array_key_exists('full_name', $input)) {
        $fullName = trim((string)$input['full_name']);
        if ($fullName === '') sendError(400, 'Full name is required');
        $fields[] = 'full_name = ?';
        $params[] = $fullName;
    }
    if (array_key_exists('dob', $input)) {
        $dob = trim((string)$input['dob']);
        if ($dob === '' || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $dob)) {
            sendError(400, 'Valid date of birth required (YYYY-MM-DD format)');
        }
        $fields[] = 'dob = ?';
        $params[] = $dob;
    }
    if (array_key_exists('gender', $input)) {
        $gender = trim((string)$input['gender']);
        if (!in_array($gender, ['Male', 'Female', 'Other'], true)) {
            sendError(400, 'Gender must be Male, Female, or Other');
        }
        $fields[] = 'gender = ?';
        $params[] = $gender;
    }
    if (array_key_exists('profile_for', $input)) {
        $profileFor = trim((string)$input['profile_for']);
        if (!in_array($profileFor, ['Myself', 'Son', 'Daughter', 'Brother', 'Sister', 'Friend'], true)) {
            sendError(400, 'Invalid profile_for value');
        }
        $fields[] = 'profile_for = ?';
        $params[] = $profileFor;
    }
    if (array_key_exists('bio', $input)) {
        $bio = trim((string)$input['bio']);
        if (strlen($bio) > 500) sendError(400, 'Bio cannot exceed 500 characters');
        $fields[] = 'bio = ?';
        $params[] = $bio !== '' ? $bio : null;
    }

    // ── Family Details ─────────────────────────────────────────────────────
    $validMotherOcc = ['Housewife', 'Business Woman', 'Job', 'Retired', 'Not Alive'];
    $validFatherOcc = ['Business Man', 'Job', 'Retired', 'Not Alive'];
    if (array_key_exists('mother_occupation', $input)) {
        $val = trim((string)$input['mother_occupation']);
        $fields[] = 'mother_occupation = ?';
        $params[] = $val !== '' ? $val : null;
    }
    if (array_key_exists('father_occupation', $input)) {
        $val = trim((string)$input['father_occupation']);
        $fields[] = 'father_occupation = ?';
        $params[] = $val !== '' ? $val : null;
    }
    if (array_key_exists('brothers', $input)) {
        $fields[] = 'brothers = ?';
        $params[] = $input['brothers'] !== null && $input['brothers'] !== '' ? (int)$input['brothers'] : null;
    }
    if (array_key_exists('sisters', $input)) {
        $fields[] = 'sisters = ?';
        $params[] = $input['sisters'] !== null && $input['sisters'] !== '' ? (int)$input['sisters'] : null;
    }

    if (empty($fields)) sendError(400, 'No profile fields supplied');

    $db = getDB();
    $params[] = $userId;
    $stmt = $db->prepare('UPDATE user_profiles SET ' . implode(', ', $fields) . ' WHERE user_id = ?');
    $stmt->execute($params);

    sendSuccess([], 'Profile updated successfully');
}

// ============================================================
// Photo Upload
// ============================================================
function uploadPhoto($userId) {
    // Accept the legacy field name too, so older app builds can still upload.
    $file = $_FILES['photo'] ?? $_FILES['profile_photo'] ?? null;
    if (empty($file)) {
        sendError(400, 'Photo file is required');
    }

    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        $uploadErrors = [
            UPLOAD_ERR_INI_SIZE => 'Photo exceeds the server upload limit',
            UPLOAD_ERR_FORM_SIZE => 'Photo exceeds the form upload limit',
            UPLOAD_ERR_PARTIAL => 'Photo upload was incomplete',
            UPLOAD_ERR_NO_FILE => 'Photo file is required',
        ];
        sendError(400, $uploadErrors[$file['error']] ?? 'Photo upload failed');
    }

    if ($file['size'] > MAX_FILE_SIZE) {
        sendError(400, 'File size cannot exceed 5MB');
    }

    // Detect the actual file contents. Client-provided MIME types are unreliable.
    $imageInfo = @getimagesize($file['tmp_name']);
    $detectedType = $imageInfo['mime'] ?? '';
    $allowedTypes = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];
    if (!$imageInfo || !isset($allowedTypes[$detectedType])) {
        sendError(400, 'Only JPG, PNG, WebP images allowed');
    }

    // Upload directory create karo
    if (!is_dir(UPLOAD_DIR)) {
        if (!mkdir(UPLOAD_DIR, 0755, true) && !is_dir(UPLOAD_DIR)) {
            sendError(500, 'Upload directory could not be created');
        }
    }

    $ext      = $allowedTypes[$detectedType];
    $filename = 'user_' . $userId . '_' . time() . '.' . $ext;
    $filepath = UPLOAD_DIR . $filename;

    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        sendError(500, 'Failed to upload photo');
    }

    $db = getDB();

    // Max 5 photos check
    $cnt = $db->prepare("SELECT COUNT(*) FROM user_photos WHERE user_id = ?");
    $cnt->execute([$userId]);
    if ((int)$cnt->fetchColumn() >= 5) {
        sendError(400, 'Maximum 5 photos allowed. Please delete one to add more.');
    }

    // First photo = primary, others not
    $existingCount = (int)$db->prepare("SELECT COUNT(*) FROM user_photos WHERE user_id = ?")->execute([$userId]);
    $cntS = $db->prepare("SELECT COUNT(*) FROM user_photos WHERE user_id = ?");
    $cntS->execute([$userId]);
    $isPrimary = (int)$cntS->fetchColumn() === 0 ? 1 : 0;

    if ($isPrimary) {
        // Remove any stale primary flags
        $db->prepare("UPDATE user_photos SET is_primary = 0 WHERE user_id = ?")->execute([$userId]);
    }

    $stmt = $db->prepare("INSERT INTO user_photos (user_id, photo_path, is_primary) VALUES (?, ?, ?)");
    $stmt->execute([$userId, $filename, $isPrimary]);
    $photoId = (int)$db->lastInsertId();

    if ($isPrimary) {
        $db->prepare("UPDATE user_profiles SET profile_photo = ? WHERE user_id = ?")->execute([$filename, $userId]);
    }

    sendSuccess([
        'photo_id'   => $photoId,
        'photo_url'  => UPLOAD_URL . $filename,
        'is_primary' => (bool)$isPrimary,
    ], 'Photo uploaded successfully');
}

// ============================================================
// Delete Photo
// ============================================================
function deletePhoto($userId) {
    $input = getInput();
    $photoId = (int)($input['photo_id'] ?? $_GET['photo_id'] ?? 0);
    if ($photoId <= 0) sendError(400, 'photo_id required');

    $db = getDB();
    $s = $db->prepare("SELECT id, photo_path, is_primary FROM user_photos WHERE id = ? AND user_id = ?");
    $s->execute([$photoId, $userId]);
    $photo = $s->fetch();
    if (!$photo) sendError(404, 'Photo not found');

    // Delete file
    $fp = UPLOAD_DIR . $photo['photo_path'];
    if (file_exists($fp)) @unlink($fp);
    $db->prepare("DELETE FROM user_photos WHERE id = ?")->execute([$photoId]);

    // If deleted was primary, promote next
    if ($photo['is_primary']) {
        $next = $db->prepare("SELECT id, photo_path FROM user_photos WHERE user_id = ? ORDER BY id ASC LIMIT 1");
        $next->execute([$userId]);
        $n = $next->fetch();
        if ($n) {
            $db->prepare("UPDATE user_photos SET is_primary = 1 WHERE id = ?")->execute([$n['id']]);
            $db->prepare("UPDATE user_profiles SET profile_photo = ? WHERE user_id = ?")->execute([$n['photo_path'], $userId]);
        } else {
            $db->prepare("UPDATE user_profiles SET profile_photo = NULL WHERE user_id = ?")->execute([$userId]);
        }
    }
    sendSuccess([], 'Photo deleted');
}

// ============================================================
// Set Primary Photo
// ============================================================
function setPrimaryPhoto($userId) {
    $input = getInput();
    $photoId = (int)($input['photo_id'] ?? 0);
    if ($photoId <= 0) sendError(400, 'photo_id required');

    $db = getDB();
    $s = $db->prepare("SELECT id, photo_path FROM user_photos WHERE id = ? AND user_id = ?");
    $s->execute([$photoId, $userId]);
    $photo = $s->fetch();
    if (!$photo) sendError(404, 'Photo not found');

    $db->prepare("UPDATE user_photos SET is_primary = 0 WHERE user_id = ?")->execute([$userId]);
    $db->prepare("UPDATE user_photos SET is_primary = 1 WHERE id = ?")->execute([$photoId]);
    $db->prepare("UPDATE user_profiles SET profile_photo = ? WHERE user_id = ?")->execute([$photo['photo_path'], $userId]);

    sendSuccess(['photo_url' => UPLOAD_URL . $photo['photo_path']], 'Primary photo updated');
}

// ============================================================
// Get Phone Number (Premium only)
// ============================================================
function getPhone($userId) {
    $targetId = (int)($_GET['target_id'] ?? 0);
    if ($targetId <= 0) sendError(400, 'target_id required');
    if ($targetId === $userId) sendError(400, 'Cannot view own number');

    $db = getDB();

    // Check premium subscription
    $sub = $db->prepare("SELECT id FROM user_subscriptions WHERE user_id = ? AND status = 'active' AND expires_at > NOW() LIMIT 1");
    $sub->execute([$userId]);
    if (!$sub->fetch()) sendError(403, 'Premium subscription required to view phone numbers.');

    $ps = $db->prepare("SELECT phone, country_code FROM users WHERE id = ?");
    $ps->execute([$targetId]);
    $u = $ps->fetch();
    if (!$u) sendError(404, 'User not found');

    sendSuccess([
        'phone'        => $u['phone'],
        'country_code' => $u['country_code'] ?? '+91',
        'full_phone'   => ($u['country_code'] ?? '+91') . ' ' . $u['phone'],
    ], 'Phone number retrieved');
}

// ============================================================
// Full Profile Get
// ============================================================
function getProfile($userId) {
    $db = getDB();

    // Basic profile
    $stmt = $db->prepare("
        SELECT
            u.phone, u.country_code,
            p.profile_for, p.full_name, p.dob, p.gender, p.bio,
            p.is_profile_complete,
            p.mother_occupation, p.father_occupation, p.brothers, p.sisters,
            CONCAT('" . UPLOAD_URL . "', p.profile_photo) as profile_photo_url
        FROM users u
        LEFT JOIN user_profiles p ON p.user_id = u.id
        WHERE u.id = ?
    ");
    $stmt->execute([$userId]);
    $profile = $stmt->fetch();

    if (!$profile) sendError(404, 'Profile not found');

    // Religion
    $stmt = $db->prepare("
        SELECT r.name as religion, ur.caste, mt.name as mother_tongue,
               ur.religion_id, ur.mother_tongue_id
        FROM user_religion ur
        LEFT JOIN religions r ON r.id = ur.religion_id
        LEFT JOIN mother_tongues mt ON mt.id = ur.mother_tongue_id
        WHERE ur.user_id = ?
    ");
    $stmt->execute([$userId]);
    $profile['religion'] = $stmt->fetch() ?: null;

    // Location
    $stmt = $db->prepare("
        SELECT s.name as state, ul.city, ul.state_id
        FROM user_location ul
        LEFT JOIN states s ON s.id = ul.state_id
        WHERE ul.user_id = ?
    ");
    $stmt->execute([$userId]);
    $profile['location'] = $stmt->fetch() ?: null;

    // Education
    $stmt = $db->prepare("
        SELECT el.name as education, ue.profession, ir.name as income,
               ue.education_id, ue.income_id
        FROM user_education ue
        LEFT JOIN education_levels el ON el.id = ue.education_id
        LEFT JOIN income_ranges ir ON ir.id = ue.income_id
        WHERE ue.user_id = ?
    ");
    $stmt->execute([$userId]);
    $profile['education'] = $stmt->fetch() ?: null;

    // Habits
    $stmt = $db->prepare("
        SELECT
            h.name as height, uh.weight,
            eh.name as eating_habit, sh.name as smoking_habit,
            dh.name as drinking_habit, d.name as disability,
            ms.name as marital_status, bt.name as body_type,
            c.name as complexion, bg.name as blood_group,
            uh.height_id, uh.eating_habit_id, uh.smoking_habit_id,
            uh.drinking_habit_id, uh.disability_id, uh.marital_status_id,
            uh.body_type_id, uh.complexion_id, uh.blood_group_id
        FROM user_habits uh
        LEFT JOIN heights h ON h.id = uh.height_id
        LEFT JOIN eating_habits eh ON eh.id = uh.eating_habit_id
        LEFT JOIN smoking_habits sh ON sh.id = uh.smoking_habit_id
        LEFT JOIN drinking_habits dh ON dh.id = uh.drinking_habit_id
        LEFT JOIN disabilities d ON d.id = uh.disability_id
        LEFT JOIN marital_statuses ms ON ms.id = uh.marital_status_id
        LEFT JOIN body_types bt ON bt.id = uh.body_type_id
        LEFT JOIN complexions c ON c.id = uh.complexion_id
        LEFT JOIN blood_groups bg ON bg.id = uh.blood_group_id
        WHERE uh.user_id = ?
    ");
    $stmt->execute([$userId]);
    $profile['habits'] = $stmt->fetch() ?: null;

    // Partner Preference
    $stmt = $db->prepare("
        SELECT pp.age_min, pp.age_max,
               r.name as religion, h1.name as min_height, h2.name as max_height,
               ir.name as income,
               pp.religion_id, pp.min_height_id, pp.max_height_id, pp.income_id
        FROM user_partner_preference pp
        LEFT JOIN religions r ON r.id = pp.religion_id
        LEFT JOIN heights h1 ON h1.id = pp.min_height_id
        LEFT JOIN heights h2 ON h2.id = pp.max_height_id
        LEFT JOIN income_ranges ir ON ir.id = pp.income_id
        WHERE pp.user_id = ?
    ");
    $stmt->execute([$userId]);
    $profile['partner_preference'] = $stmt->fetch() ?: null;

    // Photos
    $stmt = $db->prepare("SELECT id, CONCAT('" . UPLOAD_URL . "', photo_path) as url, is_primary FROM user_photos WHERE user_id = ? ORDER BY is_primary DESC, id DESC");
    $stmt->execute([$userId]);
    $profile['photos'] = $stmt->fetchAll();

    $stmt = $db->prepare("SELECT CONCAT('" . UPLOAD_URL . "', document_path) as document_url,
        document_type, original_name, CONCAT('" . UPLOAD_URL . "', selfie_path) as selfie_url,
        selfie_name, uploaded_at FROM user_documents WHERE user_id = ?");
    $stmt->execute([$userId]);
    $profile['document'] = $stmt->fetch() ?: null;

    // ── Profile completion % ─────────────────────────────────────────────────
    $completionScore = 0;
    $completionSteps = [];
    // Basic (20 pts)
    if (!empty($profile['full_name']) && !empty($profile['dob']) && !empty($profile['gender'])) {
        $completionScore += 20; $completionSteps[] = ['name' => 'Basic Details', 'done' => true];
    } else { $completionSteps[] = ['name' => 'Basic Details', 'done' => false]; }
    // Photo (20 pts)
    if (!empty($profile['photos'])) {
        $completionScore += 20; $completionSteps[] = ['name' => 'Profile Photo', 'done' => true];
    } else { $completionSteps[] = ['name' => 'Profile Photo', 'done' => false]; }
    // Religion (15 pts)
    if ($profile['religion']) {
        $completionScore += 15; $completionSteps[] = ['name' => 'Religion & Community', 'done' => true];
    } else { $completionSteps[] = ['name' => 'Religion & Community', 'done' => false]; }
    // Location (10 pts)
    if ($profile['location']) {
        $completionScore += 10; $completionSteps[] = ['name' => 'Location', 'done' => true];
    } else { $completionSteps[] = ['name' => 'Location', 'done' => false]; }
    // Education (15 pts)
    if ($profile['education']) {
        $completionScore += 15; $completionSteps[] = ['name' => 'Education & Career', 'done' => true];
    } else { $completionSteps[] = ['name' => 'Education & Career', 'done' => false]; }
    // Habits (10 pts)
    if ($profile['habits']) {
        $completionScore += 10; $completionSteps[] = ['name' => 'Physical Details', 'done' => true];
    } else { $completionSteps[] = ['name' => 'Physical Details', 'done' => false]; }
    // Partner preference (5 pts)
    if ($profile['partner_preference']) {
        $completionScore += 5; $completionSteps[] = ['name' => 'Partner Preference', 'done' => true];
    } else { $completionSteps[] = ['name' => 'Partner Preference', 'done' => false]; }
    // Bio (5 pts)
    if (!empty($profile['bio'])) {
        $completionScore += 5; $completionSteps[] = ['name' => 'About Me', 'done' => true];
    } else { $completionSteps[] = ['name' => 'About Me', 'done' => false]; }

    $profile['completion_pct']   = $completionScore;
    $profile['completion_steps'] = $completionSteps;

    sendSuccess($profile);
}
function markProfileComplete($db, $userId) {
    $stmt = $db->prepare("
        SELECT
            (SELECT COUNT(*) FROM user_profiles WHERE user_id = ? AND full_name IS NOT NULL) as has_basic,
            (SELECT COUNT(*) FROM user_religion WHERE user_id = ?) as has_religion,
            (SELECT COUNT(*) FROM user_location WHERE user_id = ?) as has_location,
            (SELECT COUNT(*) FROM user_education WHERE user_id = ?) as has_education,
            (SELECT COUNT(*) FROM user_habits WHERE user_id = ?) as has_habits
    ");
    $stmt->execute([$userId, $userId, $userId, $userId, $userId]);
    $checks = $stmt->fetch();

    $isComplete = ($checks['has_basic'] && $checks['has_religion'] &&
                   $checks['has_location'] && $checks['has_education'] && $checks['has_habits']) ? 1 : 0;

    $stmt = $db->prepare("UPDATE user_profiles SET is_profile_complete = ? WHERE user_id = ?");
    $stmt->execute([$isComplete, $userId]);
}
