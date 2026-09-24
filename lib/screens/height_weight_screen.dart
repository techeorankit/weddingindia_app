import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'mother_tongue_screen.dart';

class HabitsDetailsScreen extends StatefulWidget {
  const HabitsDetailsScreen({super.key});

  @override
  State<HabitsDetailsScreen> createState() => _HabitsDetailsScreenState();
}

class _HabitsDetailsScreenState extends State<HabitsDetailsScreen> {
  String? height;
  String? weight;
  String? eatingHabit;
  String? smokingHabit;
  String? drinkingHabit;
  String? disability;
  String? maritalStatus;
  String? bodyType;
  String? complexion;
  String? bloodGroup;
  bool _isLoading = false;

  // Height name → DB id (database.sql heights table)
  static const Map<String, int> _heightIds = {
    "4'6\"": 1,  "4'7\"": 2,  "4'8\"": 3,  "4'9\"": 4,
    "4'10\"": 5, "4'11\"": 6, "5'0\"": 7,  "5'1\"": 8,
    "5'2\"": 9,  "5'3\"": 10, "5'4\"": 11, "5'5\"": 12,
    "5'6\"": 13, "5'7\"": 14, "5'8\"": 15, "5'9\"": 16,
    "5'10\"": 17,"5'11\"": 18,"6'0\"": 19, "6'1\"": 20,
    "6'2\"": 21, "6'3\"": 22, "6'4\"": 23,
  };

  static const Map<String, int> _eatingIds    = {'Vegetarian': 1, 'Non-Vegetarian': 2, 'Eggetarian': 3, 'Vegan': 4};
  static const Map<String, int> _smokingIds   = {'No': 1, 'Occasionally': 2, 'Yes': 3};
  static const Map<String, int> _drinkingIds  = {'No': 1, 'Occasionally': 2, 'Yes': 3};
  static const Map<String, int> _disabilityIds= {'None': 1, 'Physically Challenged': 2, 'Visually Impaired': 3, 'Hearing Impaired': 4, 'Other': 5};
  static const Map<String, int> _maritalIds   = {'Never Married': 1, 'Divorced': 2, 'Widowed': 3, 'Awaiting Divorce': 4};
  static const Map<String, int> _bodyTypeIds  = {'Slim': 1, 'Average': 2, 'Athletic': 3, 'Heavy': 4};
  static const Map<String, int> _complexionIds= {'Very Fair': 1, 'Fair': 2, 'Wheatish': 3, 'Dark': 4};
  static const Map<String, int> _bloodGroupIds= {'A+': 1, 'A-': 2, 'B+': 3, 'B-': 4, 'AB+': 5, 'AB-': 6, 'O+': 7, 'O-': 8};

  final List<String> heights     = ["4'6\"","4'7\"","4'8\"","4'9\"","4'10\"","4'11\"","5'0\"","5'1\"","5'2\"","5'3\"","5'4\"","5'5\"","5'6\"","5'7\"","5'8\"","5'9\"","5'10\"","5'11\"","6'0\"","6'1\"","6'2\"","6'3\"","6'4\""];
  final List<String> weights     = List.generate(81, (i) => "${i + 40} kg");
  final List<String> eatingHabits   = ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Vegan'];
  final List<String> smokingHabits  = ['No', 'Occasionally', 'Yes'];
  final List<String> drinkingHabits = ['No', 'Occasionally', 'Yes'];
  final List<String> disabilities   = ['None', 'Physically Challenged', 'Visually Impaired', 'Hearing Impaired', 'Other'];
  final List<String> maritalStatuses= ['Never Married', 'Divorced', 'Widowed', 'Awaiting Divorce'];
  final List<String> bodyTypes      = ['Slim', 'Average', 'Athletic', 'Heavy'];
  final List<String> complexions    = ['Very Fair', 'Fair', 'Wheatish', 'Dark'];
  final List<String> bloodGroups    = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  bool get isValid =>
      height != null && weight != null && eatingHabit != null &&
      smokingHabit != null && drinkingHabit != null && disability != null &&
      maritalStatus != null && bodyType != null && complexion != null &&
      bloodGroup != null;

  Future<void> _continue() async {
    if (!isValid) return;
    setState(() => _isLoading = true);

    final result = await ApiService.saveHabits(
      heightId:        _heightIds[height!],
      weight:          weight,
      eatingHabitId:   _eatingIds[eatingHabit!],
      smokingHabitId:  _smokingIds[smokingHabit!],
      drinkingHabitId: _drinkingIds[drinkingHabit!],
      disabilityId:    _disabilityIds[disability!],
      maritalStatusId: _maritalIds[maritalStatus!],
      bodyTypeId:      _bodyTypeIds[bodyType!],
      complexionId:    _complexionIds[complexion!],
      bloodGroupId:    _bloodGroupIds[bloodGroup!],
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['status'] == true) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MotherTongueScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Something went wrong'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Habits & Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const Text('Lifestyle & Personal Details',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  _buildDropdown(title: 'Height',        value: height,        items: heights,        icon: Icons.height,                    onChanged: (v) => setState(() => height = v)),
                  _buildDropdown(title: 'Weight',        value: weight,        items: weights,        icon: Icons.monitor_weight_outlined,   onChanged: (v) => setState(() => weight = v)),
                  _buildDropdown(title: 'Eating Habit',  value: eatingHabit,   items: eatingHabits,   icon: Icons.restaurant,                onChanged: (v) => setState(() => eatingHabit = v)),
                  _buildDropdown(title: 'Smoking Habit', value: smokingHabit,  items: smokingHabits,  icon: Icons.smoking_rooms,             onChanged: (v) => setState(() => smokingHabit = v)),
                  _buildDropdown(title: 'Drinking Habit',value: drinkingHabit, items: drinkingHabits, icon: Icons.local_bar,                 onChanged: (v) => setState(() => drinkingHabit = v)),
                  _buildDropdown(title: 'Disability',    value: disability,    items: disabilities,   icon: Icons.accessible,                onChanged: (v) => setState(() => disability = v)),
                  _buildDropdown(title: 'Marital Status',value: maritalStatus, items: maritalStatuses,icon: Icons.favorite,                  onChanged: (v) => setState(() => maritalStatus = v)),
                  _buildDropdown(title: 'Body Type',     value: bodyType,      items: bodyTypes,      icon: Icons.person,                    onChanged: (v) => setState(() => bodyType = v)),
                  _buildDropdown(title: 'Complexion',    value: complexion,    items: complexions,    icon: Icons.face,                      onChanged: (v) => setState(() => complexion = v)),
                  _buildDropdown(title: 'Blood Group',   value: bloodGroup,    items: bloodGroups,    icon: Icons.bloodtype,                 onChanged: (v) => setState(() => bloodGroup = v)),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (isValid && !_isLoading) ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String title, required String? value,
    required List<String> items, required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFE91E63)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      hint: Text('Select $title'),
                      isExpanded: true,
                      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
