import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'upload_photo_screen.dart';

class AboutMeScreen extends StatefulWidget {
  const AboutMeScreen({super.key});

  @override
  State<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen> {
  final _bioController = TextEditingController();
  int _charCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(
        () => setState(() => _charCount = _bioController.text.length));
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await ApiService.saveAboutMe(_bioController.text.trim());
    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const UploadPhotoScreen()));
  }

  @override
  void dispose() {
    _bioController.dispose();
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
        title: const Text('About Me',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('About Me',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Write a short bio to introduce yourself',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 28),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4EF).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Color(0xFFE91E63), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A good bio increases your chances of finding a match!',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _bioController,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Tell something about yourself, your family, hobbies...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE91E63))),
                contentPadding: const EdgeInsets.all(16),
                counterText: '$_charCount/500',
              ),
            ),
            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UploadPhotoScreen())),
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
                    onPressed: (_charCount >= 20 && !_isLoading) ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Continue',
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
}
