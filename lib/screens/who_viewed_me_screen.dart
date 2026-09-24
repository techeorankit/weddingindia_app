import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'upgrade_screen.dart';

class WhoViewedMeScreen extends StatefulWidget {
  const WhoViewedMeScreen({super.key});

  @override
  State<WhoViewedMeScreen> createState() => _WhoViewedMeScreenState();
}

class _WhoViewedMeScreenState extends State<WhoViewedMeScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _viewers = [];
  int _totalViews = 0;
  bool _isPremium = false;
  String? _error;

  static const _kPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getProfileViewers();
    if (!mounted) return;
    if (res['status'] == true) {
      final d = res['data'];
      setState(() {
        _viewers    = List<Map<String, dynamic>>.from(d['viewers'] ?? []);
        _totalViews = int.tryParse(d['total_views']?.toString() ?? '0') ?? 0;
        _isPremium  = d['is_premium'] == true;
        _loading    = false;
      });
    } else {
      setState(() { _error = res['message']?.toString(); _loading = false; });
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt   = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      if (diff.inDays < 7)     return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: _kPink,
        foregroundColor: Colors.white,
        title: const Text('Who Viewed Me', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPink))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    // Stats banner
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE4EC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.visibility, color: _kPink, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_totalViews',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                              const Text('Total profile views',
                                  style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                          const Spacer(),
                          if (!_isPremium)
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const UpgradeScreen())),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [_kPink, Color(0xFFAD1457)]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_open, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('Unlock', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (!_isPremium)
                      Container(
                        color: const Color(0xFFFFF8E1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Upgrade to Premium to see full profiles of viewers',
                                  style: TextStyle(fontSize: 12, color: Colors.orange)),
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: _viewers.isEmpty
                          ? _buildEmpty()
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _viewers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _buildViewerCard(_viewers[i]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildViewerCard(Map<String, dynamic> v) {
    final name       = v['full_name']?.toString() ?? 'Someone';
    final photoUrl   = v['profile_photo_url']?.toString() ?? '';
    final age        = v['age']?.toString() ?? '';
    final religion   = v['religion']?.toString() ?? '';
    final city       = v['city']?.toString() ?? '';
    final lastViewed = _timeAgo(v['last_viewed']?.toString());
    final isBlurred  = v['is_blurred'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Photo
          Stack(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF5F5F5)),
                child: ClipOval(
                  child: photoUrl.isNotEmpty && !isBlurred
                      ? Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey))
                      : isBlurred
                          ? Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.person, color: Colors.grey, size: 32))
                          : const Icon(Icons.person, color: Colors.grey, size: 32),
                ),
              ),
              if (isBlurred)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    child: const Icon(Icons.lock, color: _kPink, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isBlurred ? Colors.grey : const Color(0xFF1A1A2E),
                    )),
                const SizedBox(height: 3),
                if (age.isNotEmpty || religion.isNotEmpty || city.isNotEmpty)
                  Text(
                    [if (age.isNotEmpty) '$age yrs', if (religion.isNotEmpty) religion, if (city.isNotEmpty) city]
                        .join(' · '),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(lastViewed, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              const SizedBox(height: 6),
              if (!isBlurred)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('View Profile',
                      style: TextStyle(fontSize: 10, color: _kPink, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility_off, size: 64, color: Colors.grey.shade200),
        const SizedBox(height: 16),
        Text('No views yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
        const SizedBox(height: 8),
        Text('Complete your profile to get more views!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ],
    ),
  );
}
