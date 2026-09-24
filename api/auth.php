<?php
require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? '';

switch ($action) {
    case 'send_otp':   sendOtp();   break;
    case 'verify_otp': verifyOtp(); break;
    case 'logout':     logout();    break;
    default: sendError(404, 'Invalid action');
}

// ============================================================
// Send OTP
// ============================================================
function sendOtp() {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') sendError(405, 'Method not allowed');

    $input       = getInput();
    $phone       = trim($input['phone'] ?? '');
    $countryCode = trim($input['country_code'] ?? '+91');

    if (empty($phone) || !preg_match('/^\d{10}$/', $phone)) {
        sendError(400, 'Valid 10-digit phone number required');
    }

    $db   = getDB();
    $stmt = $db->prepare("SELECT id FROM users WHERE phone = ? AND country_code = ?");
    $stmt->execute([$phone, $countryCode]);
    $user = $stmt->fetch();

    // Dev mode: OTP always 1234
    // Production: $otp = str_pad(rand(1000, 9999), 4, '0', STR_PAD_LEFT);
    $otp       = '1234';
    $expiresAt = date('Y-m-d H:i:s', strtotime('+' . OTP_EXPIRY_MINUTES . ' minutes'));

    if ($user) {
        $stmt = $db->prepare("UPDATE users SET otp = ?, otp_expires_at = ? WHERE id = ?");
        $stmt->execute([$otp, $expiresAt, $user['id']]);
    } else {
        $stmt = $db->prepare("INSERT INTO users (phone, country_code, otp, otp_expires_at) VALUES (?, ?, ?, ?)");
        $stmt->execute([$phone, $countryCode, $otp, $expiresAt]);
    }

    sendSuccess(['otp_debug' => $otp], "OTP sent to $countryCode $phone");
}

function verifyOtp() {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') sendError(405, 'Method not allowed');

    $input       = getInput();
    $phone       = trim($input['phone'] ?? '');
    $countryCode = trim($input['country_code'] ?? '+91');
    $otp         = trim($input['otp'] ?? '');

    if (empty($phone) || empty($otp)) {
        sendError(400, 'Phone and OTP are required');
    }

    $db = getDB();

    $stmt = $db->prepare("SELECT id, otp, otp_expires_at, is_verified FROM users WHERE phone = ? AND country_code = ?");
    $stmt->execute([$phone, $countryCode]);
    $user = $stmt->fetch();

    if (!$user) {
        sendError(404, 'Phone number not found. Please request OTP first.');
    }

    $isReturningUser = ((int)$user['is_verified'] === 1);

    if ($user['otp'] !== $otp) {
        sendError(400, 'Invalid OTP');
    }

    if (strtotime($user['otp_expires_at']) < time()) {
        sendError(400, 'OTP expired. Please request a new one.');
    }

    // Token generate karo
    $token       = generateToken($user['id']);
    $tokenExpiry = date('Y-m-d H:i:s', strtotime('+' . TOKEN_EXPIRY_DAYS . ' days'));

    $stmt = $db->prepare("UPDATE users SET is_verified = 1, auth_token = ?, token_expires_at = ?, otp = NULL, otp_expires_at = NULL WHERE id = ?");
    $stmt->execute([$token, $tokenExpiry, $user['id']]);

    // Profile complete hai?
    $stmt = $db->prepare("SELECT is_profile_complete FROM user_profiles WHERE user_id = ?");
    $stmt->execute([$user['id']]);
    $profile = $stmt->fetch();

    $isProfileComplete = $profile ? (bool)$profile['is_profile_complete'] : false;

    // Logic:
    // is_new_user=true  → pehli baar → ProfileForScreen (registration)
    // is_new_user=false → returning  → profile_complete check karo
    //   is_profile_complete=true  → MatchesScreen (home/dashboard)
    //   is_profile_complete=false → ProfileForScreen (registration continue)
    $isNewUser = !$isReturningUser;

    sendSuccess([
        'user_id'             => (int)$user['id'],
        'token'               => $token,
        'is_new_user'         => $isNewUser,
        'is_profile_complete' => $isProfileComplete,
    ], 'OTP verified successfully');
}

// ============================================================
// Logout
// ============================================================
function logout() {
    $userId = getAuthUserId();
    $db     = getDB();
    $stmt   = $db->prepare("UPDATE users SET auth_token = NULL, token_expires_at = NULL WHERE id = ?");
    $stmt->execute([$userId]);
    sendSuccess([], 'Logged out successfully');
}
