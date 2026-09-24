<?php
// ============================================================
//  Matches API - Find compatible partners
//  GET /api/matches.php?action=find   => Find matches based on preferences
//  GET /api/matches.php?action=view&id=<user_id>   => View specific profile
// ============================================================

require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? 'find';

// Helper: get app setting
function getSettingVal(PDO $db, string $key, string $default = ''): string {
    static $cache = [];
    if (isset($cache[$key])) return $cache[$key];
    $s = $db->prepare("SELECT `value` FROM app_settings WHERE `key` = ?");
    $s->execute([$key]);
    $row = $s->fetch();
    $cache[$key] = $row ? (string)$row['value'] : $default;
    return $cache[$key];
}
$userId = getAuthUserId();

switch ($action) {
    case 'find':
        findMatches($userId);
        break;
    case 'view':
        $profileId = (int)($_GET['id'] ?? 0);
        if ($profileId <= 0) sendError(400, 'Profile ID required');
        viewProfile($profileId);
        break;
    case 'viewers':
        getProfileViewers($userId);
        break;
    case 'daily':
        getDailyRecommendations($userId);
        break;
    default:
        sendError(404, 'Invalid action');
}

// ============================================================
// Find Matches Based on User Preferences
// ============================================================
function findMatches($userId) {
    $db = getDB();
    
    // Get current user's partner preferences
    $stmt = $db->prepare("
        SELECT age_min, age_max, religion_id, min_height_id, max_height_id, income_id
        FROM user_partner_preference
        WHERE user_id = ?
    ");
    $stmt->execute([$userId]);
    $pref = $stmt->fetch();
    
    // Get current user's gender (to find opposite gender)
    $stmt = $db->prepare("SELECT gender FROM user_profiles WHERE user_id = ?");
    $stmt->execute([$userId]);
    $userProfile = $stmt->fetch();
    $oppositeGender = $userProfile['gender'] === 'Male' ? 'Female' : 'Male';
    
    // Build dynamic query
    $query = "
        SELECT 
            u.id as user_id,
            p.full_name,
            p.profile_photo,
            CONCAT('" . UPLOAD_URL . "', p.profile_photo) as profile_photo_url,
            p.dob,
            p.is_profile_complete,
            YEAR(CURDATE()) - YEAR(p.dob) as age,
            p.gender,
            p.mother_occupation,
            p.father_occupation,
            p.brothers,
            p.sisters,
            u.created_at,
            r.name as religion,
            ur.religion_id,
            s.name as state,
            ul.state_id,
            ul.city,
            h.name as height,
            el.name as education,
            ue.profession
        FROM users u
        INNER JOIN user_profiles p ON p.user_id = u.id
        LEFT JOIN user_religion ur ON ur.user_id = u.id
        LEFT JOIN religions r ON r.id = ur.religion_id
        LEFT JOIN user_location ul ON ul.user_id = u.id
        LEFT JOIN states s ON s.id = ul.state_id
        LEFT JOIN user_habits uh ON uh.user_id = u.id
        LEFT JOIN heights h ON h.id = uh.height_id
        LEFT JOIN user_education ue ON ue.user_id = u.id
        LEFT JOIN education_levels el ON el.id = ue.education_id
        WHERE u.id != ?
        AND p.gender = ?
    ";
    
    $params = [$userId, $oppositeGender];
    
    // Apply preferences if set
    if ($pref) {
        if ($pref['age_min'] && $pref['age_max']) {
            $query .= " AND YEAR(CURDATE()) - YEAR(p.dob) BETWEEN ? AND ?";
            $params[] = $pref['age_min'];
            $params[] = $pref['age_max'];
        }
        if ($pref['religion_id']) {
            $query .= " AND ur.religion_id = ?";
            $params[] = $pref['religion_id'];
        }
        if ($pref['min_height_id'] && $pref['max_height_id']) {
            $query .= " AND uh.height_id BETWEEN ? AND ?";
            $params[] = $pref['min_height_id'];
            $params[] = $pref['max_height_id'];
        }
        if ($pref['income_id']) {
            $query .= " AND ue.income_id >= ?";
            $params[] = $pref['income_id'];
        }
    }

    // ── Advanced filters from query params ──────────────────────────────────
    if (!empty($_GET['marital_status_id'])) {
        $query .= " AND uh.marital_status_id = ?";
        $params[] = (int)$_GET['marital_status_id'];
    }
    if (!empty($_GET['education_id'])) {
        $query .= " AND ue.education_id = ?";
        $params[] = (int)$_GET['education_id'];
    }
    if (!empty($_GET['income_id'])) {
        $query .= " AND ue.income_id >= ?";
        $params[] = (int)$_GET['income_id'];
    }
    if (!empty($_GET['religion_id'])) {
        $query .= " AND ur.religion_id = ?";
        $params[] = (int)$_GET['religion_id'];
    }
    if (!empty($_GET['state_id'])) {
        $query .= " AND ul.state_id = ?";
        $params[] = (int)$_GET['state_id'];
    }
    if (!empty($_GET['age_min']) && !empty($_GET['age_max'])) {
        $query .= " AND YEAR(CURDATE()) - YEAR(p.dob) BETWEEN ? AND ?";
        $params[] = (int)$_GET['age_min'];
        $params[] = (int)$_GET['age_max'];
    }
    if (!empty($_GET['height_min']) && !empty($_GET['height_max'])) {
        $query .= " AND uh.height_id BETWEEN ? AND ?";
        $params[] = (int)$_GET['height_min'];
        $params[] = (int)$_GET['height_max'];
    }
    if (isset($_GET['has_photo']) && $_GET['has_photo'] === '1') {
        $query .= " AND p.profile_photo IS NOT NULL";
    }
    if (isset($_GET['verified_only']) && $_GET['verified_only'] === '1') {
        $query .= " AND p.is_profile_complete = 1";
    }
    
    $query .= " ORDER BY u.created_at DESC LIMIT 100";
    
    $stmt = $db->prepare($query);
    $stmt->execute($params);
    $matches = $stmt->fetchAll();

    // ── Matchmaking Score ──────────────────────────────────────────────────
    // Get my full profile for scoring
    $myS = $db->prepare("
        SELECT p.dob, ur.religion_id, uh.height_id, ue.income_id, ul.state_id,
               pp.age_min, pp.age_max, pp.religion_id as pref_religion_id,
               pp.min_height_id, pp.max_height_id, pp.income_id as pref_income_id
        FROM user_profiles p
        LEFT JOIN user_religion ur ON ur.user_id = p.user_id
        LEFT JOIN user_habits uh ON uh.user_id = p.user_id
        LEFT JOIN user_education ue ON ue.user_id = p.user_id
        LEFT JOIN user_location ul ON ul.user_id = p.user_id
        LEFT JOIN user_partner_preference pp ON pp.user_id = p.user_id
        WHERE p.user_id = ?
    ");
    $myS->execute([$userId]);
    $me = $myS->fetch() ?: [];

    foreach ($matches as &$m) {
        $score = 0;
        $maxScore = 100;

        // 1. Age in preference range (25 pts)
        $theirAge = (int)($m['age'] ?? 0);
        if (!empty($me['age_min']) && !empty($me['age_max'])) {
            if ($theirAge >= (int)$me['age_min'] && $theirAge <= (int)$me['age_max']) {
                $score += 25;
            } elseif (abs($theirAge - (int)$me['age_min']) <= 3 || abs($theirAge - (int)$me['age_max']) <= 3) {
                $score += 12; // Close to preference
            }
        } else {
            $score += 15; // No preference set = partial
        }

        // 2. Religion match (20 pts)
        if (!empty($me['pref_religion_id']) && !empty($m['religion_id'])) {
            if ((int)$me['pref_religion_id'] === (int)$m['religion_id']) $score += 20;
        } else {
            $score += 10;
        }

        // 3. Profile complete (20 pts)
        if (!empty($m['is_profile_complete'])) $score += 20;

        // 4. Has photo (15 pts)
        if (!empty($m['profile_photo'])) $score += 15;

        // 5. Recently joined (10 pts)
        $daysAgo = !empty($m['created_at']) ? (time() - strtotime($m['created_at'])) / 86400 : 999;
        if ($daysAgo <= 7)  $score += 10;
        elseif ($daysAgo <= 30) $score += 5;

        // 6. Same state (10 pts) — rough city match
        if (!empty($me['state_id']) && !empty($m['state_id']) &&
            (int)$me['state_id'] === (int)($m['state_id'] ?? 0)) {
            $score += 10;
        }

        $pct = min(100, (int)round($score / $maxScore * 100));
        $m['match_score'] = $pct;
        $m['match_label'] = $pct >= 80 ? 'Excellent Match'
            : ($pct >= 60 ? 'Good Match'
            : ($pct >= 40 ? 'Fair Match' : 'New Profile'));
    }
    unset($m);

    // Sort by score desc
    usort($matches, fn($a, $b) => ($b['match_score'] ?? 0) - ($a['match_score'] ?? 0));

    sendSuccess(['total' => count($matches), 'matches' => $matches], 'Matches found');
}

// ============================================================
// View Specific Profile (Public View)
// ============================================================
function viewProfile($profileId) {
    $db = getDB();
    $viewerId = getAuthUserId();
    if ($viewerId === $profileId) sendError(400, 'You cannot view your own profile');

    $stmt = $db->prepare("SELECT profile_limit, profiles_viewed FROM user_subscriptions
        WHERE user_id = ? AND status = 'active' AND expires_at > NOW()
        ORDER BY expires_at DESC LIMIT 1");
    $stmt->execute([$viewerId]);
    $subscription = $stmt->fetch();
    if (!$subscription) {
        // Free limit from app_settings
        $freeLimit = (int)(getSettingVal($db, 'free_profile_limit', '5'));
        $stmt = $db->prepare("SELECT COUNT(*) AS profiles_viewed FROM profile_views WHERE viewer_id = ?");
        $stmt->execute([$viewerId]);
        $subscription = ['profile_limit' => $freeLimit, 'profiles_viewed' => (int)$stmt->fetch()['profiles_viewed']];
    }
    if ((int)$subscription['profiles_viewed'] >= (int)$subscription['profile_limit']) {
        sendError(402, 'Profile view limit reached. Please buy a package.');
    }

    $stmt = $db->prepare("INSERT IGNORE INTO profile_views (viewer_id, profile_id) VALUES (?, ?)");
    $stmt->execute([$viewerId, $profileId]);
    if ($stmt->rowCount() > 0) {
        $db->prepare("UPDATE user_subscriptions SET profiles_viewed = profiles_viewed + 1
            WHERE user_id = ? AND status = 'active' AND expires_at > NOW()")
            ->execute([$viewerId]);
    }
    
    $stmt = $db->prepare("
        SELECT
            u.id,
            p.profile_for, p.full_name, p.dob,
            YEAR(CURDATE()) - YEAR(p.dob) as age,
            p.gender, p.bio,
            p.mother_occupation, p.father_occupation, p.brothers, p.sisters,
            CONCAT('" . UPLOAD_URL . "', p.profile_photo) as profile_photo_url,
            r.name as religion, ur.caste, mt.name as mother_tongue,
            s.name as state, ul.city,
            el.name as education, ue.profession, ir.name as income,
            h.name as height, uh.weight,
            eh.name as eating_habit, sh.name as smoking_habit,
            dh.name as drinking_habit, d.name as disability,
            ms.name as marital_status, bt.name as body_type,
            c.name as complexion, bg.name as blood_group
        FROM users u
        INNER JOIN user_profiles p ON p.user_id = u.id
        LEFT JOIN user_religion ur ON ur.user_id = u.id
        LEFT JOIN religions r ON r.id = ur.religion_id
        LEFT JOIN mother_tongues mt ON mt.id = ur.mother_tongue_id
        LEFT JOIN user_location ul ON ul.user_id = u.id
        LEFT JOIN states s ON s.id = ul.state_id
        LEFT JOIN user_education ue ON ue.user_id = u.id
        LEFT JOIN education_levels el ON el.id = ue.education_id
        LEFT JOIN income_ranges ir ON ir.id = ue.income_id
        LEFT JOIN user_habits uh ON uh.user_id = u.id
        LEFT JOIN heights h ON h.id = uh.height_id
        LEFT JOIN eating_habits eh ON eh.id = uh.eating_habit_id
        LEFT JOIN smoking_habits sh ON sh.id = uh.smoking_habit_id
        LEFT JOIN drinking_habits dh ON dh.id = uh.drinking_habit_id
        LEFT JOIN disabilities d ON d.id = uh.disability_id
        LEFT JOIN marital_statuses ms ON ms.id = uh.marital_status_id
        LEFT JOIN body_types bt ON bt.id = uh.body_type_id
        LEFT JOIN complexions c ON c.id = uh.complexion_id
        LEFT JOIN blood_groups bg ON bg.id = uh.blood_group_id
        WHERE u.id = ?
    ");
    $stmt->execute([$profileId]);
    $profile = $stmt->fetch();
    
    if (!$profile) {
        sendError(404, 'Profile not found or incomplete');
    }
    
    // Get all photos
    $stmt = $db->prepare("
        SELECT CONCAT('" . UPLOAD_URL . "', photo_path) as url, is_primary 
        FROM user_photos 
        WHERE user_id = ? 
        ORDER BY is_primary DESC, id DESC
    ");
    $stmt->execute([$profileId]);
    $profile['photos'] = $stmt->fetchAll();
    
    sendSuccess($profile);
}

// ============================================================
// Who Viewed My Profile
// ============================================================
function getProfileViewers($userId) {
    $db = getDB();

    // Premium check
    $sub = $db->prepare("SELECT id FROM user_subscriptions WHERE user_id = ? AND status = 'active' AND expires_at > NOW() LIMIT 1");
    $sub->execute([$userId]);
    $isPremium = (bool)$sub->fetch();

    $stmt = $db->prepare("
        SELECT
            pv.viewer_id,
            p.full_name,
            CONCAT('" . UPLOAD_URL . "', p.profile_photo) as profile_photo_url,
            p.gender,
            YEAR(CURDATE()) - YEAR(p.dob) as age,
            r.name as religion,
            s.name as state,
            ul.city,
            MAX(pv.viewed_at) as last_viewed
        FROM profile_views pv
        INNER JOIN user_profiles p ON p.user_id = pv.viewer_id
        LEFT JOIN user_religion ur ON ur.user_id = pv.viewer_id
        LEFT JOIN religions r ON r.id = ur.religion_id
        LEFT JOIN user_location ul ON ul.user_id = pv.viewer_id
        LEFT JOIN states s ON s.id = ul.state_id
        WHERE pv.profile_id = ?
        GROUP BY pv.viewer_id
        ORDER BY MAX(pv.viewed_at) DESC
        LIMIT 50
    ");
    $stmt->execute([$userId]);
    $viewers = $stmt->fetchAll();

    // Count total views
    $totalStmt = $db->prepare("SELECT COUNT(*) FROM profile_views WHERE profile_id = ?");
    $totalStmt->execute([$userId]);
    $totalViews = (int)$totalStmt->fetchColumn();

    // Blur photos for free users (shadi.com style)
    if (!$isPremium) {
        foreach ($viewers as &$v) {
            $v['is_blurred'] = true;
            $v['full_name']  = substr($v['full_name'] ?? 'Someone', 0, 1) . '****';
            $v['profile_photo_url'] = '';
        }
        unset($v);
    }

    sendSuccess([
        'viewers'      => $viewers,
        'total_views'  => $totalViews,
        'is_premium'   => $isPremium,
    ], 'Profile viewers fetched');
}

// ============================================================
// Daily Recommendations (Today's Top Picks)
// ============================================================
function getDailyRecommendations($userId) {
    $db = getDB();

    $stmt = $db->prepare("SELECT gender FROM user_profiles WHERE user_id = ?");
    $stmt->execute([$userId]);
    $me = $stmt->fetch();
    $oppositeGender = ($me['gender'] ?? 'Male') === 'Male' ? 'Female' : 'Male';

    // Seed random with date + userId for consistent daily picks
    $seed = (int)(date('Ymd')) + $userId;

    $stmt = $db->prepare("
        SELECT
            u.id as user_id,
            p.full_name,
            CONCAT('" . UPLOAD_URL . "', p.profile_photo) as profile_photo_url,
            p.dob,
            p.is_profile_complete,
            YEAR(CURDATE()) - YEAR(p.dob) as age,
            p.gender,
            r.name as religion,
            s.name as state,
            ul.city,
            h.name as height,
            el.name as education,
            ue.profession,
            u.created_at
        FROM users u
        INNER JOIN user_profiles p ON p.user_id = u.id AND p.full_name IS NOT NULL
        LEFT JOIN user_religion ur ON ur.user_id = u.id
        LEFT JOIN religions r ON r.id = ur.religion_id
        LEFT JOIN user_location ul ON ul.user_id = u.id
        LEFT JOIN states s ON s.id = ul.state_id
        LEFT JOIN user_habits uh ON uh.user_id = u.id
        LEFT JOIN heights h ON h.id = uh.height_id
        LEFT JOIN user_education ue ON ue.user_id = u.id
        LEFT JOIN education_levels el ON el.id = ue.education_id
        WHERE u.id != ?
        AND p.gender = ?
        AND p.profile_photo IS NOT NULL
        ORDER BY RAND(?) 
        LIMIT 6
    ");
    $stmt->execute([$userId, $oppositeGender, $seed]);
    $picks = $stmt->fetchAll();

    foreach ($picks as &$p) {
        $p['match_score'] = 0;
        $p['match_label'] = 'Top Pick';
        $p['is_daily_pick'] = true;
    }
    unset($p);

    sendSuccess(['picks' => $picks, 'date' => date('Y-m-d')], 'Daily recommendations');
}
