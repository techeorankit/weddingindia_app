import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppFAB extends StatelessWidget {
  final String whatsappNumber;
  final String message;

  const WhatsAppFAB({
    super.key,
    required this.whatsappNumber,
    required this.message,
  });

  Future<void> _openWhatsApp(BuildContext context) async {
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$whatsappNumber?text=$encoded';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openWhatsApp(context),
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.chat, size: 20),
      label: const Text('Chat Support', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
