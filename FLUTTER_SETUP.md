# 📱 Flutter App - API Integration Setup

## ✅ Completed

Main API integration kar diya hai aapke app mein!

### Files Created/Updated:
- ✅ `lib/services/api_service.dart` - Complete API service with all endpoints
- ✅ `lib/screens/register_screen.dart` - Send OTP se connect
- ✅ `lib/screens/otp_screen.dart` - Verify OTP se connect
- ✅ `pubspec.yaml` - Dependencies add kiye (`http`, `shared_preferences`)

---

## 🚀 Setup Steps

### Step 1: Install Dependencies

```bash
cd d:\wedding-india-app
flutter pub get
```

### Step 2: Update API Base URL

`lib/services/api_service.dart` file mein **line 9** pe API URL update karo:

#### For Android Emulator:
```dart
static const String baseUrl = 'http://10.0.2.2/wedding-india-app/api';
```

#### For Physical Device (same WiFi):
```dart
// Apna laptop ka IP address daalo (check: ipconfig)
static const String baseUrl = 'http://192.168.x.x/wedding-india-app/api';
```

#### For iOS Simulator:
```dart
static const String baseUrl = 'http://localhost/wedding-india-app/api';
```

#### For Production:
```dart
static const String baseUrl = 'https://your-domain.com/api';
```

---

## 🧪 Testing

### 1. Backend Test
Pehle backend ready hai ya nahi check karo:
```
http://localhost/wedding-india-app/api/test.php
```

### 2. Run Flutter App
```bash
flutter run
```

### 3. Test Flow:
1. ✅ Splash screen (3 seconds)
2. ✅ Register screen
   - Phone number daalo: `9876543210`
   - "Send OTP" click karo
   - Snackbar mein OTP dikhenga (dev mode mein)
3. ✅ OTP screen
   - OTP daalo (jo snackbar mein dikha)
   - Auto verify hoga ya "Verify OTP" click karo
   - Token save hoga
4. ✅ Profile creation start (ProfileForScreen)

---

## 🔧 Common Issues & Solutions

### Issue 1: "Network Error" or "Connection Refused"

**Solution:**
```bash
# Check karo backend chal raha hai:
# Browser mein open karo:
http://localhost/wedding-india-app/api/dropdowns.php?type=all

# Agar data aaya to backend OK hai
# Nahi aaya to:
# 1. XAMPP mein Apache/MySQL start karo
# 2. Database import kiya hai ya nahi check karo
# 3. config.php mein credentials sahi hain ya nahi
```

### Issue 2: Android Emulator me "Failed to Connect"

**Solution:**
```dart
// api_service.dart mein URL check karo:
// Android Emulator ke liye 10.0.2.2 use karo
static const String baseUrl = 'http://10.0.2.2/wedding-india-app/api';
```

### Issue 3: Physical Device me "Network Error"

**Solution:**
```bash
# 1. Check laptop aur phone same WiFi pe hain
# 2. Laptop ka IP address find karo:
#    Windows: ipconfig (look for IPv4)
#    Mac/Linux: ifconfig

# 3. URL update karo:
static const String baseUrl = 'http://192.168.1.100/wedding-india-app/api';

# 4. Firewall check karo:
#    Windows Firewall mein Apache ko allow karo
```

### Issue 4: "Invalid OTP"

**Solution:**
```dart
// Development mode mein OTP snackbar mein show hota hai
// Production mein SMS gateway integrate karna hoga

// Temporary testing ke liye database check karo:
// phpMyAdmin → users table → otp column
```

---

## 📝 What Works Now

### ✅ Authentication:
- [x] Phone number validation
- [x] Send OTP API call
- [x] OTP verification
- [x] Token save (SharedPreferences)
- [x] Auto-navigate based on profile status

### 🔄 Next Steps (Already Available in API):
Profile screens mein bhi API connect karna hai:

1. **ProfileForScreen** → `ApiService.saveProfileFor()`
2. **BasicDetailsScreen** → `ApiService.saveBasicDetails()`
3. **ReligionScreen** → `ApiService.saveReligion()`
4. **LocationScreen** → `ApiService.saveLocation()`
5. **EducationScreen** → `ApiService.saveEducation()`
6. **HabitsDetailsScreen** → `ApiService.saveHabits()`
7. **PartnerPreferenceScreen** → `ApiService.savePartnerPreference()`

Main `ApiService` mein sab functions ready hain, sirf screens mein call karna hai!

---

## 🎯 API Service Usage Examples

### Example 1: Save Profile For
```dart
final result = await ApiService.saveProfileFor('Myself');
if (result['status'] == true) {
  // Success - next screen pe jao
} else {
  // Error - message show karo
  print(result['message']);
}
```

### Example 2: Save Basic Details
```dart
final result = await ApiService.saveBasicDetails(
  fullName: 'Rahul Sharma',
  dob: '1995-05-15',
  gender: 'Male',
);
```

### Example 3: Get Profile
```dart
final result = await ApiService.getProfile();
if (result['status'] == true) {
  final profile = result['data'];
  print(profile['full_name']);
  print(profile['religion']);
}
```

---

## 📊 API Response Format

All APIs return same format:

### Success:
```json
{
  "status": true,
  "message": "Success message",
  "data": { ... }
}
```

### Error:
```json
{
  "status": false,
  "message": "Error message",
  "data": null
}
```

---

## 🔒 Security

- ✅ Token automatically saved after OTP verification
- ✅ Token automatically added to API headers
- ✅ Token stored securely in SharedPreferences
- ✅ Session management handled

---

## 📞 Testing Credentials

**Development Mode:**
- Phone: Any 10-digit number (e.g., `9876543210`)
- OTP will show in snackbar (dev mode)
- Production mein SMS gateway integrate karna hoga

---

## 🎉 Summary

| Component | Status |
|-----------|--------|
| Backend API | ✅ Ready |
| Database | ✅ Ready |
| ApiService | ✅ Created |
| Login/Register | ✅ Connected |
| OTP Verification | ✅ Connected |
| Token Management | ✅ Implemented |
| Profile APIs | ✅ Ready (need to connect screens) |

**Next:** Profile screens mein API calls add karo!

---

## 🛠️ Quick Commands

```bash
# Install dependencies
flutter pub get

# Run on emulator
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Hot reload (development)
# Press 'r' in terminal

# Hot restart
# Press 'R' in terminal

# Clear and rebuild
flutter clean
flutter pub get
flutter run
```

---

**Happy Coding! 🚀**
