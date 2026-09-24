import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../widgets/photo_gallery_widget.dart';
import 'messenger_screen.dart';
import 'upgrade_screen.dart';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final bool hasActivePackage;
  final int myUserId;
  final String myName;
  final Set<String> activeActions;
  final Future<bool> Function(int userId, String type) onAction;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    required this.hasActivePackage,
    required this.myUserId,
    required this.myName,
    required this.activeActions,
    required this.onAction,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late Set<String> _active;
  bool _loadingFull = false;
  Map<String, dynamic>? _fullProfile;

  // Phone reveal
  String? _revealedPhone;
  bool _loadingPhone = false;

  @override
  void initState() {
    super.initState();
    _active = Set.from(widget.activeActions);
    _loadFullProfile();
  }

  Future<void> _loadFullProfile() async {
    setState(() => _loadingFull = true);
    final userId = _userId;
    final res = await ApiService.viewProfile(userId);
    if (mounted && res['status'] == true) {
      setState(() {
        _fullProfile = res['data'];
        _loadingFull = false;
      });
    } else {
      setState(() => _loadingFull = false);
    }
  }

  int get _userId {
    final p = widget.profile;
    return p['user_id'] is int ? p['user_id'] as int : int.tryParse(p['user_id'].toString()) ?? 0;
  }

  Future<void> _revealPhone() async {
    if (_loadingPhone) return;
    setState(() => _loadingPhone = true);
    final res = await ApiService.getPhone(_userId);
    if (!mounted) return;
    setState(() => _loadingPhone = false);
    if (res['status'] == true) {
      setState(() => _revealedPhone = res['data']['full_phone']?.toString() ?? res['data']['phone']?.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Could not fetch phone number'),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _startVoiceCall() {
    if (!widget.hasActivePackage) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
      return;
    }
    final p = _fullProfile ?? widget.profile;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VoiceCallScreen(
        remoteUserId: _userId,
        remoteName: p['full_name']?.toString() ?? widget.profile['full_name']?.toString() ?? 'User',
        remotePhoto: p['profile_photo_url']?.toString(),
        myUserId: widget.myUserId,
      ),
    ));
  }

  void _startVideoCall() {
    if (!widget.hasActivePackage) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
      return;
    }
    final p = _fullProfile ?? widget.profile;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VideoCallScreen(
        remoteUserId: _userId,
        remoteName: p['full_name']?.toString() ?? widget.profile['full_name']?.toString() ?? 'User',
        remotePhoto: p['profile_photo_url']?.toString(),
        myUserId: widget.myUserId,
      ),
    ));
  }

  Future<void> _doAction(String type) async {
    final success = await widget.onAction(_userId, type);
    if (success && mounted) {
      setState(() {
        if (_active.contains(type)) {
          _active.remove(type);
        } else {
          _active.add(type);
        }
      });
      if (type == 'chat' && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            name: widget.profile['full_name']?.toString() ?? '',
            userId: _userId,
            myUserId: widget.myUserId,
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _fullProfile ?? widget.profile;
    final photoUrl = p['profile_photo_url']?.toString() ?? '';
    final name = p['full_name']?.toString() ?? 'N/A';
    final age = p['age']?.toString() ?? '';
    final height = p['height']?.toString() ?? '';
    final city = p['city']?.toString() ?? '';
    final state = p['state']?.toString() ?? '';
    final religion = p['religion']?.toString() ?? '';
    final caste = p['caste']?.toString() ?? '';
    final profession = p['profession']?.toString() ?? '';
    final education = p['education']?.toString() ?? '';
    final income = p['income']?.toString() ?? '';
    final maritalStatus = p['marital_status']?.toString() ?? '';
    final motherTongue = p['mother_tongue']?.toString() ?? '';
    final bio = p['bio']?.toString() ?? '';
    final gender = p['gender']?.toString() ?? '';
    final profileFor = p['profile_for']?.toString() ?? '';
    final bodyType = p['body_type']?.toString() ?? '';
    final complexion = p['complexion']?.toString() ?? '';
    final bloodGroup = p['blood_group']?.toString() ?? '';
    final eatingHabit = p['eating_habit']?.toString() ?? '';
    final weight = p['weight']?.toString() ?? '';
    final isVerified = p['is_profile_complete']?.toString() == '1';
    // Family
    final motherOccupation = p['mother_occupation']?.toString() ?? '';
    final fatherOccupation = p['father_occupation']?.toString() ?? '';
    final brothers = p['brothers']?.toString() ?? '';
    final sisters  = p['sisters']?.toString() ?? '';
    // Match score
    final matchScore = int.tryParse(widget.profile['match_score']?.toString() ?? '0') ?? 0;
    final matchLabel = widget.profile['match_label']?.toString() ?? '';
    // Photos
    final rawPhotos = p['photos'];
    final List<Map<String, dynamic>> photos = rawPhotos is List
        ? rawPhotos.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : (p['profile_photo_url']?.toString().isNotEmpty == true
            ? [{'id': 0, 'url': p['profile_photo_url'], 'is_primary': true}]
            : []);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: CustomScrollView(
        slivers: [
          // ── Photo + AppBar ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(gender),
                        )
                      : _photoPlaceholder(gender),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                  // Name + badges
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$name, $age',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Color(0xFF4FC3F7), size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (city.isNotEmpty || state.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white70, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                [city, state].where((s) => s.isNotEmpty).join(', '),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (religion.isNotEmpty) _tag(religion),
                            if (maritalStatus.isNotEmpty) _tag(maritalStatus),
                            if (profileFor.isNotEmpty) _tag('For $profileFor'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Match Score Banner ─────────────────────────────
                if (matchScore > 0)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        // Score circle
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: matchScore >= 80
                                ? Colors.green.shade50
                                : matchScore >= 60
                                    ? Colors.orange.shade50
                                    : const Color(0xFFFCE4EC),
                            border: Border.all(
                              color: matchScore >= 80
                                  ? Colors.green
                                  : matchScore >= 60
                                      ? Colors.orange
                                      : const Color(0xFFE91E63),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text('$matchScore%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: matchScore >= 80
                                      ? Colors.green.shade700
                                      : matchScore >= 60
                                          ? Colors.orange.shade700
                                          : const Color(0xFFE91E63),
                                )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(matchLabel.isNotEmpty ? matchLabel : 'Match Score',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Based on your partner preferences',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                        const Spacer(),
                        // Progress bar
                        SizedBox(
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: matchScore / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                matchScore >= 80 ? Colors.green : matchScore >= 60 ? Colors.orange : const Color(0xFFE91E63),
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Action Buttons ─────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        icon: Icons.favorite,
                        label: 'Interest',
                        active: _active.contains('interest'),
                        activeColor: const Color(0xFFE91E63),
                        onTap: () => _doAction('interest'),
                      ),
                      _actionButton(
                        icon: Icons.star,
                        label: 'Shortlist',
                        active: _active.contains('shortlist'),
                        activeColor: Colors.amber,
                        onTap: () => _doAction('shortlist'),
                      ),
                      _actionButton(
                        icon: Icons.chat_bubble,
                        label: 'Chat',
                        active: _active.contains('chat'),
                        activeColor: Colors.green,
                        onTap: () => _doAction('chat'),
                      ),
                      _actionButton(
                        icon: Icons.block,
                        label: 'Ignore',
                        active: _active.contains('ignore'),
                        activeColor: Colors.red,
                        onTap: () => _doAction('ignore'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Call Buttons ───────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.call, color: Color(0xFFE91E63), size: 16),
                            SizedBox(width: 6),
                            Text('Connect', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _callBtn(
                                icon: Icons.call,
                                label: 'Voice Call',
                                color: const Color(0xFF4CAF50),
                                locked: !widget.hasActivePackage,
                                onTap: () => _startVoiceCall(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _callBtn(
                                icon: Icons.videocam,
                                label: 'Video Call',
                                color: const Color(0xFF1976D2),
                                locked: !widget.hasActivePackage,
                                onTap: () => _startVideoCall(),
                              ),
                            ),
                          ],
                        ),
                        if (!widget.hasActivePackage) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFAD1457)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_open, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Upgrade to unlock calling', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── About Me ───────────────────────────────────────
                if (bio.isNotEmpty) ...[
                  _sectionCard(
                    title: 'About',
                    icon: Icons.person_outline,
                    child: Text(
                      bio,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Basic Details ──────────────────────────────────
                _sectionCard(
                  title: 'Basic Details',
                  icon: Icons.info_outline,
                  child: Column(
                    children: [
                      _detailRow('Age', '$age years'),
                      _detailRow('Height', height),
                      _detailRow('Weight', weight),
                      _detailRow('Body Type', bodyType),
                      _detailRow('Complexion', complexion),
                      _detailRow('Blood Group', bloodGroup),
                      _detailRow('Marital Status', maritalStatus),
                      _detailRow('Eating Habit', eatingHabit),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Religion ──────────────────────────────────────
                _sectionCard(
                  title: 'Religion',
                  icon: Icons.temple_hindu_outlined,
                  child: Column(
                    children: [
                      _detailRow('Religion', religion),
                      _detailRow('Caste', caste),
                      _detailRow('Mother Tongue', motherTongue),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Career ────────────────────────────────────────
                _sectionCard(
                  title: 'Career & Education',
                  icon: Icons.school_outlined,
                  child: Column(
                    children: [
                      _detailRow('Education', education),
                      _detailRow('Profession', profession),
                      _detailRow('Annual Income', income),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Location ──────────────────────────────────────
                _sectionCard(
                  title: 'Location',
                  icon: Icons.location_on_outlined,
                  child: Column(
                    children: [
                      _detailRow('City', city),
                      _detailRow('State', state),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Family Details ─────────────────────────────────
                if (motherOccupation.isNotEmpty || fatherOccupation.isNotEmpty ||
                    brothers.isNotEmpty || sisters.isNotEmpty)
                  _sectionCard(
                    title: 'Family Details',
                    icon: Icons.family_restroom,
                    child: Column(
                      children: [
                        _detailRow('Mother\'s Occupation', motherOccupation),
                        _detailRow('Father\'s Occupation', fatherOccupation),
                        _detailRow('Brothers', brothers.isNotEmpty ? brothers : ''),
                        _detailRow('Sisters', sisters.isNotEmpty ? sisters : ''),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Phone Number Reveal (Premium) ──────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone, color: Color(0xFFE91E63), size: 16),
                            SizedBox(width: 6),
                            Text('Contact', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_revealedPhone != null)
                          // Show phone
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone, color: Colors.green, size: 18),
                                      const SizedBox(width: 8),
                                      Text(_revealedPhone!,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Copy
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _revealedPhone!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Phone number copied!'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                                  );
                                },
                              ),
                              // Call
                              IconButton(
                                icon: const Icon(Icons.call, color: Colors.green, size: 20),
                                onPressed: () async {
                                  await launchUrl(Uri.parse('tel:$_revealedPhone'));
                                },
                              ),
                            ],
                          )
                        else if (!widget.hasActivePackage)
                          // Not premium
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFAD1457)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_open, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Upgrade to view phone number',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          )
                        else
                          // Premium — show reveal button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loadingPhone ? null : _revealPhone,
                              icon: _loadingPhone
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.visibility, size: 18),
                              label: const Text('View Phone Number'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Photo Gallery (read-only) ────────────────────────
                if (photos.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: PhotoGalleryWidget(
                      initialPhotos: photos,
                      editable: false,
                    ),
                  ),

                // ── Send Interest CTA ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _doAction('interest'),
                      icon: const Icon(Icons.favorite),
                      label: Text(
                        _active.contains('interest') ? 'Interest Sent ✓' : 'Send Interest',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _active.contains('interest')
                            ? Colors.grey.shade400
                            : const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(String gender) {
    return Container(
      color: const Color(0xFFFCE4EC),
      child: Center(
        child: Icon(
          gender == 'Female' ? Icons.face : Icons.face_3,
          size: 100,
          color: const Color(0xFFE91E63).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _callBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool locked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: locked ? Colors.grey.shade100 : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: locked ? Colors.grey.shade300 : color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(locked ? Icons.lock_outline : icon,
                color: locked ? Colors.grey.shade400 : color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: locked ? Colors.grey.shade400 : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active ? activeColor : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              boxShadow: active
                  ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Icon(icon, color: active ? Colors.white : Colors.grey.shade600, size: 22),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? activeColor : Colors.grey.shade600,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFE91E63), size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
            ),
          ),
        ],
      ),
    );
  }
}
