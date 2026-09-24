import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'marital_status_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  String? _education;
  String? _income;
  final _professionController = TextEditingController();
  bool _isLoading = false;

  // Education name → DB id
  static const Map<String, int> _educationIds = {
    'Below 10th': 1, '10th Pass': 2, '12th Pass': 3, 'Diploma': 4,
    'Graduate': 5,   'Post Graduate': 6, 'Doctorate': 7, 'Other': 8,
  };

  // Income name → DB id
  static const Map<String, int> _incomeIds = {
    'No Income': 1,         'Below 1 Lakh': 2,        '1-2 Lakh': 3,
    '2-5 Lakh': 4,          '5-10 Lakh': 5,           '10-20 Lakh': 6,
    '20-50 Lakh': 7,        '50 Lakh - 1 Crore': 8,   '1-2 Crore': 9,
    '2-3 Crore': 10,        '3-4 Crore': 11,           '4-5 Crore': 12,
    '5+ Crore': 13,
  };

  Future<void> _continue() async {
    if (_education == null) return;
    setState(() => _isLoading = true);

    final result = await ApiService.saveEducation(
      educationId: _educationIds[_education!]!,
      profession: _professionController.text.trim(),
      incomeId: _income != null ? _incomeIds[_income!] : null,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['status'] == true) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MaritalStatusScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Something went wrong'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _professionController.dispose();
    super.dispose();
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
        title: const Text('Education & Career',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgress(4, 4),
            const SizedBox(height: 24),
            const Text('Education & Career',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Step 4 of 4',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 28),

            const Text('Highest Education',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _educationIds.keys.map((e) {
                final isSelected = _education == e;
                return GestureDetector(
                  onTap: () => setState(() => _education = e),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
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
                    child: Text(e,
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
            const SizedBox(height: 24),

            const Text('Profession',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _professionController,
              decoration: InputDecoration(
                hintText: 'e.g. Software Engineer, Doctor, Teacher',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE91E63))),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Annual Income',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _income,
                  hint: const Text('Select Annual Income'),
                  isExpanded: true,
                  items: _incomeIds.keys
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  onChanged: (val) => setState(() => _income = val),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_education != null && !_isLoading) ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Continue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(int current, int total) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i < current
                  ? const Color(0xFFE91E63)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
