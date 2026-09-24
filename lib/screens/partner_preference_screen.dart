import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_success_screen.dart';

class PartnerPreferenceScreen extends StatefulWidget {
  const PartnerPreferenceScreen({super.key});

  @override
  State<PartnerPreferenceScreen> createState() =>
      _PartnerPreferenceScreenState();
}

class _PartnerPreferenceScreenState extends State<PartnerPreferenceScreen> {
  RangeValues _ageRange = const RangeValues(22, 35);
  String? _religion;
  String? _minHeight;
  String? _maxHeight;
  String? _income;
  bool _isLoading = false;

  static const Map<String, int> _religionIds = {
    'Any': 0, 'Hindu': 1, 'Muslim': 2, 'Christian': 3,
    'Sikh': 4, 'Jain': 5, 'Buddhist': 6, 'Other': 7,
  };
  static const Map<String, int> _incomeIds = {
    'Any': 0,               'No Income': 1,         'Below 1 Lakh': 2,
    '1-2 Lakh': 3,          '2-5 Lakh': 4,          '5-10 Lakh': 5,
    '10-20 Lakh': 6,        '20-50 Lakh': 7,        '50 Lakh - 1 Crore': 8,
    '1-2 Crore': 9,         '2-3 Crore': 10,        '3-4 Crore': 11,
    '4-5 Crore': 12,        '5+ Crore': 13,
  };
  static const Map<String, int> _heightIds = {
    "4'6\"": 1, "4'8\"": 3, "4'10\"": 5, "5'0\"": 7,
    "5'2\"": 9, "5'4\"": 11,"5'6\"": 13, "5'8\"": 15,
    "5'10\"":17,"6'0\"": 19,"6'2\"": 21, "6'4\"": 23,
  };

  Future<void> _save() async {
    setState(() => _isLoading = true);

    await ApiService.savePartnerPreference(
      ageMin:      _ageRange.start.round(),
      ageMax:      _ageRange.end.round(),
      religionId:  (_religion != null && _religionIds[_religion!] != 0)
                       ? _religionIds[_religion!] : null,
      minHeightId: _minHeight != null ? _heightIds[_minHeight!] : null,
      maxHeightId: _maxHeight != null ? _heightIds[_maxHeight!] : null,
      incomeId:    (_income != null && _incomeIds[_income!] != 0)
                       ? _incomeIds[_income!] : null,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegisterSuccessScreen()),
      (route) => false,
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
        title: const Text('Partner Preference',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Partner Preference',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Tell us what you are looking for',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 28),

            // Age range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Age Range',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_ageRange.start.round()} - ${_ageRange.end.round()} yrs',
                    style: const TextStyle(
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _ageRange,
              min: 18, max: 60, divisions: 42,
              activeColor: const Color(0xFFE91E63),
              inactiveColor: Colors.grey.shade200,
              onChanged: (v) => setState(() => _ageRange = v),
            ),
            const SizedBox(height: 20),

            // Religion
            const Text('Religion',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _religionIds.keys.map((r) {
                final isSelected = _religion == r;
                return GestureDetector(
                  onTap: () => setState(() => _religion = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFE4EF)
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE91E63)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(r,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFE91E63)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Height range
            const Text('Height Range',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dropdownField(
                      value: _minHeight,
                      hint: 'Min Height',
                      items: _heightIds.keys.toList(),
                      onChanged: (v) => setState(() => _minHeight = v)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  child: _dropdownField(
                      value: _maxHeight,
                      hint: 'Max Height',
                      items: _heightIds.keys.toList(),
                      onChanged: (v) => setState(() => _maxHeight = v)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Income
            const Text('Annual Income',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            _dropdownField(
                value: _income,
                hint: 'Select preferred income',
                items: _incomeIds.keys.toList(),
                onChanged: (v) => setState(() => _income = v)),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterSuccessScreen()),
                      (route) => false,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE91E63)),
                      foregroundColor: const Color(0xFFE91E63),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Skip',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Complete',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          isExpanded: true,
          items:
              items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
