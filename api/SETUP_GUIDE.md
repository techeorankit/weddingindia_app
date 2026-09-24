# 🚀 Wedding India App - Complete Setup Guide

## 📋 Prerequisites

### Software Requirements:
- **XAMPP** / **WAMP** / **LAMP** (Apache + MySQL + PHP)
- **PHP** 7.4 or higher
- **MySQL** 5.7 or higher
- **Postman** (optional, for testing)

---

## 🔧 Step-by-Step Setup

### Step 1: Install XAMPP (if not installed)

1. Download XAMPP from: https://www.apachefriends.org/
2. Install karo default settings ke saath
3. XAMPP Control Panel open karo
4. **Apache** aur **MySQL** start karo

### Step 2: Project Setup

#### Option A: Direct Copy
```bash
# Wedding-india-app folder ko xampp/htdocs mein copy karo
# Path hoga: C:\xampp\htdocs\wedding-india-app\
```

#### Option B: Git Clone
```bash
cd C:\xampp\htdocs
git clone <repository-url> wedding-india-app
```

### Step 3: Database Setup

#### Method 1: Using phpMyAdmin (Recommended)

1. Browser mein open karo: `http://localhost/phpmyadmin`
2. Login karo (default username: `root`, password: blank)
3. **New** button click karo
4. Database name: `wedding_india_db`
5. Collation: `utf8mb4_unicode_ci`
6. Create button click karo
7. **Import** tab pe jao
8. File choose karo: `wedding-india-app/api/database.sql`
9. **Go** button click karo

#### Method 2: Using Command Line
```bash
# MySQL mein login karo
mysql -u root -p

# Database create karo
CREATE DATABASE wedding_india_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Exit karo
exit;

# SQL file import karo
mysql -u root -p wedding_india_db < "C:\xampp\htdocs\wedding-india-app\api\database.sql"
```

### Step 4: Configuration

#### Edit `config.php`:

```php
// Line 6-9: Database credentials
define('DB_HOST', 'localhost');
define('DB_NAME', 'wedding_india_db');
define('DB_USER', 'root');          // ⚠️ Apna username
define('DB_PASS', '');              // ⚠️ Apna password (blank ho sakta hai)

// Line 17: Upload URL (very important!)
define('UPLOAD_URL', 'http://localhost/wedding-india-app/api/uploads/');
```

**Production Setup ke liye:**
```php
define('UPLOAD_URL', 'http://your-domain.com/api/uploads/');
define('JWT_SECRET', 'your-very-secure-random-secret-key-here');
```

### Step 5: App Content Table

Run [app_content.sql](app_content.sql) once in the `wedding_india_db` database. The admin panel's
**App Content** page can then update these values, and the Flutter app reads
them from `/api/content.php`.

```sql
CREATE TABLE app_content (
  id INT AUTO_INCREMENT PRIMARY KEY,
  content_key VARCHAR(50) NOT NULL UNIQUE,
  title VARCHAR(150) NOT NULL,
  body TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO app_content (content_key, title, body, sort_order) VALUES
('privacy', 'Privacy Policy', 'Add your privacy policy here.', 0),
('terms', 'Terms & Conditions', 'Add your terms and conditions here.', 1),
('about', 'About Us', 'Add your about us content here.', 2),
('help', 'Help Line', 'Add your help line details here.', 3);
```

### Package Access Setup

Run the remaining statements in [app_content.sql](app_content.sql) once after
the existing `upgrade_plans` table is available. Then configure each plan in
the admin panel with its profile limit and duration in months. The app allows
two profile views by default, blocks further profile details after the limit,
and redirects the user to the package screen. A real payment gateway must send
the successful transaction reference to `upgrade.php?action=subscribe` before
the package is activated.

### Step 6: Uploads Folder Setup

```bash
# api folder ke andar
cd C:\xampp\htdocs\wedding-india-app\api

# uploads folder create karo
mkdir uploads
```

**Windows Permission:**
1. Right-click on `uploads` folder
2. Properties → Security tab
3. Edit → Add
4. Enter: `Everyone`
5. Check: `Write` permission
6. Apply → OK

**Linux/Mac Permission:**
```bash
chmod 755 uploads
```

### Step 6: Testing

#### Test 1: Check Apache
Browser mein open karo: `http://localhost`
✅ "XAMPP Welcome Page" dikhna chahiye

#### Test 2: Check API Files
Browser mein open karo: `http://localhost/wedding-india-app/api/dropdowns.php?type=all`

**Expected Response:**
```json
{
  "status": true,
  "message": "All dropdowns fetched",
  "data": {
    "religions": [...],
    "states": [...],
    ...
  }
}
```

#### Test 3: Database Connection
Browser mein open karo: `http://localhost/wedding-india-app/api/test.php`

Create this test file:
```php
<?php
require_once 'config.php';
$db = getDB();
echo "✅ Database connected successfully!";
?>
```

---

## 🧪 Testing with Postman

### Import Collection

1. Postman open karo
2. **Import** button click karo
3. File select karo: `Wedding_India_API.postman_collection.json`
4. Import karo

### Update Base URL

1. Collection pe right-click → Edit
2. Variables tab
3. `base_url` ko update karo: `http://localhost/wedding-india-app/api`
4. Save karo

### Test Flow

1. **Send OTP** request run karo
   - Response mein `otp_debug` milega (development ke liye)
   
2. **Verify OTP** request run karo
   - OTP daalo jo step 1 mein mila
   - Token automatically save ho jayega
   
3. **Get All Dropdowns** request run karo
   - Sab master data milega
   
4. **Save Profile For** request run karo (token required)
   - Profile creation start hoga
   
5. Baaki profile APIs test karo sequentially

---

## 🔍 Troubleshooting

### Issue 1: "Database connection failed"

**Solution:**
```bash
# Check MySQL running hai ya nahi
# XAMPP Control Panel mein MySQL ka status check karo

# phpMyAdmin open karo: http://localhost/phpmyadmin
# Agar open nahi ho raha to MySQL start karo

# config.php mein credentials check karo
```

### Issue 2: "404 Not Found"

**Solution:**
```bash
# Check karo files sahi location pe hain:
C:\xampp\htdocs\wedding-india-app\api\

# Apache restart karo XAMPP Control Panel se

# URL check karo:
# ✅ http://localhost/wedding-india-app/api/auth.php
# ❌ http://localhost/api/auth.php (galat)
```

### Issue 3: "No data returned from database"

**Solution:**
```sql
-- phpMyAdmin mein check karo database.sql properly import hua ya nahi
-- Ye query run karo:

USE wedding_india_db;
SELECT COUNT(*) FROM religions;
-- Agar 0 aaya to database.sql dobara import karo
```

### Issue 4: "Photo upload failed"

**Solution:**
```bash
# uploads folder exists karta hai?
# Write permission hai?

# Windows:
# uploads folder → Right-click → Properties → Security
# Everyone ko Write permission do

# Test karo:
# uploads folder mein manually ek text file create karo
# Agar nahi ban raha to permission issue hai
```

### Issue 5: "CORS error in Flutter"

**Solution:**
```php
// config.php check karo (line 24-26)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// .htaccess file bhi check karo
```

### Issue 6: "Token expired" / "Unauthorized"

**Solution:**
```bash
# Token 30 days ke liye valid hai
# Dobara login karo (Send OTP → Verify OTP)
# Naya token milega

# Ya database mein manually check karo:
SELECT auth_token, token_expires_at FROM users WHERE id = 1;
```

---

## 🌐 Production Deployment

### 1. Security Checklist

```php
// config.php mein
define('JWT_SECRET', 'change-this-to-strong-random-string');

// auth.php se ye line remove karo (line 52):
$responseData = ['otp_debug' => $otp]; // ⚠️ REMOVE IN PRODUCTION
```

### 2. SMS Gateway Integration

```php
// auth.php mein sendOtp() function update karo:

function sendOtp() {
    // ... existing code ...
    
    // TODO: Real SMS API integrate karo
    // Example: Twilio, MSG91, etc.
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://api.msg91.com/api/v5/otp');
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
        'mobile' => $countryCode . $phone,
        'otp' => $otp,
    ]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'authkey: YOUR_MSG91_KEY',
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $result = curl_exec($ch);
    curl_close($ch);
}
```

### 3. SSL Certificate Setup

```bash
# cPanel ya hosting panel mein SSL enable karo
# Let's Encrypt free SSL use kar sakte ho

# config.php mein UPLOAD_URL update karo:
define('UPLOAD_URL', 'https://your-domain.com/api/uploads/');
```

### 4. Database Optimization

```sql
-- Production database mein indexes add karo for better performance

USE wedding_india_db;

-- Users table
ALTER TABLE users ADD INDEX idx_phone (phone);
ALTER TABLE users ADD INDEX idx_token (auth_token);

-- User profiles
ALTER TABLE user_profiles ADD INDEX idx_complete (is_profile_complete);
ALTER TABLE user_profiles ADD INDEX idx_gender (gender);

-- Religion
ALTER TABLE user_religion ADD INDEX idx_religion (religion_id);

-- Location
ALTER TABLE user_location ADD INDEX idx_state (state_id);
```

---

## 📊 Database Backup

### Manual Backup
```bash
# Command line se
mysqldump -u root -p wedding_india_db > backup_$(date +%Y%m%d).sql

# phpMyAdmin se
# Database select karo → Export tab → Go
```

### Automated Backup (Linux/Mac)
```bash
# Cron job setup
crontab -e

# Daily backup at 2 AM
0 2 * * * mysqldump -u root -p'password' wedding_india_db > /backups/wedding_$(date +\%Y\%m\%d).sql
```

---

## 📱 Flutter Integration

### Add HTTP Package
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
```

### Create API Service
```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://localhost/wedding-india-app/api';
  // Production: 'https://your-domain.com/api'
  
  String? token;
  
  // ... API methods from README.md
}
```

---

## 🎯 Next Steps

1. ✅ Setup complete ho gaya
2. ✅ Postman se test kiya
3. ✅ Flutter app mein integrate karo
4. ⏭️ SMS gateway integrate karo (production ke liye)
5. ⏭️ Payment gateway add karo (optional)
6. ⏭️ Admin panel banao (optional)

---

## 📞 Support

Problems face kar rahe ho?
- Check **Troubleshooting** section
- README.md file mein detailed docs hain
- GitHub Issues create kar sakte ho

---

## ✅ Quick Checklist

- [ ] XAMPP installed & running
- [ ] Database `wedding_india_db` created
- [ ] `database.sql` imported successfully
- [ ] `config.php` updated with correct credentials
- [ ] `uploads` folder created with write permission
- [ ] Test API: `http://localhost/wedding-india-app/api/dropdowns.php?type=all`
- [ ] Postman collection imported
- [ ] Token generation working (Send OTP → Verify OTP)
- [ ] All APIs tested in Postman

---

**Happy Coding! 🎉**
