<?php
// ============================================================
//  Quick API Test File
//  Browser mein open karo: http://localhost/wedding-india-app/api/test.php
// ============================================================

header('Content-Type: text/html; charset=UTF-8');

echo "<!DOCTYPE html>
<html>
<head>
    <title>Wedding India API - Test</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white; 
            padding: 30px; 
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 { 
            color: #E91E63; 
            margin-bottom: 10px;
            font-size: 28px;
        }
        h2 { 
            color: #333; 
            margin: 25px 0 15px; 
            font-size: 20px;
            border-bottom: 2px solid #E91E63;
            padding-bottom: 8px;
        }
        .success { 
            background: #d4edda; 
            color: #155724; 
            padding: 12px 20px; 
            border-radius: 8px; 
            margin: 10px 0;
            border-left: 4px solid #28a745;
        }
        .error { 
            background: #f8d7da; 
            color: #721c24; 
            padding: 12px 20px; 
            border-radius: 8px; 
            margin: 10px 0;
            border-left: 4px solid #dc3545;
        }
        .info { 
            background: #d1ecf1; 
            color: #0c5460; 
            padding: 12px 20px; 
            border-radius: 8px; 
            margin: 10px 0;
            border-left: 4px solid #17a2b8;
        }
        .test-item {
            padding: 10px 15px;
            margin: 8px 0;
            border-radius: 5px;
            background: #f8f9fa;
        }
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            margin-left: 8px;
        }
        .badge-success { background: #28a745; color: white; }
        .badge-error { background: #dc3545; color: white; }
        code {
            background: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            color: #E91E63;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
            font-size: 14px;
        }
        a {
            color: #E91E63;
            text-decoration: none;
            font-weight: bold;
        }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
<div class='container'>
    <h1>🎉 Wedding India API Test</h1>
    <p style='color: #666; margin-bottom: 20px;'>API server status and configuration check</p>
";

// ============================================================
// Test 1: PHP Version
// ============================================================
echo "<h2>1️⃣ PHP Configuration</h2>";
$phpVersion = phpversion();
$phpOK = version_compare($phpVersion, '7.4', '>=');

if ($phpOK) {
    echo "<div class='success'>✅ PHP Version: <strong>$phpVersion</strong> <span class='badge badge-success'>OK</span></div>";
} else {
    echo "<div class='error'>❌ PHP Version: <strong>$phpVersion</strong> <span class='badge badge-error'>Required: 7.4+</span></div>";
}

// Check required extensions
$extensions = ['pdo', 'pdo_mysql', 'json', 'mbstring', 'fileinfo'];
echo "<div class='info'><strong>Required Extensions:</strong><br>";
foreach ($extensions as $ext) {
    $loaded = extension_loaded($ext);
    $icon = $loaded ? '✅' : '❌';
    $status = $loaded ? 'Loaded' : 'Missing';
    echo "$icon <code>$ext</code> - $status<br>";
}
echo "</div>";

// ============================================================
// Test 2: Database Connection
// ============================================================
echo "<h2>2️⃣ Database Connection</h2>";

try {
    require_once 'config.php';
    $db = getDB();
    echo "<div class='success'>✅ Database Connected: <strong>" . DB_NAME . "</strong> <span class='badge badge-success'>OK</span></div>";
    
    // Check tables
    $stmt = $db->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    $tableCount = count($tables);
    
    if ($tableCount >= 20) {
        echo "<div class='success'>✅ Database Tables: <strong>$tableCount tables</strong> found <span class='badge badge-success'>OK</span></div>";
    } else {
        echo "<div class='error'>⚠️ Database Tables: Only <strong>$tableCount tables</strong> found. Expected 25+. Please import database.sql</div>";
    }
    
    // Check sample data
    $stmt = $db->query("SELECT COUNT(*) as cnt FROM religions");
    $religionCount = $stmt->fetch()['cnt'];
    
    if ($religionCount > 0) {
        echo "<div class='success'>✅ Sample Data: <strong>$religionCount religions</strong> loaded <span class='badge badge-success'>OK</span></div>";
    } else {
        echo "<div class='error'>❌ Sample Data: No data found. Please import database.sql</div>";
    }
    
} catch (Exception $e) {
    echo "<div class='error'>❌ Database Connection Failed<br>";
    echo "<strong>Error:</strong> " . $e->getMessage() . "<br>";
    echo "<strong>Fix:</strong> Update credentials in <code>config.php</code></div>";
}

// ============================================================
// Test 3: File Permissions
// ============================================================
echo "<h2>3️⃣ File Permissions</h2>";

$uploadDir = __DIR__ . '/uploads';
if (!is_dir($uploadDir)) {
    echo "<div class='error'>❌ Uploads folder not found at: <code>$uploadDir</code><br>";
    echo "<strong>Fix:</strong> Create the folder: <code>mkdir uploads</code></div>";
} else {
    echo "<div class='success'>✅ Uploads folder exists: <code>$uploadDir</code></div>";
    
    if (is_writable($uploadDir)) {
        echo "<div class='success'>✅ Uploads folder is writable <span class='badge badge-success'>OK</span></div>";
    } else {
        echo "<div class='error'>❌ Uploads folder is not writable<br>";
        echo "<strong>Fix (Windows):</strong> Right-click folder → Properties → Security → Give 'Everyone' write permission<br>";
        echo "<strong>Fix (Linux):</strong> <code>chmod 755 uploads</code></div>";
    }
}

// ============================================================
// Test 4: API Files
// ============================================================
echo "<h2>4️⃣ API Files</h2>";

$requiredFiles = [
    'config.php' => 'Configuration file',
    'auth.php' => 'Authentication endpoints',
    'profile.php' => 'Profile management',
    'dropdowns.php' => 'Master data endpoints',
    'matches.php' => 'Matching system',
    'database.sql' => 'Database schema',
];

$allFilesExist = true;
foreach ($requiredFiles as $file => $desc) {
    $path = __DIR__ . '/' . $file;
    if (file_exists($path)) {
        echo "<div class='test-item'>✅ <code>$file</code> - $desc</div>";
    } else {
        echo "<div class='test-item'>❌ <code>$file</code> - Missing!</div>";
        $allFilesExist = false;
    }
}

if ($allFilesExist) {
    echo "<div class='success'>✅ All required API files present <span class='badge badge-success'>OK</span></div>";
}

// ============================================================
// Test 5: API Endpoints
// ============================================================
echo "<h2>5️⃣ API Endpoints Test</h2>";

$baseUrl = 'http://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']);

echo "<div class='info'><strong>Base URL:</strong> <code>$baseUrl</code></div>";

$endpoints = [
    'Dropdowns API' => $baseUrl . '/dropdowns.php?type=all',
    'Send OTP' => $baseUrl . '/auth.php?action=send_otp',
    'Profile API' => $baseUrl . '/profile.php?action=get',
];

echo "<div class='test-item'><strong>Test these endpoints:</strong><br>";
foreach ($endpoints as $name => $url) {
    echo "• <a href='$url' target='_blank'>$name</a><br>";
}
echo "</div>";

// ============================================================
// Summary
// ============================================================
echo "<h2>📊 Summary</h2>";

if ($phpOK && isset($db) && $tableCount >= 20 && $religionCount > 0 && is_writable($uploadDir)) {
    echo "<div class='success' style='font-size: 18px; text-align: center;'>
        <strong>🎉 All Tests Passed!</strong><br>
        Your API is ready to use. Test with Postman or integrate with Flutter app.
    </div>";
    
    echo "<div class='info'><strong>Next Steps:</strong><br>";
    echo "1. Import <code>Wedding_India_API.postman_collection.json</code> in Postman<br>";
    echo "2. Test all endpoints<br>";
    echo "3. Integrate with Flutter app<br>";
    echo "4. Read <a href='README.md'>README.md</a> for detailed documentation</div>";
} else {
    echo "<div class='error' style='font-size: 18px; text-align: center;'>
        <strong>⚠️ Some Tests Failed</strong><br>
        Please fix the issues above and refresh this page.
    </div>";
    
    echo "<div class='info'><strong>Common Fixes:</strong><br>";
    echo "• Database: Import <code>database.sql</code> in phpMyAdmin<br>";
    echo "• Config: Update <code>config.php</code> with correct credentials<br>";
    echo "• Uploads: Create folder and give write permissions<br>";
    echo "• Help: Read <a href='SETUP_GUIDE.md'>SETUP_GUIDE.md</a></div>";
}

echo "<div class='footer'>
    <p>Wedding India API v1.0 | <a href='README.md'>Documentation</a> | <a href='SETUP_GUIDE.md'>Setup Guide</a></p>
    <p style='margin-top: 10px; font-size: 12px;'>Test URL: <code>" . $_SERVER['PHP_SELF'] . "</code></p>
</div>";

echo "</div></body></html>";
?>
