import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    ApiService.getUserId().then((id) => setState(() => _myUserId = id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildChatList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: const [
          Text('Messenger',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text('Search conversations',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_myUserId == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getUserChats(_myUserId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          dev.log('Firestore error: ${snap.error}', name: 'Messenger');
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = [...?snap.data?.docs];
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['lastMessageTime'] as Timestamp?;
          final bTime = bData['lastMessageTime'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        dev.log('Chat docs count: ${docs.length}', name: 'Messenger');
        for (var d in docs) {
          dev.log('Chat doc: ${d.data()}', name: 'Messenger');
        }
        if (docs.isEmpty) {
          return const Center(child: Text('No conversations yet'));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final users = List<int>.from(data['users'] ?? []);
            final otherUserId = users.firstWhere((u) => u != _myUserId, orElse: () => 0);
            final lastMsg = data['lastMessage'] ?? '';
            final lastFrom = data['lastMessageFrom'];
            final isMe = lastFrom == _myUserId;
            final time = data['lastMessageTime'] as Timestamp?;
            final timeStr = time != null ? _formatTime(time.toDate()) : '';

            return _ChatTile(
              myUserId: _myUserId!,
              otherUserId: otherUserId,
              lastMsg: isMe ? 'You: $lastMsg' : lastMsg,
              time: timeStr,
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ChatTile extends StatefulWidget {
  final int myUserId;
  final int otherUserId;
  final String lastMsg;
  final String time;

  const _ChatTile({
    required this.myUserId,
    required this.otherUserId,
    required this.lastMsg,
    required this.time,
  });

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  String _name = '';
  String? _photo;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final res = await ApiService.viewProfile(widget.otherUserId);
    dev.log('viewProfile ${widget.otherUserId}: $res', name: 'ChatTile');
    if (res['status'] == true && mounted) {
      final data = res['data'];
      setState(() {
        _name = data['full_name'] ?? 'User ${widget.otherUserId}';
        _photo = data['profile_photo_url'];
        _loaded = true;
      });
    } else if (mounted) {
      setState(() {
        _name = 'User ${widget.otherUserId}';
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          name: _name,
          userId: widget.otherUserId,
          myUserId: widget.myUserId,
        ),
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (_photo != null && _photo!.isNotEmpty)
                  ? NetworkImage(_photo!)
                  : null,
              child: (_photo == null || _photo!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.grey, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_loaded ? _name : '...',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(widget.lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            Text(widget.time,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── CHAT DETAIL SCREEN ─────────────────────────────────────────────────────

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final int userId;      // other user
  final int myUserId;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.userId,
    this.myUserId = 0,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  int _myId = 0;
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _loadMyInfo();
  }

  Future<void> _loadMyInfo() async {
    final id = widget.myUserId != 0
        ? widget.myUserId
        : await ApiService.getUserId() ?? 0;
    final res = await ApiService.getProfile();
    if (mounted) {
      setState(() {
        _myId = id;
        _myName = res['data']?['full_name'] ?? 'Me';
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_myId == 0) {
      dev.log('_myId is 0, cannot send message', name: 'ChatDetail');
      return;
    }
    dev.log('Sending: myId=$_myId toId=${widget.userId} text=$text', name: 'ChatDetail');
    _controller.clear();
    await FirebaseService.sendMessage(
      fromUserId: _myId,
      toUserId: widget.userId,
      fromName: _myName,
      text: text,
    );
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 8),
            Text(widget.name,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_myId == 0) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getMessages(_myId, widget.userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final m = docs[i].data() as Map<String, dynamic>;
            final isMe = m['from'] == _myId;
            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFFE91E63) : Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 16),
                  ),
                ),
                child: Text(m['text'] ?? '',
                    style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: Color(0xFFE91E63), shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
