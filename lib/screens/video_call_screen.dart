import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class VideoCallScreen extends StatefulWidget {
  final int remoteUserId;
  final String remoteName;
  final String? remotePhoto;
  final int myUserId;

  const VideoCallScreen({
    super.key,
    required this.remoteUserId,
    required this.remoteName,
    this.remotePhoto,
    required this.myUserId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  RtcEngine? _engine;
  bool _joined       = false;
  bool _remoteJoined = false;
  bool _muted        = false;
  bool _cameraOff    = false;
  bool _frontCamera  = true;
  bool _loading      = true;
  int? _remoteUid;
  String? _error;
  int _seconds       = 0;
  Timer? _timer;

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
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      setState(() { _error = 'Camera & Microphone permissions are required'; _loading = false; });
      return;
    }

    // Channel name (same for both users)
    final ids = [widget.myUserId, widget.remoteUserId]..sort();
    final channelName = 'wivideo_${ids[0]}_${ids[1]}';

    final tokenRes = await ApiService.getCallToken(
      channelName: channelName,
      uid: widget.myUserId,
    );

    if (tokenRes['status'] != true) {
      setState(() { _error = tokenRes['message']?.toString() ?? 'Call setup failed'; _loading = false; });
      return;
    }

    final appId  = tokenRes['data']['app_id']?.toString() ?? '';
    final token  = tokenRes['data']['token']?.toString();
    final chName = tokenRes['data']['channel_name']?.toString() ?? channelName;

    if (appId.isEmpty) {
      setState(() { _error = 'Video calling not configured. Contact admin.'; _loading = false; });
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));
    await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.startPreview();

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (mounted) setState(() { _joined = true; _loading = false; });
        _startTimer();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (mounted) setState(() { _remoteJoined = true; _remoteUid = remoteUid; });
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (mounted) { setState(() { _remoteJoined = false; _remoteUid = null; }); _endCall(); }
      },
      onError: (err, msg) {
        if (mounted) setState(() { _error = 'Error: $msg'; _loading = false; });
      },
    ));

    await _engine!.joinChannel(
      token: token ?? '',
      channelId: chName,
      uid: widget.myUserId,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
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

  void _toggleCamera() async {
    setState(() => _cameraOff = !_cameraOff);
    await _engine?.muteLocalVideoStream(_cameraOff);
  }

  void _switchCamera() async {
    setState(() => _frontCamera = !_frontCamera);
    await _engine?.switchCamera();
  }

  void _endCall() {
    _timer?.cancel();
    _engine?.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? _buildError()
          : _loading
              ? _buildLoading()
              : _buildVideoUI(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(80),
          const SizedBox(height: 16),
          Text(widget.remoteName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Connecting video call...', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
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
            const Icon(Icons.videocam_off, color: Colors.red, size: 64),
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

  Widget _buildVideoUI() {
    return Stack(
      children: [
        // Remote video (full screen)
        if (_remoteJoined && _remoteUid != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: _remoteUid!),
              connection: const RtcConnection(),
            ),
          )
        else
          Container(
            color: const Color(0xFF1A1A2E),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(90),
                  const SizedBox(height: 16),
                  Text(widget.remoteName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Waiting...', style: TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ),

        // Local video (PiP top right)
        Positioned(
          top: 60, right: 16,
          child: SizedBox(
            width: 100, height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _cameraOff
                  ? Container(
                      color: Colors.black87,
                      child: const Center(child: Icon(Icons.videocam_off, color: Colors.white54)))
                  : AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
            ),
          ),
        ),

        // Top bar — name + timer
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.remoteName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      _remoteJoined ? _callDuration : 'Connecting...',
                      style: TextStyle(
                        color: _remoteJoined ? const Color(0xFF4CAF50) : Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ctrl(icon: _muted ? Icons.mic_off : Icons.mic,
                    color: _muted ? Colors.red : Colors.white,
                    onTap: _toggleMute, label: _muted ? 'Unmute' : 'Mute'),
                _ctrl(icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                    color: _cameraOff ? Colors.red : Colors.white,
                    onTap: _toggleCamera, label: _cameraOff ? 'Start Cam' : 'Stop Cam'),
                // End call (bigger)
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 66, height: 66,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                  ),
                ),
                _ctrl(icon: Icons.flip_camera_ios, color: Colors.white,
                    onTap: _switchCamera, label: 'Flip'),
                _ctrl(icon: Icons.volume_up, color: Colors.white,
                    onTap: () {}, label: 'Speaker'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE91E63), width: 2),
      ),
      child: ClipOval(
        child: (widget.remotePhoto != null && widget.remotePhoto!.isNotEmpty)
            ? Image.network(widget.remotePhoto!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(size))
            : _placeholder(size),
      ),
    );
  }

  Widget _placeholder(double size) => Container(
    color: const Color(0xFFE91E63).withOpacity(0.2),
    child: Icon(Icons.person, size: size * 0.5, color: const Color(0xFFE91E63)),
  );

  Widget _ctrl({required IconData icon, required Color color,
      required VoidCallback onTap, required String label}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}
