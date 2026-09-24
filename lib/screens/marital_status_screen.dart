import 'package:flutter/material.dart';
import 'height_weight_screen.dart';

class MaritalStatusScreen extends StatefulWidget {
  const MaritalStatusScreen({super.key});

  @override
  State<MaritalStatusScreen> createState() => _MaritalStatusScreenState();
}

class _MaritalStatusScreenState extends State<MaritalStatusScreen> {
  String? _selected;

  final List<Map<String, dynamic>> _options = [
    {'label': 'Never Married', 'icon': Icons.favorite_border},
    {'label': 'Divorced', 'icon': Icons.heart_broken_outlined},
    {'label': 'Widowed', 'icon': Icons.person_outline},
    {'label': 'Awaiting Divorce', 'icon': Icons.hourglass_empty},
  ];

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
        title: const Text('Marital Status', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marital Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Select your current marital status', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 28),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: _options.length,
                itemBuilder: (context, i) {
                  final opt = _options[i];
                  final isSelected = _selected == opt['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = opt['label']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFE4EF) : Colors.grey.shade50,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFE91E63) : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(opt['icon'],
                              color: isSelected ? const Color(0xFFE91E63) : Colors.grey[600], size: 36),
                          const SizedBox(height: 10),
                          Text(
                            opt['label'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? const Color(0xFFE91E63) : Colors.black87,
                            ),
                          ),
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
                onPressed: _selected == null
                    ? null
                    : () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HabitsDetailsScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
