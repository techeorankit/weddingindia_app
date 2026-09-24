import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'basic_details_screen.dart';

class ProfileForScreen extends StatefulWidget {
  const ProfileForScreen({super.key});

  @override
  State<ProfileForScreen> createState() => _ProfileForScreenState();
}

class _ProfileForScreenState extends State<ProfileForScreen> {
  String? _selected;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _options = [
    {'label': 'Myself',   'icon': Icons.person},
    {'label': 'Son',      'icon': Icons.boy},
    {'label': 'Daughter', 'icon': Icons.girl},
    {'label': 'Brother',  'icon': Icons.people},
    {'label': 'Sister',   'icon': Icons.people_outline},
    {'label': 'Friend',   'icon': Icons.group},
  ];

  Future<void> _continue() async {
    if (_selected == null) return;
    setState(() => _isLoading = true);

    final result = await ApiService.saveProfileFor(_selected!);

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['status'] == true) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const BasicDetailsScreen()));
    } else {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${result['message']}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
    }
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
        title: const Text('Profile For',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This profile is for',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Select who you are creating this profile for',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: _options.length,
                itemBuilder: (context, i) {
                  final opt = _options[i];
                  final isSelected = _selected == opt['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = opt['label']),
                    child: Container(
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(opt['icon'],
                              color: isSelected
                                  ? const Color(0xFFE91E63)
                                  : Colors.grey,
                              size: 32),
                          const SizedBox(height: 8),
                          Text(opt['label'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFE91E63)
                                    : Colors.black87,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_selected == null || _isLoading) ? null : _continue,
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
}
