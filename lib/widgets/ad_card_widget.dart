import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class AdCardWidget extends StatefulWidget {
  final Map<String, dynamic> ad;

  const AdCardWidget({super.key, required this.ad});

  @override
  State<AdCardWidget> createState() => _AdCardWidgetState();
}

class _AdCardWidgetState extends State<AdCardWidget> {
  bool _dismissed = false;
  bool _impressionTracked = false;

  static const _kPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _trackImpression();
  }

  Future<void> _trackImpression() async {
    if (_impressionTracked) return;
    _impressionTracked = true;
    final id = int.tryParse(widget.ad['id']?.toString() ?? '0') ?? 0;
    if (id > 0) ApiService.trackAdImpression(id);
  }

  Future<void> _onTapLearnMore() async {
    final id = int.tryParse(widget.ad['id']?.toString() ?? '0') ?? 0;
    if (id > 0) ApiService.trackAdClick(id);
    final url = widget.ad['click_url']?.toString() ?? '';
    if (url.isNotEmpty) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  Future<void> _onCall() async {
    final id = int.tryParse(widget.ad['id']?.toString() ?? '0') ?? 0;
    if (id > 0) ApiService.trackAdClick(id);
    final phone = widget.ad['phone']?.toString() ?? '';
    if (phone.isNotEmpty) {
      try {
        await launchUrl(Uri.parse('tel:$phone'));
      } catch (_) {}
    }
  }

  Future<void> _onWhatsApp() async {
    final id = int.tryParse(widget.ad['id']?.toString() ?? '0') ?? 0;
    if (id > 0) ApiService.trackAdClick(id);
    final phone = widget.ad['phone']?.toString() ?? '';
    if (phone.isNotEmpty) {
      // Remove non-digits, add country code if needed
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final wa = digits.length == 10 ? '91$digits' : digits;
      final title = Uri.encodeComponent(widget.ad['title']?.toString() ?? 'Ad');
      try {
        await launchUrl(
          Uri.parse('https://wa.me/$wa?text=Hi, I saw your ad "$title" on Wedding India app'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dismissed — hide completely
    if (_dismissed) return const SizedBox.shrink();

    final mediaType   = widget.ad['media_type']?.toString() ?? 'image';
    final mediaUrl    = widget.ad['media_url']?.toString() ?? '';
    final title       = widget.ad['title']?.toString() ?? '';
    final advertiser  = widget.ad['advertiser']?.toString() ?? '';
    final description = widget.ad['description']?.toString() ?? '';
    final phone       = widget.ad['phone']?.toString() ?? '';
    final hasClickUrl = (widget.ad['click_url']?.toString() ?? '').isNotEmpty;
    final hasPhone    = phone.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPink.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Sponsored header bar ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: const Color(0xFFFCE4EC),
            child: Row(
              children: [
                const Icon(Icons.campaign_outlined, size: 14, color: _kPink),
                const SizedBox(width: 4),
                const Text('Sponsored',
                    style: TextStyle(fontSize: 11, color: _kPink, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (advertiser.isNotEmpty)
                  Text(advertiser,
                      style: const TextStyle(fontSize: 11, color: _kPink, fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                // Close / dismiss button
                GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _kPink.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 13, color: _kPink),
                  ),
                ),
              ],
            ),
          ),

          // ── Media ───────────────────────────────────────────────
          if (mediaUrl.isNotEmpty)
            GestureDetector(
              onTap: hasClickUrl ? _onTapLearnMore : null,
              child: mediaType == 'video'
                  ? _VideoThumb(url: mediaUrl)
                  : Image.network(
                      mediaUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        color: const Color(0xFFF5F5F5),
                        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                      ),
                    ),
            ),

          // ── Text content ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),

          // ── Action buttons ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            child: Row(
              children: [
                // Call button
                if (hasPhone) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: _onCall,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call, size: 15, color: Colors.green.shade700),
                            const SizedBox(width: 5),
                            Text('Call', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // WhatsApp button
                  Expanded(
                    child: GestureDetector(
                      onTap: _onWhatsApp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 15, color: Color(0xFF25D366)),
                            SizedBox(width: 5),
                            Text('WhatsApp', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (hasClickUrl) const SizedBox(width: 8),
                ],
                // Learn More button
                if (hasClickUrl)
                  Expanded(
                    child: GestureDetector(
                      onTap: _onTapLearnMore,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _kPink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Learn More',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 13, color: Colors.white),
                          ],
                        ),
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

class _VideoThumb extends StatelessWidget {
  final String url;
  const _VideoThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (_) {}
      },
      child: Container(
        height: 180,
        width: double.infinity,
        color: const Color(0xFF1A1A2E),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
            SizedBox(height: 8),
            Text('Tap to play video',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
