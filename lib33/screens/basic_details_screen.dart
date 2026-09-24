import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'religion_screen.dart';

class BasicDetailsScreen extends StatefulWidget {
  const BasicDetailsScreen({super.key});

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final _nameController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(2005),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String get _dobText => _dob == null
      ? 'Select Date of Birth'
      : '${_dob!.day}/${_dob!.month}/${_dob!.year}';

  // YYYY-MM-DD format for API
  String get _dobForApi => _dob == null
      ? ''
      : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}';

  bool get _isValid =>
      _nameController.text.isNotEmpty && _dob != null && _gender != null;

  Future<void> _continue() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);

    final result = await ApiService.saveBasicDetails(
      fullName: _nameController.text.trim(),
      dob: _dobForApi,
      gender: _gender!,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['status'] == true) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ReligionScreen()));
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
    _nameController.dispose();
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
        title: const Text('Basic Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgress(1, 4),
            const SizedBox(height: 24),
            const Text('Tell us about yourself',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Step 1 of 4',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 28),

            _label('Full Name'),
            const SizedBox(height: 8),
            _textField(_nameController, 'Enter your full name', TextInputType.name),
            const SizedBox(height: 20),

            _label('Date of Birth'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dobText,
                        style: TextStyle(
                          color: _dob == null ? Colors.grey : Colors.black,
                          fontSize: 16,
                        )),
                    const Icon(Icons.calendar_today,
                        color: Color(0xFFE91E63), size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _label('Gender'),
            const SizedBox(height: 8),
            Row(
              children: ['Male', 'Female', 'Other'].map((g) {
                final isSelected = _gender == g;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = g),
                      child: Container(
                        height: 48,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(g,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFE91E63)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isValid && !_isLoading) ? _continue : null,
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

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));

  Widget _textField(TextEditingController c, String hint, TextInputType type) =>
      TextField(
        controller: c,
        keyboardType: type,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE91E63))),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );

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
