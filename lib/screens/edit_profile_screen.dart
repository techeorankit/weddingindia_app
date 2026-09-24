import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/photo_gallery_widget.dart';
import 'register_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _casteController = TextEditingController();
  final _cityController = TextEditingController();
  final _professionController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _dob;
  String? _gender;
  String? _profileFor;
  String? _religion;
  String? _state;
  String? _education;
  String? _income;
  String? _height;
  String? _weight;
  String? _eatingHabit;
  String? _smokingHabit;
  String? _drinkingHabit;
  String? _disability;
  String? _maritalStatus;
  String? _bodyType;
  String? _complexion;
  String? _bloodGroup;
  // Family fields
  String? _motherOccupation;
  String? _fatherOccupation;
  String? _brothers;
  String? _sisters;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  // Photo state
  File? _pickedImage;
  String? _existingPhotoUrl;
  bool _isUploadingPhoto = false;
  List<Map<String, dynamic>> _photos = [];

  static const Map<String, int> _religionIds = {
    'Hindu': 1, 'Muslim': 2, 'Christian': 3, 'Sikh': 4,
    'Jain': 5, 'Buddhist': 6, 'Other': 7,
  };
  static const Map<String, int> _stateIds = {
    'Maharashtra': 14, 'Delhi': 29, 'Gujarat': 7, 'Rajasthan': 21,
    'Uttar Pradesh': 26, 'Karnataka': 11, 'Tamil Nadu': 23,
    'West Bengal': 28, 'Punjab': 20, 'Madhya Pradesh': 13,
    'Bihar': 4, 'Haryana': 8, 'Andhra Pradesh': 1,
    'Telangana': 24, 'Kerala': 12, 'Other': 30,
  };
  static const Map<String, int> _educationIds = {
    'Below 10th': 1, '10th Pass': 2, '12th Pass': 3, 'Diploma': 4,
    'Graduate': 5, 'Post Graduate': 6, 'Doctorate': 7, 'Other': 8,
  };
  static const Map<String, int> _incomeIds = {
    'No Income': 1, 'Below 1 Lakh': 2, '1-2 Lakh': 3, '2-5 Lakh': 4,
    '5-10 Lakh': 5, '10-20 Lakh': 6, '20-50 Lakh': 7,
    '50 Lakh - 1 Crore': 8, '1-2 Crore': 9, '2-3 Crore': 10,
    '3-4 Crore': 11, '4-5 Crore': 12, '5+ Crore': 13,
  };
  static const Map<String, int> _heightIds = {
    "4'6\"": 1, "4'7\"": 2, "4'8\"": 3, "4'9\"": 4, "4'10\"": 5,
    "4'11\"": 6, "5'0\"": 7, "5'1\"": 8, "5'2\"": 9, "5'3\"": 10,
    "5'4\"": 11, "5'5\"": 12, "5'6\"": 13, "5'7\"": 14, "5'8\"": 15,
    "5'9\"": 16, "5'10\"": 17, "5'11\"": 18, "6'0\"": 19, "6'1\"": 20,
    "6'2\"": 21, "6'3\"": 22, "6'4\"": 23,
  };
  static const Map<String, int> _eatingIds = {'Vegetarian': 1, 'Non-Vegetarian': 2, 'Eggetarian': 3, 'Vegan': 4};
  static const Map<String, int> _smokingIds = {'No': 1, 'Occasionally': 2, 'Yes': 3};
  static const Map<String, int> _drinkingIds = {'No': 1, 'Occasionally': 2, 'Yes': 3};
  static const Map<String, int> _disabilityIds = {'None': 1, 'Physically Challenged': 2, 'Visually Impaired': 3, 'Hearing Impaired': 4, 'Other': 5};
  static const Map<String, int> _maritalIds = {'Never Married': 1, 'Divorced': 2, 'Widowed': 3, 'Awaiting Divorce': 4};
  static const Map<String, int> _bodyTypeIds = {'Slim': 1, 'Average': 2, 'Athletic': 3, 'Heavy': 4};
  static const Map<String, int> _complexionIds = {'Very Fair': 1, 'Fair': 2, 'Wheatish': 3, 'Dark': 4};
  static const Map<String, int> _bloodGroupIds = {'A+': 1, 'A-': 2, 'B+': 3, 'B-': 4, 'AB+': 5, 'AB-': 6, 'O+': 7, 'O-': 8};

  final List<String> _profileForOptions = ['Myself', 'Son', 'Daughter', 'Brother', 'Sister', 'Friend'];
  final List<String> _weights = List.generate(81, (i) => '${i + 40} kg');

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final p = widget.profile;
    _nameController.text = p['full_name'] ?? '';
    _bioController.text = p['bio'] ?? '';
    _gender = p['gender'];
    _profileFor = p['profile_for'];
    _existingPhotoUrl = p['profile_photo_url']?.toString();

    // Load existing photos for gallery
    final rawPhotos = p['photos'];
    if (rawPhotos is List) {
      _photos = rawPhotos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      // Fallback: use profile photo as single item
      _photos = [{'id': 0, 'url': _existingPhotoUrl!, 'is_primary': true}];
    }

    if (p['dob'] != null && p['dob'].toString().isNotEmpty) {
      final parts = p['dob'].toString().split('-');
      if (parts.length == 3) {
        _dob = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    }

    final religion = p['religion'] as Map?;
    if (religion != null) {
      _religion = religion['religion'];
      _casteController.text = religion['caste'] ?? '';
    }

    final location = p['location'] as Map?;
    if (location != null) {
      _state = location['state'];
      _cityController.text = location['city'] ?? '';
    }

    final education = p['education'] as Map?;
    if (education != null) {
      _education = education['education'];
      _professionController.text = education['profession'] ?? '';
      _income = education['income'];
    }

    final habits = p['habits'] as Map?;
    if (habits != null) {
      _height = habits['height'];
      _weight = habits['weight'];
      _eatingHabit = habits['eating_habit'];
      _smokingHabit = habits['smoking_habit'];
      _drinkingHabit = habits['drinking_habit'];
      _disability = habits['disability'];
      _maritalStatus = habits['marital_status'];
      _bodyType = habits['body_type'];
      _complexion = habits['complexion'];
      _bloodGroup = habits['blood_group'];
    }

    // Family fields
    _motherOccupation = p['mother_occupation']?.toString();
    _fatherOccupation = p['father_occupation']?.toString();
    final bro = p['brothers'];
    final sis = p['sisters'];
    _brothers = bro != null ? bro.toString() : null;
    _sisters  = sis != null ? sis.toString() : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _casteController.dispose();
    _cityController.dispose();
    _professionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String get _dobForApi => _dob == null
      ? ''
      : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}';

  /// Gallery se image pick karo
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  /// Pehle photo upload karo (agar naya pick kiya), phir profile data save karo
  Future<void> _save() async {
    setState(() => _isLoading = true);

    // Step 1: Agar naya image pick kiya hai toh pehle upload karo
    if (_pickedImage != null) {
      setState(() => _isUploadingPhoto = true);
      final uploadResult = await ApiService.uploadProfilePhoto(_pickedImage!);
      setState(() => _isUploadingPhoto = false);

      if (!mounted) return;
      if (uploadResult['status'] != true) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(uploadResult['message'] ?? 'Photo upload failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }

    // Step 2: Profile details save karo
    final result = await ApiService.updateProfile({
      'full_name': _nameController.text.trim(),
      'dob': _dobForApi,
      'gender': _gender,
      'profile_for': _profileFor,
      'bio': _bioController.text.trim(),
      'religion_id': _religion != null ? _religionIds[_religion!] : null,
      'caste': _casteController.text.trim(),
      'state_id': _state != null ? _stateIds[_state!] : null,
      'city': _cityController.text.trim(),
      'education_id': _education != null ? _educationIds[_education!] : null,
      'profession': _professionController.text.trim(),
      'income_id': _income != null ? _incomeIds[_income!] : null,
      'height_id': _height != null ? _heightIds[_height!] : null,
      'weight': _weight,
      'eating_habit_id': _eatingHabit != null ? _eatingIds[_eatingHabit!] : null,
      'smoking_habit_id': _smokingHabit != null ? _smokingIds[_smokingHabit!] : null,
      'drinking_habit_id': _drinkingHabit != null ? _drinkingIds[_drinkingHabit!] : null,
      'disability_id': _disability != null ? _disabilityIds[_disability!] : null,
      'marital_status_id': _maritalStatus != null ? _maritalIds[_maritalStatus!] : null,
      'body_type_id': _bodyType != null ? _bodyTypeIds[_bodyType!] : null,
      'complexion_id': _complexion != null ? _complexionIds[_complexion!] : null,
      'blood_group_id': _bloodGroup != null ? _bloodGroupIds[_bloodGroup!] : null,
      'mother_occupation': _motherOccupation,
      'father_occupation': _fatherOccupation,
      'brothers': _brothers != null ? int.tryParse(_brothers!) : null,
      'sisters': _sisters != null ? int.tryParse(_sisters!) : null,
    });
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result['status'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Something went wrong'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;
    setState(() => _isLoggingOut = true);
    await ApiService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE91E63)))
                : const Text('Save', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Photo Section ──────────────────────────
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Photo display
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!) as ImageProvider
                            : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                                ? NetworkImage(_existingPhotoUrl!)
                                : null),
                        child: (_pickedImage == null &&
                                (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty))
                            ? const Icon(Icons.person, size: 56, color: Colors.grey)
                            : null,
                      ),
                      // Upload loading overlay
                      if (_isUploadingPhoto)
                        Positioned.fill(
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: Colors.black38,
                            child: const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ),
                      // Camera button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _pickImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pickedImage != null ? 'Tap Save to upload photo' : 'Tap camera to change photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: _pickedImage != null ? const Color(0xFFE91E63) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── End Profile Photo Section ──────────────────────

            // ── Photo Gallery (up to 5 photos) ─────────────────
            const SizedBox(height: 16),
            PhotoGalleryWidget(
              initialPhotos: _photos,
              editable: true,
            ),
            const SizedBox(height: 8),

            _section('Basic Details'),
            _label('Full Name'),
            _textField(_nameController, 'Enter full name'),
            const SizedBox(height: 16),
            _label('Date of Birth'),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime(2005),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63))),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _dob = picked);
              },
              child: Container(
                width: double.infinity,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dob == null ? 'Select Date of Birth' : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                      style: TextStyle(color: _dob == null ? Colors.grey : Colors.black, fontSize: 15),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFFE91E63), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _label('Gender'),
            _chipRow(['Male', 'Female', 'Other'], _gender, (v) => setState(() => _gender = v)),
            const SizedBox(height: 16),
            _label('Profile For'),
            _dropdownField(_profileFor, _profileForOptions, 'Select', (v) => setState(() => _profileFor = v)),
            const SizedBox(height: 16),
            _label('About Me'),
            _textField(_bioController, 'Write something about yourself', maxLines: 3),

            _section('Religion & Community'),
            _label('Religion'),
            _chipWrap(_religionIds.keys.toList(), _religion, (v) => setState(() => _religion = v)),
            const SizedBox(height: 16),
            _label('Caste / Community'),
            _textField(_casteController, 'Enter caste or community'),

            _section('Location'),
            _label('State'),
            _dropdownField(_state, _stateIds.keys.toList(), 'Select State', (v) => setState(() => _state = v)),
            const SizedBox(height: 16),
            _label('City'),
            _textField(_cityController, 'Enter city'),

            _section('Education & Career'),
            _label('Highest Education'),
            _chipWrap(_educationIds.keys.toList(), _education, (v) => setState(() => _education = v)),
            const SizedBox(height: 16),
            _label('Profession'),
            _textField(_professionController, 'e.g. Software Engineer, Doctor'),
            const SizedBox(height: 16),
            _label('Annual Income'),
            _dropdownField(_income, _incomeIds.keys.toList(), 'Select Income', (v) => setState(() => _income = v)),

            _section('Physical & Lifestyle'),
            _buildDropdown('Height', _height, _heightIds.keys.toList(), (v) => setState(() => _height = v)),
            _buildDropdown('Weight', _weight, _weights, (v) => setState(() => _weight = v)),
            _buildDropdown('Eating Habit', _eatingHabit, _eatingIds.keys.toList(), (v) => setState(() => _eatingHabit = v)),
            _buildDropdown('Smoking Habit', _smokingHabit, _smokingIds.keys.toList(), (v) => setState(() => _smokingHabit = v)),
            _buildDropdown('Drinking Habit', _drinkingHabit, _drinkingIds.keys.toList(), (v) => setState(() => _drinkingHabit = v)),
            _buildDropdown('Disability', _disability, _disabilityIds.keys.toList(), (v) => setState(() => _disability = v)),
            _buildDropdown('Marital Status', _maritalStatus, _maritalIds.keys.toList(), (v) => setState(() => _maritalStatus = v)),
            _buildDropdown('Body Type', _bodyType, _bodyTypeIds.keys.toList(), (v) => setState(() => _bodyType = v)),
            _buildDropdown('Complexion', _complexion, _complexionIds.keys.toList(), (v) => setState(() => _complexion = v)),
            _buildDropdown('Blood Group', _bloodGroup, _bloodGroupIds.keys.toList(), (v) => setState(() => _bloodGroup = v)),

            // ── Family Details ──────────────────────────────────────────────
            _section('Family Details'),
            _label('Mother\'s Occupation'),
            _chipWrap(
              ['Housewife', 'Business Woman', 'Job', 'Retired', 'Not Alive'],
              _motherOccupation,
              (v) => setState(() => _motherOccupation = v),
            ),
            const SizedBox(height: 16),
            _label('Father\'s Occupation'),
            _chipWrap(
              ['Business Man', 'Job', 'Retired', 'Not Alive'],
              _fatherOccupation,
              (v) => setState(() => _fatherOccupation = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Brothers'),
                      _dropdownField(
                        _brothers,
                        ['0', '1', '2', '3', '4', '5+'],
                        'Select',
                        (v) => setState(() => _brothers = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Sisters'),
                      _dropdownField(
                        _sisters,
                        ['0', '1', '2', '3', '4', '5+'],
                        'Select',
                        (v) => setState(() => _sisters = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isLoggingOut ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                                const SizedBox(width: 10),
                                Text(
                                  _isUploadingPhoto ? 'Uploading...' : 'Saving...',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            )
                          : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading || _isLoggingOut ? null : _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoggingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                            )
                          : const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );

  Widget _textField(TextEditingController c, String hint, {int maxLines = 1}) => TextField(
        controller: c,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE91E63))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _dropdownField(String? value, List<String> items, String hint, ValueChanged<String?> onChanged) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint),
            isExpanded: true,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _chipRow(List<String> options, String? selected, ValueChanged<String> onTap) => Row(
        children: options.map((o) {
          final isSel = selected == o;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onTap(o),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFFFE4EF) : Colors.grey.shade50,
                    border: Border.all(color: isSel ? const Color(0xFFE91E63) : Colors.grey.shade200, width: isSel ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(o, style: TextStyle(
                      color: isSel ? const Color(0xFFE91E63) : Colors.black87,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _chipWrap(List<String> options, String? selected, ValueChanged<String> onTap) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: options.map((o) {
          final isSel = selected == o;
          return GestureDetector(
            onTap: () => onTap(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFFFE4EF) : Colors.grey.shade50,
                border: Border.all(color: isSel ? const Color(0xFFE91E63) : Colors.grey.shade200, width: isSel ? 2 : 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(o, style: TextStyle(
                color: isSel ? const Color(0xFFE91E63) : Colors.black87,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              )),
            ),
          );
        }).toList(),
      );

  Widget _buildDropdown(String title, String? value, List<String> items, ValueChanged<String?> onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(title),
            _dropdownField(value, items, 'Select $title', onChanged),
          ],
        ),
      );
}
