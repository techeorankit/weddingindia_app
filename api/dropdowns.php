<?php
// ============================================================
//  Dropdown / Lookup Data API
//  GET /api/dropdowns.php?type=all          => Sab data ek saath
//  GET /api/dropdowns.php?type=religions
//  GET /api/dropdowns.php?type=states
//  GET /api/dropdowns.php?type=education_levels
//  GET /api/dropdowns.php?type=income_ranges
//  GET /api/dropdowns.php?type=marital_statuses
//  GET /api/dropdowns.php?type=mother_tongues
//  GET /api/dropdowns.php?type=heights
//  GET /api/dropdowns.php?type=eating_habits
//  GET /api/dropdowns.php?type=smoking_habits
//  GET /api/dropdowns.php?type=drinking_habits
//  GET /api/dropdowns.php?type=body_types
//  GET /api/dropdowns.php?type=complexions
//  GET /api/dropdowns.php?type=blood_groups
//  GET /api/dropdowns.php?type=disabilities
//  GET /api/dropdowns.php?type=profile_for_options
//  GET /api/dropdowns.php?type=country_codes
// ============================================================

require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError(405, 'Method not allowed');
}

$type = $_GET['type'] ?? 'all';
$db   = getDB();

// Simple lookup helper
function fetchLookup($db, $table, $extraFields = '') {
    $fields = "id, name" . ($extraFields ? ", $extraFields" : '');
    $stmt = $db->query("SELECT $fields FROM `$table` WHERE is_active = 1 ORDER BY sort_order ASC");
    return $stmt->fetchAll();
}

switch ($type) {
    case 'religions':
        sendSuccess(fetchLookup($db, 'religions'));

    case 'states':
        sendSuccess(fetchLookup($db, 'states'));

    case 'education_levels':
        sendSuccess(fetchLookup($db, 'education_levels'));

    case 'income_ranges':
        sendSuccess(fetchLookup($db, 'income_ranges'));

    case 'marital_statuses':
        sendSuccess(fetchLookup($db, 'marital_statuses'));

    case 'mother_tongues':
        sendSuccess(fetchLookup($db, 'mother_tongues'));

    case 'heights':
        sendSuccess(fetchLookup($db, 'heights', 'cm_value'));

    case 'eating_habits':
        sendSuccess(fetchLookup($db, 'eating_habits'));

    case 'smoking_habits':
        sendSuccess(fetchLookup($db, 'smoking_habits'));

    case 'drinking_habits':
        sendSuccess(fetchLookup($db, 'drinking_habits'));

    case 'body_types':
        sendSuccess(fetchLookup($db, 'body_types'));

    case 'complexions':
        sendSuccess(fetchLookup($db, 'complexions'));

    case 'blood_groups':
        sendSuccess(fetchLookup($db, 'blood_groups'));

    case 'disabilities':
        sendSuccess(fetchLookup($db, 'disabilities'));

    case 'profile_for_options':
        sendSuccess(fetchLookup($db, 'profile_for_options'));

    case 'country_codes':
        $stmt = $db->query("SELECT id, country_name, code FROM country_codes WHERE is_active = 1 ORDER BY sort_order ASC");
        sendSuccess($stmt->fetchAll());

    case 'all':
        // Flutter app mein ek hi call se sab data load karo (performance ke liye)
        sendSuccess([
            'religions'          => fetchLookup($db, 'religions'),
            'states'             => fetchLookup($db, 'states'),
            'education_levels'   => fetchLookup($db, 'education_levels'),
            'income_ranges'      => fetchLookup($db, 'income_ranges'),
            'marital_statuses'   => fetchLookup($db, 'marital_statuses'),
            'mother_tongues'     => fetchLookup($db, 'mother_tongues'),
            'heights'            => fetchLookup($db, 'heights', 'cm_value'),
            'eating_habits'      => fetchLookup($db, 'eating_habits'),
            'smoking_habits'     => fetchLookup($db, 'smoking_habits'),
            'drinking_habits'    => fetchLookup($db, 'drinking_habits'),
            'body_types'         => fetchLookup($db, 'body_types'),
            'complexions'        => fetchLookup($db, 'complexions'),
            'blood_groups'       => fetchLookup($db, 'blood_groups'),
            'disabilities'       => fetchLookup($db, 'disabilities'),
            'profile_for_options'=> fetchLookup($db, 'profile_for_options'),
            'country_codes'      => (function() use ($db) {
                $s = $db->query("SELECT id, country_name, code FROM country_codes WHERE is_active=1 ORDER BY sort_order");
                return $s->fetchAll();
            })(),
        ]);

    default:
        sendError(400, 'Invalid type parameter');
}
