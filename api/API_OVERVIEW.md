# 📱 Wedding India App - API Overview

## 🎯 What's Included

Aapke Flutter wedding app ke liye **complete backend system** ready hai with:

### ✅ Core Features
- **OTP-based Authentication** (Phone number login)
- **Complete User Profile Management** (10+ sections)
- **Dynamic Dropdowns** (Database se sab data)
- **Partner Matching System** (Preference-based)
- **Photo Upload** (Multiple photos support)
- **Token-based Security** (30-day expiry)

---

## 📁 File Structure

```
api/
├── config.php                  # Database & app configuration
├── auth.php                    # Login/OTP/Logout
├── profile.php                 # User profile CRUD
├── dropdowns.php               # All master data
├── matches.php                 # Find & view matches
├── database.sql                # Complete database schema
├── .htaccess                   # Apache configuration
├── README.md                   # Complete API documentation
├── SETUP_GUIDE.md              # Step-by-step setup
├── API_OVERVIEW.md             # This file
├── Wedding_India_API.postman_collection.json   # Postman testing
└── uploads/                    # User photos (auto-created)
```

---

## 🗄️ Database Schema

### Master/Lookup Tables (16 tables)
Sab dropdowns database se load honge:

1. **religions** - Hindu, Muslim, Christian, etc.
2. **mother_tongues** - Hindi, Marathi, Tamil, etc.
3. **states** - All Indian states
4. **education_levels** - 10th, Graduate, Post Graduate, etc.
5. **income_ranges** - Below 1 Lakh to 5+ Crore
6. **marital_statuses** - Never Married, Divorced, etc.
7. **profile_for_options** - Myself, Son, Daughter, etc.
8. **heights** - 4'6" to 6'4" (with cm values)
9. **eating_habits** - Vegetarian, Non-Veg, etc.
10. **smoking_habits** - No, Occasionally, Yes
11. **drinking_habits** - No, Occasionally, Yes
12. **body_types** - Slim, Average, Athletic, Heavy
13. **complexions** - Very Fair, Fair, Wheatish, Dark
14. **blood_groups** - A+, B+, O+, AB+, etc.
15. **disabilities** - None, Physically Challenged, etc.
16. **country_codes** - +91 (India), +1 (USA), etc.

### User Data Tables (9 tables)

1. **users** - Phone, OTP, Token (Auth)
2. **user_profiles** - Name, DOB, Gender, Bio, Photo
3. **user_religion** - Religion, Caste, Mother Tongue
4. **user_location** - State, City
5. **user_education** - Education, Profession, Income
6. **user_habits** - Height, Weight, Habits, Physical details
7. **user_partner_preference** - Age range, Height, Religion, Income
8. **user_photos** - Multiple photos per user
9. (Relationships maintained via Foreign Keys)

---

## 🔄 Complete User Flow

### 1️⃣ Registration Flow
```
User Registration Screen
  ↓
[Enter Phone Number]
  ↓
Send OTP → auth.php?action=send_otp
  ↓
[Enter OTP]
  ↓
Verify OTP → auth.php?action=verify_otp
  ↓
Get Token (30-day validity)
  ↓
Profile Creation Screens...
```

### 2️⃣ Profile Creation Flow (Your App Screens)
```
1. Profile For Screen → save_profile_for (Myself/Son/etc)
2. Basic Details Screen → save_basic (Name, DOB, Gender)
3. Religion Screen → save_religion (Religion, Caste)
4. Location Screen → save_location (State, City)
5. Education Screen → save_education (Education, Job, Income)
6. Marital Status Screen → (part of habits)
7. Habits & Details Screen → save_habits (Height, Weight, etc.)
8. Mother Tongue Screen → (part of religion)
9. About Me Screen → save_about (Bio)
10. Partner Preference Screen → save_preference (Age, Height, etc.)
11. Upload Photo Screen → upload_photo
```

### 3️⃣ Main App Flow
```
Home Screen
  ↓
Matches Screen → matches.php?action=find
  ↓
View Profile → matches.php?action=view&id=X
  ↓
My Profile → profile.php?action=get
```

---

## 🚀 API Endpoints Quick Reference

### Authentication (No token required)
```
POST /api/auth.php?action=send_otp        # Send OTP
POST /api/auth.php?action=verify_otp      # Verify & get token
POST /api/auth.php?action=logout          # Logout (token required)
```

### Dropdowns (No token required)
```
GET /api/dropdowns.php?type=all           # All dropdowns (recommended)
GET /api/dropdowns.php?type=religions     # Individual dropdown
```

### Profile (Token required in all)
```
POST /api/profile.php?action=save_profile_for
POST /api/profile.php?action=save_basic
POST /api/profile.php?action=save_religion
POST /api/profile.php?action=save_location
POST /api/profile.php?action=save_education
POST /api/profile.php?action=save_habits
POST /api/profile.php?action=save_preference
POST /api/profile.php?action=save_about
POST /api/profile.php?action=upload_photo
GET  /api/profile.php?action=get
```

### Matches (Token required)
```
GET /api/matches.php?action=find          # Find compatible matches
GET /api/matches.php?action=view&id=X     # View specific profile
```

---

## 🔐 Security Features

✅ **Token-based Authentication** - Bearer token in header  
✅ **OTP Verification** - Phone number validation  
✅ **SQL Injection Protection** - PDO prepared statements  
✅ **Password Hashing** - (if implementing password login)  
✅ **CORS Enabled** - Flutter app se call kar sakte ho  
✅ **File Upload Validation** - Only images allowed  
✅ **Input Validation** - Sab inputs validated  

---

## 📊 Response Format

### Success Response
```json
{
  "status": true,
  "message": "Success message",
  "data": { ... }
}
```

### Error Response
```json
{
  "status": false,
  "message": "Error message",
  "data": null
}
```

HTTP Status Codes:
- `200` - Success
- `400` - Bad Request (validation error)
- `401` - Unauthorized (no/invalid token)
- `404` - Not Found
- `500` - Server Error

---

## 🎨 Flutter Integration Example

### 1. Load Dropdowns on App Start
```dart
class SplashScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    loadDropdowns();
  }
  
  Future<void> loadDropdowns() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dropdowns.php?type=all'),
    );
    final data = json.decode(response.body);
    
    if (data['status']) {
      // Save to local storage (SharedPreferences)
      await saveDropdowns(data['data']);
    }
  }
}
```

### 2. Use Dropdowns in UI
```dart
// ReligionScreen.dart
List<Map<String, dynamic>> religions = await getDropdownFromStorage('religions');

// Build UI
religions.map((religion) {
  return ChoiceChip(
    label: Text(religion['name']),
    selected: selectedReligionId == religion['id'],
    onSelected: (selected) {
      setState(() => selectedReligionId = religion['id']);
    },
  );
}).toList();
```

### 3. Save Profile Data
```dart
// BasicDetailsScreen.dart
Future<void> saveBasicDetails() async {
  final response = await http.post(
    Uri.parse('$baseUrl/profile.php?action=save_basic'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'full_name': nameController.text,
      'dob': selectedDate.toString().split(' ')[0], // YYYY-MM-DD
      'gender': selectedGender,
    }),
  );
  
  final data = json.decode(response.body);
  if (data['status']) {
    // Navigate to next screen
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ReligionScreen(),
    ));
  }
}
```

---

## 🛠️ Customization Guide

### Add New Dropdown

1. **Database mein table banao:**
```sql
CREATE TABLE hobbies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    sort_order INT DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1
);

INSERT INTO hobbies (name, sort_order) VALUES
('Reading', 1), ('Sports', 2), ('Music', 3);
```

2. **dropdowns.php mein add karo:**
```php
case 'hobbies':
    getSimpleDropdown('hobbies');
    break;

// getAllDropdowns() function mein bhi add karo:
'hobbies' => fetchDropdown($db, 'hobbies'),
```

3. **Flutter app mein use karo:**
```dart
final hobbies = await getDropdown('hobbies');
```

---

## 📈 Performance Tips

### 1. Cache Dropdowns in Flutter
```dart
// Load once on app start, save in SharedPreferences
// Reload only if version changes
```

### 2. Pagination for Matches
```dart
// matches.php mein add karo:
$page = (int)($_GET['page'] ?? 1);
$limit = 20;
$offset = ($page - 1) * $limit;

$query .= " LIMIT $offset, $limit";
```

### 3. Image Optimization
```dart
// Flutter se upload se pehle compress karo
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

final compressedImage = await FlutterImageCompress.compressAndGetFile(
  image.path,
  targetPath,
  quality: 80,
);
```

---

## 🎯 Production Checklist

Before going live:

- [ ] Change `JWT_SECRET` in config.php
- [ ] Remove `otp_debug` from auth.php
- [ ] Integrate real SMS gateway (MSG91/Twilio)
- [ ] Setup SSL certificate (HTTPS)
- [ ] Update `UPLOAD_URL` to production domain
- [ ] Enable MySQL slow query log
- [ ] Setup automated database backups
- [ ] Add rate limiting for OTP
- [ ] Setup error logging
- [ ] Test all APIs thoroughly
- [ ] Add monitoring (Sentry/New Relic)

---

## 📞 Common Questions

**Q: Dropdowns hard-coded hain ya database se aati hain?**  
A: Database se. Aap admin panel bana ke add/edit kar sakte ho.

**Q: Multiple photos upload kar sakte hain?**  
A: Haan. `user_photos` table mein multiple entries hoti hain.

**Q: Matches kaise filter hote hain?**  
A: User ki partner preference ke basis pe SQL query automatically filter karti hai.

**Q: Token expire hone ke baad?**  
A: User ko dobara login karna padega (OTP process).

**Q: Production mein OTP kaise bhejenge?**  
A: MSG91, Twilio, ya koi bhi SMS gateway integrate karo.

---

## 🎉 You're All Set!

Ab aapke paas hai:
✅ Complete database schema  
✅ Working REST APIs  
✅ Authentication system  
✅ Profile management  
✅ Matching system  
✅ Documentation  
✅ Postman collection  
✅ Setup guide  

**Next Steps:**
1. SETUP_GUIDE.md follow karo
2. Postman se test karo
3. Flutter app mein integrate karo
4. Build something amazing! 🚀

---

**Made with ❤️ for Wedding India App**
