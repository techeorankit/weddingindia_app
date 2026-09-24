import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'about_me_screen.dart';

class MotherTongueScreen extends StatefulWidget {
  const MotherTongueScreen({super.key});

  @override
  State<MotherTongueScreen> createState() => _MotherTongueScreenState();
}

class _MotherTongueScreenState extends State<MotherTongueScreen> {
  String? _selected;
  bool _isLoading = false;

  // Language name → DB id (database.sql mother_tongues table)
  static const Map<String, int> _languageIds = {
    'Hindi': 1, 'Marathi': 2, 'Gujarati': 3, 'Bengali': 4,
    'Tamil': 5, 'Telugu': 6,  'Kannada': 7,  'Malayalam': 8,
    'Punjabi': 9,'Odia': 10,  'Urdu': 11,    'Assamese': 12,
    'Maithili': 13,'Sanskrit': 14,'English': 15,'Other': 16,
  };

  Future<void> _continue() async {
    if (_selected == null) return;
    setState(() => _isLoading = true);

    // Mother tongue ko religion table mein update karo
    final result = await ApiService.saveReligion(
      religionId: 0,          // 0 means "don't update religion"
      motherTongueId: _languageIds[_selected!],
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    // API fail bhi ho to next screen pe jao (religion already saved hai)
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AboutMeScreen()));
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
        title: const Text('Mother Tongue',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mother Tongue',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Select your mother tongue / language',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: _languageIds.length,
                itemBuilder: (context, i) {
                  final lang = _languageIds.keys.elementAt(i);
                  final isSelected = _selected == lang;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = lang),
                    child: Container(
                      alignment: Alignment.center,
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(lang,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFE91E63)
                                : Colors.black87,
                          )),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
