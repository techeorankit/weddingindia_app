import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // all PHP files are in root /public_html/
  static const String baseUrl = 'https://weddingindiamatrimony.com/';
  static const String rootUrl = 'https://weddingindiamatrimony.com/';

  static String? _sessionCookie;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    _sessionCookie = null;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  // POST helper — root URL ke liye
  static Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _authHeaders();
      final url = '$rootUrl$endpoint';
      dev.log('POST $url', name: 'API');
      dev.log('Body: ${jsonEncode(body)}', name: 'API');
      final response = await http
          .post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 20));

      dev.log('Response ${response.statusCode}: ${response.body}', name: 'API');

      final decoded = jsonDecode(response.body);
      return decoded;
    } on http.ClientException catch (e) {
      dev.log('ClientException: $e', name: 'API');
      return {'status': false, 'message': 'Unable to connect to server: $e'};
    } catch (e) {
      dev.log('Error: $e', name: 'API');
      return {'status': false, 'message': 'Error: $e'};
    }
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String countryCode,
  }) async {
    try {
      final client = http.Client();

      final response = await client.post(
        Uri.parse('${rootUrl}send_otp.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'mobile': phone,
          'country_code': countryCode,
        },
      );

      dev.log('Send OTP Status: ${response.statusCode}', name: 'API');
      dev.log('Send OTP Body: ${response.body}', name: 'API');

      final cookie = response.headers['set-cookie'];
      if (cookie != null) {
        _sessionCookie = cookie;
        dev.log('Session Cookie saved: $_sessionCookie', name: 'API');
      } else {
        dev.log('No session cookie received', name: 'API');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' || data['status'] == true) {
          return {
            'status': 'success',
            'message': data['message'] ?? 'OTP sent successfully to your phone',
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to send OTP',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      dev.log('Send OTP Error: $e', name: 'API');
      return {
        'status': 'error',
        'message': 'Network error: $e',
      };
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String countryCode,
    required String otp,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };

      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
        dev.log('Using Session Cookie for verification: $_sessionCookie', name: 'API');
      } else {
        dev.log('No session cookie available for verification', name: 'API');
      }

      final response = await http.post(
        Uri.parse('${rootUrl}verify_otp.php'),
        headers: headers,
        body: {
          'mobile': phone,
          'country_code': countryCode,
          'otp': otp,
        },
      ).timeout(const Duration(seconds: 20));

      dev.log('Verify OTP Status: ${response.statusCode}', name: 'API');
      dev.log('Verify OTP Body: ${response.body}', name: 'API');

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        if (data['data'] != null) {
          if (data['data']['token'] != null) {
            await saveToken(data['data']['token']);
          }
          if (data['data']['user_id'] != null) {
            await saveUserId(data['data']['user_id']);
          }
        }
        _sessionCookie = null;
      }
      return data;
    } catch (e) {
      dev.log('Verify OTP Error: $e', name: 'API');
      return {'status': false, 'message': 'Server error: $e'};
    }
  }

  static Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http
          .post(Uri.parse('${rootUrl}auth.php?action=logout'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
    await clearSession();
  }

  static Future<Map<String, dynamic>> getUpgradeData() async {
    try {
      final response = await http
          .get(Uri.parse('${rootUrl}upgrade.php'))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${rootUrl}upgrade.php?action=status'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> subscribeToPlan({
    required int planId,
    required String paymentReference,
  }) async =>
      _post('upgrade.php?action=subscribe', {
        'plan_id': planId,
        'payment_reference': paymentReference,
      });

  static Future<Map<String, dynamic>> getAppContent() async {
    try {
      final response = await http
          .get(Uri.parse('${rootUrl}content.php'))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDropdowns() async {
    try {
      final response = await http
          .get(Uri.parse('${rootUrl}dropdowns.php?type=all'))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> saveProfileFor(String profileFor) async =>
      _post('profile.php?action=save_profile_for', {'profile_for': profileFor});

  static Future<Map<String, dynamic>> saveBasicDetails({
    required String fullName,
    required String dob,
    required String gender,
  }) async =>
      _post('profile.php?action=save_basic', {
        'full_name': fullName,
        'dob': dob,
        'gender': gender,
      });

  static Future<Map<String, dynamic>> saveReligion({
    required int religionId,
    String? caste,
    int? motherTongueId,
  }) async =>
      _post('profile.php?action=save_religion', {
        'religion_id': religionId,
        'caste': caste ?? '',
        'mother_tongue_id': motherTongueId,
      });

  static Future<Map<String, dynamic>> saveLocation({
    required int stateId,
    required String city,
  }) async =>
      _post('profile.php?action=save_location', {
        'state_id': stateId,
        'city': city,
      });

  static Future<Map<String, dynamic>> saveEducation({
    required int educationId,
    String? profession,
    int? incomeId,
  }) async =>
      _post('profile.php?action=save_education', {
        'education_id': educationId,
        'profession': profession ?? '',
        'income_id': incomeId,
      });

  static Future<Map<String, dynamic>> saveHabits({
    int? heightId,
    String? weight,
    int? eatingHabitId,
    int? smokingHabitId,
    int? drinkingHabitId,
    int? disabilityId,
    int? maritalStatusId,
    int? bodyTypeId,
    int? complexionId,
    int? bloodGroupId,
  }) async =>
      _post('profile.php?action=save_habits', {
        'height_id': heightId,
        'weight': weight,
        'eating_habit_id': eatingHabitId,
        'smoking_habit_id': smokingHabitId,
        'drinking_habit_id': drinkingHabitId,
        'disability_id': disabilityId,
        'marital_status_id': maritalStatusId,
        'body_type_id': bodyTypeId,
        'complexion_id': complexionId,
        'blood_group_id': bloodGroupId,
      });

  static Future<Map<String, dynamic>> savePartnerPreference({
    required int ageMin,
    required int ageMax,
    int? religionId,
    int? minHeightId,
    int? maxHeightId,
    int? incomeId,
  }) async =>
      _post('profile.php?action=save_preference', {
        'age_min': ageMin,
        'age_max': ageMax,
        'religion_id': religionId,
        'min_height_id': minHeightId,
        'max_height_id': maxHeightId,
        'income_id': incomeId,
      });

  static Future<Map<String, dynamic>> saveAboutMe(String bio) async =>
      _post('profile.php?action=save_about', {'bio': bio});

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async =>
      _post('profile.php?action=update_profile', data);

  /// Profile photo upload
  static Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('${rootUrl}profile.php?action=upload_photo');

      dev.log('Uploading photo to $uri', name: 'API');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'photo',
            imageFile.path,
          ),
        );

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      dev.log('Upload response ${response.statusCode}: ${response.body}', name: 'API');

      return jsonDecode(response.body);
    } catch (e) {
      dev.log('uploadProfilePhoto error: $e', name: 'API');
      return {'status': false, 'message': 'Photo upload failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadDocument({
    required File documentFile,
    required String documentType,
    required File selfieFile,
  }) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('${rootUrl}document.php');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['document_type'] = documentType
        ..files.add(await http.MultipartFile.fromPath('document', documentFile.path))
        ..files.add(await http.MultipartFile.fromPath('selfie', selfieFile.path));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      dev.log('Document upload response ${response.statusCode}: ${response.body}', name: 'API');
      return jsonDecode(response.body);
    } catch (e) {
      dev.log('uploadDocument error: $e', name: 'API');
      return {'status': false, 'message': 'Document upload failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${rootUrl}profile.php?action=get');
      dev.log('User profile API: $uri', name: 'ProfileAPI');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      dev.log(
        'Profile photo URL: ${data['data']?['profile_photo_url'] ?? 'No profile photo'}',
        name: 'ProfileAPI',
      );
      return data;
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendInteraction({
    required int toUserId,
    required String type,
  }) async =>
      _post('interactions.php', {'to_user_id': toUserId, 'type': type});

  static Future<Map<String, dynamic>> viewProfile(int userId) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${rootUrl}matches.php?action=view&id=$userId');
      dev.log('Other user profile API: $uri', name: 'ProfileAPI');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      dev.log(
        'Viewed profile $userId photo URL: ${data['data']?['profile_photo_url'] ?? 'No profile photo'}',
        name: 'ProfileAPI',
      );
      return data;
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> findMatches() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${rootUrl}matches.php?action=find'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  // ─── PAYMENT / CASHFREE ──────────────────────────────────────────────────

  /// Gateway enabled hai ya nahi
  static Future<Map<String, dynamic>> getGatewayStatus() async {
    try {
      final response = await http
          .get(Uri.parse('${baseUrl}payment.php?action=gateway_status'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  /// Cashfree order create karo
  static Future<Map<String, dynamic>> createPaymentOrder({
    required int planId,
  }) async {
    try {
      final headers = await _authHeaders();
      final url = '${baseUrl}payment.php?action=create_order';
      dev.log('POST $url', name: 'API');
      final response = await http
          .post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'plan_id': planId}),
      )
          .timeout(const Duration(seconds: 20));
      dev.log('Response ${response.statusCode}: ${response.body}', name: 'API');
      return jsonDecode(response.body);
    } on http.ClientException catch (e) {
      return {'status': false, 'message': 'Unable to connect to server: $e'};
    } catch (e) {
      return {'status': false, 'message': 'Error: $e'};
    }
  }

  /// Payment verify karo
  static Future<Map<String, dynamic>> verifyPayment({
    required String cfOrderId,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${baseUrl}payment.php?action=verify&order_id=${Uri.encodeComponent(cfOrderId)}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }
}
