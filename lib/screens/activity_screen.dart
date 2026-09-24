import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int? _myUserId;
  String _myName = 'Someone';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final id = await ApiService.getUserId();
    final profile = await ApiService.getProfile();
    if (!mounted) return;
    setState(() {
      _myUserId = id;
      _myName = profile['data']?['full_name']?.toString() ?? 'Someone';
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: const [
                Text('Activity',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
            TabBar(
              controller: _tab,
              labelColor: const Color(0xFFE91E63),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFE91E63),
              tabs: const [Tab(text: 'Received'), Tab(text: 'Sent'), Tab(text: 'All')],
            ),
            Expanded(
              child: _myUserId == null
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _buildList(filter: 'received'),
                        _buildList(filter: 'sent'),
                        _buildList(filter: 'all'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList({required String filter}) {
    Stream<QuerySnapshot> stream;
    final userId = _myUserId!;

    if (filter == 'received') {
      dev.log(
        'Activity source: Firestore activities, filter: toUserId == $userId',
        name: 'ActivityData',
      );
      stream = FirebaseService.getActivities(userId);
    } else if (filter == 'sent') {
      dev.log(
        'Activity source: Firestore activities, filter: fromUserId == $userId',
        name: 'ActivityData',
      );
      stream = FirebaseFirestore.instance
          .collection('activities')
          .where('fromUserId', isEqualTo: userId)
          .snapshots();
    } else {
      dev.log(
        'Activity source: Firestore activities, filter: toUserId == $userId',
        name: 'ActivityData',
      );
      stream = FirebaseFirestore.instance
          .collection('activities')
          .where('toUserId', isEqualTo: userId)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          dev.log('Activity data error: ${snap.error}', name: 'ActivityData');
          return Center(child: Text('Activity load error: ${snap.error}'));
        }
        final docs = [...?snap.data?.docs];
        dev.log('Activity documents received: ${docs.length}', name: 'ActivityData');
        for (final document in docs) {
          dev.log(
            'Activity document ${document.id}: ${document.data()}',
            name: 'ActivityData',
          );
        }
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['timestamp'] as Timestamp?;
          final bTime = bData['timestamp'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        if (docs.isEmpty) {
          return const Center(child: Text('No activity yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final a = docs[i].data() as Map<String, dynamic>;
            return _buildTile(docs[i].id, a);
          },
        );
      },
    );
  }

  Widget _buildTile(String activityId, Map<String, dynamic> a) {
    final type = a['type'] ?? '';
    final name = a['fromName'] ?? 'Someone';
    final message = a['message'] ?? '';
    final time = a['timestamp'] as Timestamp?;
    final timeStr = time != null ? _formatTime(time.toDate()) : '';

    Color iconColor;
    IconData iconData;
    switch (type) {
      case 'interest':
        iconData = Icons.favorite;
        iconColor = const Color(0xFFE91E63);
        break;
      case 'shortlist':
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      case 'ignore':
        iconData = Icons.close;
        iconColor = Colors.red;
        break;
      case 'accepted':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'rejected':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'message':
        iconData = Icons.chat;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.blue;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey.shade200,
        child: const Icon(Icons.person, color: Colors.grey, size: 30),
      ),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Row(
        children: [
          Icon(iconData, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(message,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(timeStr,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 6),
          if (type == 'interest' && a['response'] == null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _responseButton(activityId, a, 'accepted', 'Accept', Colors.green),
                const SizedBox(width: 4),
                _responseButton(activityId, a, 'rejected', 'Reject', Colors.red),
              ],
            ),
        ],
      ),
    );
  }

  Widget _responseButton(String activityId, Map<String, dynamic> activity,
      String response, String label, Color color) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseService.respondToActivity(
            activityId: activityId,
            fromUserId: activity['fromUserId'] as int,
            toUserId: _myUserId!,
            fromName: _myName,
            response: response,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
