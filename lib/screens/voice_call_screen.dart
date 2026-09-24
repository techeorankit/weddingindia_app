import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class VoiceCallScreen extends StatefulWidget {
  final int remoteUserId;
  final String remoteName;
  final String? remotePhoto;
  final int myUserId;

  const VoiceCallScreen({
    super.key,
    required this.remoteUserId,
    required this.remoteName,
    this.remotePhoto,
    required this.myUserId,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  RtcEngine? _engine;
  bool _joined      = false;
  bool _remoteJoined = false;
  bool _muted       = false;
  bool _speakerOn   = true;
  bool _loading     = true;
  String? _error;
  int _seconds      = 0;
  Timer? _timer;
  String _channelName = '';

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Future<void> _initCall() async {
    // Permissions
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      setState(() { _error = 'Microphone permission denied'; _loading = false; });
      return;
    }

    // Get token from server
    _channelName = 'wicall_${widget.myUserId}_${widget.remoteUserId}';
    // Ensure channel is same for both users (sort IDs)
    final ids = [widget.myUserId, widget.remoteUserId]..sort();
    _channelName = 'wicall_${ids[0]}_${ids[1]}';

    final tokenRes = await ApiService.getCallToken(
      channelName: _channelName,
      uid: widget.myUserId,
    );

    if (tokenRes['status'] != true) {
      setState(() { _error = tokenRes['message']?.toString() ?? 'Call setup failed'; _loading = false; });
      return;
    }

    final appId       = tokenRes['data']['app_id']?.toString() ?? '';
    final token       = tokenRes['data']['token']?.toString();
    final channelName = tokenRes['data']['channel_name']?.toString() ?? _channelName;

    if (appId.isEmpty) {
      setState(() { _error = 'Calling not configured. Contact admin.'; _loading = false; });
      return;
    }

    // Init Agora engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));
    await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
    await _engine!.disableVideo();
    await _engine!.setEnableSpeakerphone(_speakerOn);

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (mounted) setState(() { _joined = true; _loading = false; });
        _startTimer();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (mounted) setState(() => _remoteJoined = true);
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (mounted) { setState(() => _remoteJoined = false); _endCall(); }
      },
      onError: (err, msg) {
        if (mounted) setState(() { _error = 'Error: $msg'; _loading = false; });
      },
    ));

    await _engine!.joinChannel(
      token: token ?? '',
      channelId: channelName,
      uid: widget.myUserId,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get _callDuration {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleMute() async {
    setState(() => _muted = !_muted);
    await _engine?.muteLocalAudioStream(_muted);
  }

  void _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await _engine?.setEnableSpeakerphone(_speakerOn);
  }

  void _endCall() {
    _timer?.cancel();
    _engine?.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: _error != null
            ? _buildError()
            : _loading
                ? _buildLoading()
                : _buildCallUI(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(size: 90),
          const SizedBox(height: 20),
          Text(widget.remoteName,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Connecting...', style: TextStyle(color: Colors.white60, fontSize: 16)),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Color(0xFFE91E63)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_end, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallUI() {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Status
        Text(
          _remoteJoined ? _callDuration : 'Ringing...',
          style: TextStyle(
            color: _remoteJoined ? const Color(0xFF4CAF50) : Colors.white60,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        // Avatar
        _buildAvatar(size: 110),
        const SizedBox(height: 20),
        // Name
        Text(widget.remoteName,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _remoteJoined ? 'Voice Call' : 'Calling...',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const Spacer(),
        // Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlBtn(
                icon: _muted ? Icons.mic_off : Icons.mic,
                label: _muted ? 'Unmute' : 'Mute',
                color: _muted ? Colors.red : Colors.white,
                bg: Colors.white12,
                onTap: _toggleMute,
              ),
              // End call
              GestureDetector(
                onTap: _endCall,
                child: Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                ),
              ),
              _controlBtn(
                icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                label: _speakerOn ? 'Speaker' : 'Earpiece',
                color: _speakerOn ? const Color(0xFFE91E63) : Colors.white,
                bg: Colors.white12,
                onTap: _toggleSpeaker,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({double size = 80}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE91E63), width: 3),
      ),
      child: ClipOval(
        child: (widget.remotePhoto != null && widget.remotePhoto!.isNotEmpty)
            ? Image.network(widget.remotePhoto!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarPlaceholder(size))
            : _avatarPlaceholder(size),
      ),
    );
  }

  Widget _avatarPlaceholder(double size) {
    return Container(
      color: const Color(0xFFE91E63).withOpacity(0.2),
      child: Icon(Icons.person, size: size * 0.5, color: const Color(0xFFE91E63)),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}
