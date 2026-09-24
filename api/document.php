<?php
// POST /api/document.php
// Multipart fields: document, document_type, selfie (max 5MB each)

require_once __DIR__ . '/config.php';

$userId = getAuthUserId();
$documentType = trim($_POST['document_type'] ?? '');
$allowedDocumentTypes = ['Aadhaar Card', 'PAN Card', 'Voter ID', 'Passport'];
if (!in_array($documentType, $allowedDocumentTypes, true)) {
    sendError(400, 'Please select a valid document type.');
}
$db = getDB();

$stmt = $db->prepare("SELECT id FROM user_subscriptions
    WHERE user_id = ? AND status = 'active' AND expires_at > NOW()
    LIMIT 1");
$stmt->execute([$userId]);
if (!$stmt->fetch()) {
    sendError(402, 'Please buy a package before uploading a document.');
}

$file = $_FILES['document'] ?? null;
$selfie = $_FILES['selfie'] ?? null;
if (!$file || ($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    sendError(400, 'Document file is required.');
}
if (!$selfie || ($selfie['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    sendError(400, 'Selfie is required.');
}
if (($file['size'] ?? 0) > MAX_FILE_SIZE) {
    sendError(400, 'File size cannot exceed 5MB.');
}
if (($selfie['size'] ?? 0) > MAX_FILE_SIZE) {
    sendError(400, 'Selfie size cannot exceed 5MB.');
}

$finfo = finfo_open(FILEINFO_MIME_TYPE);
$detectedType = $finfo ? finfo_file($finfo, $file['tmp_name']) : '';
$allowedTypes = [
    'application/pdf' => 'pdf',
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
];
if (!isset($allowedTypes[$detectedType])) {
    if ($finfo) finfo_close($finfo);
    sendError(400, 'Only PDF, JPG, PNG, or WebP documents are allowed.');
}
$selfieType = $finfo ? finfo_file($finfo, $selfie['tmp_name']) : '';
if ($finfo) finfo_close($finfo);
$allowedSelfieTypes = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
if (!isset($allowedSelfieTypes[$selfieType])) {
    sendError(400, 'Selfie must be a JPG, PNG, or WebP image.');
}

if (!is_dir(UPLOAD_DIR) && !mkdir(UPLOAD_DIR, 0755, true) && !is_dir(UPLOAD_DIR)) {
    sendError(500, 'Upload directory could not be created.');
}

$extension = $allowedTypes[$detectedType];
$filename = 'document_' . $userId . '_' . time() . '.' . $extension;
$filepath = UPLOAD_DIR . $filename;
if (!move_uploaded_file($file['tmp_name'], $filepath)) {
    sendError(500, 'Failed to upload document.');
}
$selfieExtension = $allowedSelfieTypes[$selfieType];
$selfieFilename = 'selfie_' . $userId . '_' . time() . '.' . $selfieExtension;
$selfieFilepath = UPLOAD_DIR . $selfieFilename;
if (!move_uploaded_file($selfie['tmp_name'], $selfieFilepath)) {
    if (is_file($filepath)) unlink($filepath);
    sendError(500, 'Failed to upload selfie.');
}

$stmt = $db->prepare('SELECT document_path, selfie_path FROM user_documents WHERE user_id = ?');
$stmt->execute([$userId]);
$oldDocument = $stmt->fetch();

$documentName = basename($file['name'] ?? 'document.' . $extension);
$selfieName = basename($selfie['name'] ?? 'selfie.' . $selfieExtension);
$stmt = $db->prepare("INSERT INTO user_documents
    (user_id, document_path, document_type, original_name, selfie_path, selfie_name)
    VALUES (?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE document_path = VALUES(document_path), document_type = VALUES(document_type),
    original_name = VALUES(original_name), selfie_path = VALUES(selfie_path), selfie_name = VALUES(selfie_name),
    uploaded_at = CURRENT_TIMESTAMP");
$stmt->execute([$userId, $filename, $documentType, $documentName, $selfieFilename, $selfieName]);

if ($oldDocument && !empty($oldDocument['document_path'])) {
    $oldPath = UPLOAD_DIR . basename($oldDocument['document_path']);
    if (is_file($oldPath) && $oldPath !== $filepath) unlink($oldPath);
}
if ($oldDocument && !empty($oldDocument['selfie_path'])) {
    $oldSelfiePath = UPLOAD_DIR . basename($oldDocument['selfie_path']);
    if (is_file($oldSelfiePath) && $oldSelfiePath !== $selfieFilepath) unlink($oldSelfiePath);
}

sendSuccess([
    'document_url' => UPLOAD_URL . $filename,
    'document_type' => $documentType,
    'original_name' => $documentName,
    'selfie_url' => UPLOAD_URL . $selfieFilename,
], 'Document uploaded successfully.');
