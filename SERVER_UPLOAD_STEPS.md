# Server pe API Upload Karne ke Steps

## Aapka Server: https://weddingindiamatrimony.com

---

## STEP 1 — cPanel Login Karo

Browser mein open karo:
https://weddingindiamatrimony.com:2083
ya
https://weddingindiamatrimony.com/cpanel

Username aur password daalo (hosting company ne diya hoga)

---

## STEP 2 — Database Banao

cPanel mein jaao: **MySQL Databases**

1. "Create New Database" mein type karo: `wedding_india`
   (Full name hoga: `cpanelusername_wedding_india`)

2. "MySQL Users" section mein:
   - Username: `weddinguser`
   - Password: koi strong password
   - Click: Create User

3. "Add User To Database":
   - User: weddinguser select karo
   - Database: wedding_india select karo
   - Click: Add
   - Permissions: ALL PRIVILEGES check karo → Make Changes

4. Note karo:
   - DB Host: `localhost`
   - DB Name: `cpanelusername_wedding_india`  (cPanel username prefix lagta hai)
   - DB User: `cpanelusername_weddinguser`
   - DB Pass: jo aapne set kiya

---

## STEP 3 — SQL Import Karo

cPanel mein: **phpMyAdmin** open karo

1. Left side mein apna database select karo
2. "Import" tab click karo
3. "Choose File" → `d:\wedding-india-app\api\database.sql` select karo
4. "Go" button click karo
5. Success message aana chahiye: 25+ tables created

---

## STEP 4 — config.php Update Karo

`d:\wedding-india-app\api\config.php` file open karo aur update karo:

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'cpanelusername_wedding_india');  // apna prefix daalo
define('DB_USER', 'cpanelusername_weddinguser');    // apna prefix daalo
define('DB_PASS', 'aapka_password_yahan');

define('UPLOAD_URL', 'https://weddingindiamatrimony.com/api/uploads/');
```

---

## STEP 5 — Files Upload Karo

cPanel → **File Manager** open karo

1. `public_html` folder pe double-click karo
2. "New Folder" button → naam: `api`
3. `api` folder open karo
4. "Upload" button click karo
5. Yeh files upload karo:
   - `config.php`
   - `auth.php`
   - `profile.php`
   - `dropdowns.php`
   - `matches.php`
   - `test.php`
6. `uploads` naam ka folder banao (empty)
7. `uploads` folder pe right-click → Permissions → 755 set karo

---

## STEP 6 — Test Karo

Browser mein open karo:
```
https://weddingindiamatrimony.com/api/test.php
```

Green checkmarks dikhne chahiye:
✅ PHP Version OK
✅ Database Connected
✅ Database Tables: 25 tables found
✅ Sample Data loaded
✅ Uploads folder writable

---

## STEP 7 — Flutter App Test Karo

Ab `flutter run` karo:
- Register screen → phone number daalo
- OTP screen → 1234 daalo
- Profile creation karo
- phpMyAdmin mein check karo — data aa raha hoga!

---

## Troubleshooting

### "Database connection failed"
- DB_NAME mein cPanel username prefix hai? (jaise: `username_wedding_india`)
- DB_USER bhi prefix ke saath hai?
- Password sahi hai?

### "404 Not Found"
- Files `public_html/api/` mein hain?
- Folder naam exactly `api` hai?

### "Permission denied" on uploads
- `uploads` folder ka permission 755 set karo

---

## Quick Check Commands (cPanel Terminal se)

cPanel → Terminal ya SSH:
```bash
ls public_html/api/
mysql -u username -p username_wedding_india -e "SHOW TABLES;"
```
