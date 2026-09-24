# Wedding India App - Complete API Documentation

## 📋 Table of Contents
- [Setup Instructions](#setup-instructions)
- [API Endpoints](#api-endpoints)
- [Authentication Flow](#authentication-flow)
- [Dropdown Data](#dropdown-data)
- [Profile Management](#profile-management)
- [Matches](#matches)
- [Response Format](#response-format)

---

## 🚀 Setup Instructions

### 1. Database Setup

```bash
# MySQL mein database import karo
mysql -u root -p < database.sql

# Ya phpmyadmin se import karo
```

### 2. Configuration

`config.php` file mein apne database credentials update karo:

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'wedding_india_db');
define('DB_USER', 'root');          // Apna username
define('DB_PASS', '');              // Apna password
```

Upload URL bhi update karo:
```php
define('UPLOAD_URL', 'http://your-domain.com/api/uploads/');
```

### 3. Folder Permissions

```bash
# Windows pe
# api folder ke andar 'uploads' folder create karo
# Right click -> Properties -> Security -> Edit
# Users ko "Write" permission do

# Linux/Mac pe
mkdir uploads
chmod 755 uploads
```

### 4. Testing

Browser mein test karo:
```
http://localhost/wedding-india-app/api/dropdowns.php?type=all
```

---

## 🔐 Authentication Flow

### Step 1: Send OTP

**Endpoint:** `POST /api/auth.php?action=send_otp`

**Request Body:**
```json
{
  "phone": "9876543210",
  "country_code": "+91"
}
```

**Response:**
```json
{
  "status": true,
  "message": "OTP sent to +91 9876543210",
  "data": {
    "otp_debug": "1234"  // ⚠️ Production mein remove karo
  }
}
```

### Step 2: Verify OTP

**Endpoint:** `POST /api/auth.php?action=verify_otp`

**Request Body:**
```json
{
  "phone": "9876543210",
  "country_code": "+91",
  "otp": "1234"
}
```

**Response:**
```json
{
  "status": true,
  "message": "OTP verified successfully",
  "data": {
    "user_id": 1,
    "token": "MTZ8MTczNTE2NzQyM3xhYmNkZWY=",
    "is_profile_complete": false
  }
}
```

### Step 3: Use Token

Token ko **Authorization header** mein bhejna hai:

```
Authorization: Bearer MTZ8MTczNTE2NzQyM3xhYmNkZWY=
```

Flutter Example:
```dart
final response = await http.get(
  Uri.parse('http://your-api.com/api/profile.php?action=get'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
```

### Logout

**Endpoint:** `POST /api/auth.php?action=logout`

**Headers:** `Authorization: Bearer <token>`

---

## 📊 Dropdown Data

### Get All Dropdowns (Recommended)

**Endpoint:** `GET /api/dropdowns.php?type=all`

**Response:**
```json
{
  "status": true,
  "message": "All dropdowns fetched",
  "data": {
    "religions": [
      {"id": 1, "name": "Hindu"},
      {"id": 2, "name": "Muslim"}
    ],
    "mother_tongues": [
      {"id": 1, "name": "Hindi"},
      {"id": 2, "name": "Marathi"}
    ],
    "states": [
      {"id": 1, "name": "Maharashtra"},
      {"id": 14, "name": "Delhi"}
    ],
    "education_levels": [...],
    "income_ranges": [...],
    "marital_statuses": [...],
    "profile_for_options": [...],
    "heights": [
      {"id": 1, "name": "4'6\"", "cm_value": 137}
    ],
    "eating_habits": [...],
    "smoking_habits": [...],
    "drinking_habits": [...],
    "body_types": [...],
    "complexions": [...],
    "blood_groups": [...],
    "disabilities": [...],
    "country_codes": [
      {"id": 1, "country_name": "India", "code": "+91"}
    ]
  }
}
```

### Individual Dropdown

**Endpoint:** `GET /api/dropdowns.php?type=religions`

Available types:
- `religions`
- `mother_tongues`
- `states`
- `education_levels`
- `income_ranges`
- `marital_statuses`
- `profile_for_options`
- `heights`
- `eating_habits`
- `smoking_habits`
- `drinking_habits`
- `body_types`
- `complexions`
- `blood_groups`
- `disabilities`
- `country_codes`

---

## 👤 Profile Management

All profile APIs require **Authorization token**.

### 1. Save Profile For

**Endpoint:** `POST /api/profile.php?action=save_profile_for`

**Request:**
```json
{
  "profile_for": "Myself"
}
```

Valid values: `Myself`, `Son`, `Daughter`, `Brother`, `Sister`, `Friend`

### 2. Save Basic Details

**Endpoint:** `POST /api/profile.php?action=save_basic`

**Request:**
```json
{
  "full_name": "Rahul Sharma",
  "dob": "1995-05-15",
  "gender": "Male"
}
```

Valid gender: `Male`, `Female`, `Other`

### 3. Save Religion & Community

**Endpoint:** `POST /api/profile.php?action=save_religion`

**Request:**
```json
{
  "religion_id": 1,
  "caste": "Brahmin",
  "mother_tongue_id": 1
}
```

### 4. Save Location

**Endpoint:** `POST /api/profile.php?action=save_location`

**Request:**
```json
{
  "state_id": 14,
  "city": "Mumbai"
}
```

### 5. Save Education & Career

**Endpoint:** `POST /api/profile.php?action=save_education`

**Request:**
```json
{
  "education_id": 5,
  "profession": "Software Engineer",
  "income_id": 6
}
```

### 6. Save Habits & Physical Details

**Endpoint:** `POST /api/profile.php?action=save_habits`

**Request:**
```json
{
  "height_id": 15,
  "weight": "70 kg",
  "eating_habit_id": 1,
  "smoking_habit_id": 1,
  "drinking_habit_id": 1,
  "disability_id": 1,
  "marital_status_id": 1,
  "body_type_id": 2,
  "complexion_id": 2,
  "blood_group_id": 1
}
```

### 7. Save Partner Preference

**Endpoint:** `POST /api/profile.php?action=save_preference`

**Request:**
```json
{
  "age_min": 22,
  "age_max": 30,
  "religion_id": 1,
  "min_height_id": 10,
  "max_height_id": 20,
  "income_id": 5
}
```

### 8. Save About Me

**Endpoint:** `POST /api/profile.php?action=save_about`

**Request:**
```json
{
  "bio": "I am a software engineer working in Mumbai. Looking for a life partner who shares similar values and interests."
}
```

### 9. Upload Photo

**Endpoint:** `POST /api/profile.php?action=upload_photo`

**Content-Type:** `multipart/form-data`

**Form Data:**
```
photo: <image file>
```

Flutter Example:
```dart
var request = http.MultipartRequest(
  'POST',
  Uri.parse('http://your-api.com/api/profile.php?action=upload_photo'),
);
request.headers['Authorization'] = 'Bearer $token';
request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
var response = await request.send();
```

**Response:**
```json
{
  "status": true,
  "message": "Photo uploaded successfully",
  "data": {
    "photo_url": "http://your-api.com/api/uploads/user_1_1735167890.jpg",
    "is_primary": true
  }
}
```

### 10. Get Complete Profile

**Endpoint:** `GET /api/profile.php?action=get`

**Response:**
```json
{
  "status": true,
  "message": "Success",
  "data": {
    "phone": "9876543210",
    "country_code": "+91",
    "profile_for": "Myself",
    "full_name": "Rahul Sharma",
    "dob": "1995-05-15",
    "gender": "Male",
    "bio": "Software engineer...",
    "is_profile_complete": true,
    "profile_photo_url": "http://...",
    "religion": {
      "religion": "Hindu",
      "caste": "Brahmin",
      "mother_tongue": "Hindi",
      "religion_id": 1,
      "mother_tongue_id": 1
    },
    "location": {
      "state": "Maharashtra",
      "city": "Mumbai",
      "state_id": 14
    },
    "education": {
      "education": "Graduate",
      "profession": "Software Engineer",
      "income": "5-10 Lakh",
      "education_id": 5,
      "income_id": 5
    },
    "habits": {
      "height": "5'8\"",
      "weight": "70 kg",
      "eating_habit": "Vegetarian",
      ...
    },
    "partner_preference": {
      "age_min": 22,
      "age_max": 30,
      "religion": "Hindu",
      ...
    },
    "photos": [
      {
        "id": 1,
        "url": "http://...",
        "is_primary": 1
      }
    ]
  }
}
```

---

## 💑 Matches API

### Find Matches

**Endpoint:** `GET /api/matches.php?action=find`

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "status": true,
  "message": "Matches found",
  "data": {
    "total": 25,
    "matches": [
      {
        "user_id": 5,
        "full_name": "Priya Patel",
        "profile_photo_url": "http://...",
        "age": 26,
        "gender": "Female",
        "religion": "Hindu",
        "state": "Gujarat",
        "city": "Ahmedabad",
        "height": "5'4\"",
        "education": "Graduate",
        "profession": "Teacher"
      }
    ]
  }
}
```

### View Specific Profile

**Endpoint:** `GET /api/matches.php?action=view&id=5`

**Headers:** `Authorization: Bearer <token>`

**Response:** Complete profile details of the user

---

## 📤 Response Format

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

### Common HTTP Status Codes

- `200` - Success
- `400` - Bad Request (validation error)
- `401` - Unauthorized (token missing/invalid)
- `404` - Not Found
- `405` - Method Not Allowed
- `500` - Server Error

---

## 🔧 Common Issues & Solutions

### 1. CORS Error in Flutter

Make sure `config.php` mein CORS headers set hain:
```php
header('Access-Control-Allow-Origin: *');
```

### 2. Token Not Working

Check karo:
- Token Bearer format mein hai: `Bearer <token>`
- Token expired to nahi (30 days)
- User verified hai

### 3. Photo Upload Fail

- `uploads/` folder create karo
- Folder ko write permission do
- `UPLOAD_DIR` aur `UPLOAD_URL` config.php mein sahi hain

### 4. Database Connection Error

- MySQL server running hai?
- Username/password sahi hai?
- Database `wedding_india_db` create ho gaya?

---

## 📱 Flutter Integration Example

```dart
class ApiService {
  static const String baseUrl = 'http://your-api.com/api';
  String? token;
  
  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth.php?action=send_otp'),
      body: json.encode({'phone': phone, 'country_code': '+91'}),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }
  
  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth.php?action=verify_otp'),
      body: json.encode({
        'phone': phone,
        'country_code': '+91',
        'otp': otp,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    final data = json.decode(response.body);
    if (data['status']) {
      token = data['data']['token'];
    }
    return data;
  }
  
  // Get Dropdowns
  Future<Map<String, dynamic>> getDropdowns() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dropdowns.php?type=all'),
    );
    return json.decode(response.body);
  }
  
  // Save Basic Details
  Future<Map<String, dynamic>> saveBasicDetails({
    required String fullName,
    required String dob,
    required String gender,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile.php?action=save_basic'),
      body: json.encode({
        'full_name': fullName,
        'dob': dob,
        'gender': gender,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return json.decode(response.body);
  }
  
  // Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile.php?action=get'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }
  
  // Find Matches
  Future<Map<String, dynamic>> findMatches() async {
    final response = await http.get(
      Uri.parse('$baseUrl/matches.php?action=find'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }
}
```

---

## 📞 Support

Issues ya questions ke liye:
- GitHub Issues create karo
- Email: support@weddingindia.com

---

## 📝 License

© 2025 Wedding India App. All rights reserved.
