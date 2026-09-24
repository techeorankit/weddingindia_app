import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import 'activity_screen.dart';
import 'document_upload_screen.dart';
import 'edit_profile_screen.dart';
import 'messenger_screen.dart';
import 'upgrade_screen.dart';
import 'register_screen.dart';

enum _ProfileMenuAction { privacy, terms, about, help, logout }

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int _currentTab = 0;
  String? _userName;
  String? _photoUrl;
  int? _myUserId;
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _filteredProfiles = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _activeFilter = 'All';
  String? _myCity;
  Map<String, dynamic> _appContent = {};
  bool _hasActivePackage = false;
  bool _hasDocument = false;
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> result = _profiles;
    if (query.isNotEmpty) {
      result = result.where((p) =>
          (p['full_name']?.toString().toLowerCase() ?? '').contains(query)).toList();
    }
    if (_activeFilter == 'Verified') {
      result = result.where((p) => p['is_profile_complete'].toString() == '1').toList();
    } else if (_activeFilter == 'Just Joined') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      result = result.where((p) {
        final created = p['created_at']?.toString() ?? '';
        if (created.isEmpty) return false;
        try {
          return DateTime.parse(created).isAfter(weekAgo);
        } catch (_) { return false; }
      }).toList();
    } else if (_activeFilter == 'Nearby') {
      result = result.where((p) =>
          (p['city']?.toString().toLowerCase() ?? '') == (_myCity?.toLowerCase() ?? '')).toList();
    }

    setState(() => _filteredProfiles = result);
  }

  void _onSearch(String query) => _applyFilters();

  Future<void> _goToEditProfile() async {
    final profileRes = await ApiService.getProfile();
    if (!mounted) return;
    if (profileRes['status'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profileRes['message'] ?? 'Profile load nahi hui')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: profileRes['data']),
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
      (_) => false,
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContent(String key) {
    final page = _appContent[key];
    if (page is! Map<String, dynamic>) {
      _showInfoDialog('Content unavailable', 'Please try again later.');
      return;
    }
    _showInfoDialog(
      page['title']?.toString() ?? 'Wedding India',
      page['body']?.toString() ?? '',
    );
  }

  void _handleMenuAction(_ProfileMenuAction action) {
    switch (action) {
      case _ProfileMenuAction.privacy:
        _showContent('privacy');
        break;
      case _ProfileMenuAction.terms:
        _showContent('terms');
        break;
      case _ProfileMenuAction.about:
        _showContent('about');
        break;
      case _ProfileMenuAction.help:
        _showContent('help');
        break;
      case _ProfileMenuAction.logout:
        _logout();
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profileRes = await ApiService.getProfile();
    dev.log('Profile Response: $profileRes', name: 'MatchesScreen');
    if (profileRes['status'] == true && mounted) {
      final data = profileRes['data'];
      setState(() {
        _userName = data['full_name'];
        _photoUrl = data['profile_photo_url'];
        _myCity = data['location']?['city']?.toString().toLowerCase();
        final document = data['document'];
        _hasDocument = document is Map &&
            document['document_url']?.toString().isNotEmpty == true;
      });
    }
    final contentRes = await ApiService.getAppContent();
    if (contentRes['status'] == true && contentRes['data'] is Map && mounted) {
      setState(() => _appContent = Map<String, dynamic>.from(contentRes['data']));
    }
    final subscriptionRes = await ApiService.getSubscriptionStatus();
    if (subscriptionRes['status'] == true && mounted) {
      final subscription = Map<String, dynamic>.from(subscriptionRes['data'] ?? {});
      final limit = int.tryParse(subscription['profile_limit'].toString()) ?? 2;
      final viewed = int.tryParse(subscription['profiles_viewed'].toString()) ?? 0;
      setState(() => _hasActivePackage = subscription['plan_id'] != null);
      if (viewed >= limit) {
        await _openUpgradeScreen();
      }
      if (_hasActivePackage && !_hasDocument && mounted) {
        await _promptForDocument();
      }
    }
    _myUserId = await ApiService.getUserId();
    if (_myUserId != null) {
      await FirebaseService.init(_myUserId!);
    }

    final matchRes = await ApiService.findMatches();
    dev.log('Matches Response: $matchRes', name: 'MatchesScreen');
    if (matchRes['status'] == true && mounted) {
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(matchRes['data']['matches'] ?? []);
        _filteredProfiles = _profiles;
        _loading = false;
      });
      _applyFilters();
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  // track active states per user
  final Map<int, Set<String>> _activeActions = {};

  Future<bool> _handleAction(int toUserId, String type) async {
    if (!_hasActivePackage) {
      await _openUpgradeScreen();
      return false;
    }
    final res = await ApiService.sendInteraction(toUserId: toUserId, type: type);
    if (!mounted) return false;

    if (res['status'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Action failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    final data = res['data'];
    if (data is! Map || data['active'] is! bool) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid response from server')),
      );
      return false;
    }

    setState(() {
      _activeActions[toUserId] ??= {};
      if (data['active'] == true) {
        _activeActions[toUserId]!.add(type);
        if (type != 'chat') {
          FirebaseService.sendActivityNotification(
            fromUserId: _myUserId ?? 0,
            toUserId: toUserId,
            fromName: _userName ?? 'Someone',
            type: type,
          );
        }
      } else {
        _activeActions[toUserId]!.remove(type);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message']), duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating),
    );
    return true;
  }

  Future<void> _openUpgradeScreen() async {
    final purchased = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
    );
    if (purchased == true && mounted) {
      await _openDocumentUpload();
    }
  }

  Future<void> _openDocumentUpload() async {
    if (!mounted) return;
    setState(() => _hasActivePackage = true);
    final uploaded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const DocumentUploadScreen()),
    );
    if (uploaded == true && mounted) setState(() => _hasDocument = true);
  }

  Future<void> _promptForDocument() async {
    final uploadNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Document upload required'),
        content: const Text('Please upload one document to continue using your package.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload now'),
          ),
        ],
      ),
    );
    if (uploadNow == true && mounted) await _openDocumentUpload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentTab,
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterChips(),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredProfiles.isEmpty
                          ? const Center(child: Text('No matches found'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredProfiles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 20),
                              itemBuilder: (_, i) => _buildProfileCard(_filteredProfiles[i]),
                            ),
                ),
              ],
            ),
          ),
          const ActivityScreen(),
          const MessengerScreen(),
          UpgradeScreen(onPackageActivated: _openDocumentUpload),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _goToEditProfile(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: (_photoUrl == null || _photoUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.grey, size: 26)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE91E63),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_userName ?? 'Matches',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => _goToEditProfile(),
                child: const Text('Edit Profile',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE91E63))),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _currentTab = 1),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 28),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('6',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            ),
          ),
          PopupMenuButton<_ProfileMenuAction>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ProfileMenuAction.privacy,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy Policy'),
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.terms,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.description_outlined),
                  title: Text('Terms & Conditions'),
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.about,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline),
                  title: Text('About Us'),
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.help,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.support_agent),
                  title: Text('Help Line'),
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.logout,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: "Search by name...",
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Verified', 'Just Joined', 'Nearby'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = filters[i];
          final isActive = _activeFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() => _activeFilter = filter);
              _applyFilters();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE91E63) : Colors.transparent,
                border: Border.all(
                  color: isActive ? const Color(0xFFE91E63) : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> p) {
    final userId = p['user_id'] is int ? p['user_id'] as int : int.tryParse(p['user_id'].toString()) ?? 0;
    final active = _activeActions[userId] ?? {};
    final photoUrl = p['profile_photo_url']?.toString() ?? '';
    final name = p['full_name']?.toString() ?? 'N/A';
    final age = p['age']?.toString() ?? '';
    final height = p['height']?.toString() ?? '';
    final city = p['city']?.toString() ?? '';
    final religion = p['religion']?.toString() ?? '';
    final profession = p['profession']?.toString() ?? '';
    final education = p['education']?.toString() ?? '';
    final actionBackground = _hasActivePackage ? Colors.white24 : Colors.white10;
    final actionForeground = _hasActivePackage ? Colors.white : Colors.white54;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background image placeholder
          Container(
            height: 460,
            color: Colors.blueGrey.shade200,
            child: photoUrl.isNotEmpty
                ? Image.network(photoUrl, height: 460, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.person, size: 120, color: Colors.white54)))
                : const Center(
                    child: Icon(Icons.person, size: 120, color: Colors.white54)),
          ),

          // Photo count badge - hide if no data
          // Tag
          Positioned(
            top: 12,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8)),
              ),
              child: const Text('Just Joined',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ),
          ),

          // Bottom info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Member',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${name}, ${age}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${height} · ${city} · ${religion}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                  Text('${profession}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                  Text(education,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('Profile managed by Self',
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionBtn(Icons.send, 'Interest',
                          !_hasActivePackage ? actionBackground : (active.contains('interest') ? const Color(0xFFE91E63) : const Color(0xFF8B1A2E)),
                          !_hasActivePackage ? actionForeground : Colors.white, () => _handleAction(userId, 'interest')),
                      _actionBtn(Icons.star_border, 'Shortlist',
                          !_hasActivePackage ? actionBackground : (active.contains('shortlist') ? Colors.amber : Colors.white24),
                          !_hasActivePackage ? actionForeground : Colors.white, () => _handleAction(userId, 'shortlist')),
                      _actionBtn(Icons.close, 'Ignore',
                          !_hasActivePackage ? actionBackground : (active.contains('ignore') ? Colors.red : Colors.white24),
                          !_hasActivePackage ? actionForeground : Colors.white, () => _handleAction(userId, 'ignore')),
                      _actionBtn(Icons.chat_bubble_outline, 'Chat',
                          !_hasActivePackage ? actionBackground : (active.contains('chat') ? Colors.green : Colors.white24),
                          !_hasActivePackage ? actionForeground : Colors.white, () async {
                            if (!_hasActivePackage) {
                              await _openUpgradeScreen();
                              return;
                            }
                            final actionSucceeded = await _handleAction(userId, 'chat');
                            if (actionSucceeded && mounted) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  name: name,
                                  userId: userId,
                                  myUserId: _myUserId ?? 0,
                                ),
                              ));
                            }
                          }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.favorite, 'label': 'Matches'},
      {'icon': Icons.access_time, 'label': 'Activity'},
      {'icon': Icons.chat_bubble_outline, 'label': 'Messenger'},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ...List.generate(items.length, (i) {
                final isActive = _currentTab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i]['icon'] as IconData,
                          color: isActive
                              ? const Color(0xFFE91E63)
                              : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive
                                ? const Color(0xFFE91E63)
                                : Colors.grey,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Upgrade button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentTab = 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: _currentTab == 3 ? const Color(0xFFE91E63) : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upgrade',
                        style: TextStyle(
                          fontSize: 11,
                          color: _currentTab == 3 ? const Color(0xFFE91E63) : Colors.grey,
                          fontWeight: _currentTab == 3 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
