import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'register_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getProfile();
    if (res['status'] == true) {
      setState(() { _profile = res['data']; _loading = false; });
    } else {
      setState(() { _error = res['message'] ?? 'Profile load nahi hui'; _loading = false; });
    }
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
    setState(() => _isLoggingOut = true);
    await ApiService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfile),
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: _profile!),
                  ),
                );
                if (updated == true) _loadProfile();
              },
            ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                  ],
                ))
              : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final p = _profile!;
    final photoUrl = p['profile_photo_url'];
    final religion = p['religion'] as Map?;
    final location = p['location'] as Map?;
    final education = p['education'] as Map?;
    final habits = p['habits'] as Map?;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo + Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (photoUrl != null && photoUrl.toString().isNotEmpty)
                        ? NetworkImage(photoUrl.toString())
                        : null,
                    child: (photoUrl == null || photoUrl.toString().isEmpty)
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(p['full_name'] ?? 'N/A',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (p['gender'] != null)
                    Text(p['gender'], style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _infoCard('Basic Info', [
              _row('Date of Birth', p['dob']),
              _row('Profile For', p['profile_for']),
              _row('Bio', p['bio']),
            ]),

            if (religion != null)
              _infoCard('Religion', [
                _row('Religion', religion['religion']),
                _row('Caste', religion['caste']),
                _row('Mother Tongue', religion['mother_tongue']),
              ]),

            if (location != null)
              _infoCard('Location', [
                _row('State', location['state']),
                _row('City', location['city']),
              ]),

            if (education != null)
              _infoCard('Education & Career', [
                _row('Education', education['education']),
                _row('Profession', education['profession']),
                _row('Income', education['income']),
              ]),

            if (habits != null)
              _infoCard('Physical Details', [
                _row('Height', habits['height']),
                _row('Weight', habits['weight']),
                _row('Marital Status', habits['marital_status']),
                _row('Blood Group', habits['blood_group']),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                color: Color(0xFFE91E63))),
            const Divider(),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value.toString(),
              style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
