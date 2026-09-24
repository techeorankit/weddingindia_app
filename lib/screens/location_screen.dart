import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'education_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _state;
  final _cityController = TextEditingController();
  bool _isLoading = false;

  // State name → DB id mapping (database.sql ke according)
  static const Map<String, int> _stateIds = {
    'Maharashtra': 14,   'Delhi': 29,        'Gujarat': 7,
    'Rajasthan': 21,     'Uttar Pradesh': 26,'Karnataka': 11,
    'Tamil Nadu': 23,    'West Bengal': 28,  'Punjab': 20,
    'Madhya Pradesh': 13,'Bihar': 4,         'Haryana': 8,
    'Andhra Pradesh': 1, 'Telangana': 24,    'Kerala': 12,
    'Other': 30,
  };

  Future<void> _continue() async {
    if (_state == null || _cityController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final result = await ApiService.saveLocation(
      stateId: _stateIds[_state!]!,
      city: _cityController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['status'] == true) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EducationScreen()));
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
    _cityController.dispose();
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
        title: const Text('Location',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgress(3, 4),
            const SizedBox(height: 24),
            const Text('Your Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Step 3 of 4',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 28),

            const Text('State',
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
                  value: _state,
                  hint: const Text('Select State'),
                  isExpanded: true,
                  items: _stateIds.keys
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _state = val),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('City',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter your city',
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: Color(0xFFE91E63)),
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
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_state != null &&
                        _cityController.text.isNotEmpty &&
                        !_isLoading)
                    ? _continue
                    : null,
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
