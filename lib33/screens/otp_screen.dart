import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_for_screen.dart';
import 'matches_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String countryCode;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.countryCode,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 4 boxes for 4-digit OTP
  final List<TextEditingController> _controllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  bool _isSendingOtp = false;
  int _resendTimer = 30;
  Timer? _timer;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }
  Future<void> _sendOtpToPhone() async {
    setState(() {
      _isSendingOtp = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.sendOtp(
        phone: widget.phone,
        countryCode: widget.countryCode,
      );

      dev.log('=== SEND OTP RESPONSE ===', name: 'OTP');
      dev.log('Full response: $result', name: 'OTP');
      dev.log('status   : ${result['status']}', name: 'OTP');
      dev.log('message  : ${result['message']}', name: 'OTP');
      dev.log('==========================', name: 'OTP');

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }

      if (result['status'] == 'success' || result['status'] == true) {
        if (mounted) {
          _showSnackBar('OTP sent to your phone!', isSuccess: true);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _focusNodes[0].requestFocus();
            }
          });
        }
      } else {
        _errorMessage = result['message'] ?? 'Failed to send OTP';
        if (mounted) {
          _showSnackBar(_errorMessage);
        }
      }
    } catch (e) {
      dev.log('Error sending OTP: $e', name: 'OTP');
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _errorMessage = 'Network error: $e';
        });
        _showSnackBar('Failed to send OTP. Please try again.');
      }
    }
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendTimer == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _resendTimer--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otp;

    if (otp.length != 4) {
      _showSnackBar('Please enter the complete 4-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.verifyOtp(
      phone: widget.phone,
      countryCode: widget.countryCode,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    dev.log('=== VERIFY OTP RESPONSE ===', name: 'OTP');
    dev.log('status   : ${result['status']}', name: 'OTP');
    dev.log('message  : ${result['message']}', name: 'OTP');
    dev.log('data     : ${result['data']}', name: 'OTP');
    dev.log('===========================', name: 'OTP');

    if (result['status'] == true) {
      final data = result['data'] ?? {};
      final bool isNew = data['is_new_user'] ?? true;
      final bool isComplete = data['is_profile_complete'] ?? false;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) {
            if (!isNew) {
              return const MatchesScreen();
            } else if (!isComplete) {
              return const ProfileForScreen();
            } else {
              return const MatchesScreen();
            }
          },
        ),
            (route) => false,
      );
    } else {
      _showSnackBar(result['message'] ?? 'Invalid OTP. Please try again.');
      for (var c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      setState(() {});
    }
  }
  void _resendOtp() async {
    if (_resendTimer > 0) return;
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});

    await _sendOtpToPhone();
    _startResendTimer();
  }
  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4EF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_outline,
                  color: Color(0xFFE91E63), size: 40),
            ),
            const SizedBox(height: 24),

            const Text(
              'OTP Verification',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                children: [
                  const TextSpan(text: 'OTP sent to '),
                  TextSpan(
                    text: '${widget.countryCode} ${widget.phone}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Stack(
              children: [
                Column(
                  children: [
                    // 4 OTP boxes for 4-digit OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) {
                        final isFilled = _controllers[i].text.isNotEmpty;
                        return SizedBox(
                          width: 60,
                          height: 64,
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: isFilled
                                  ? const Color(0xFFFFE4EF)
                                  : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isFilled
                                      ? const Color(0xFFE91E63)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE91E63), width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {});
                              if (val.isNotEmpty && i < 3) {
                                _focusNodes[i + 1].requestFocus();
                              } else if (val.isEmpty && i > 0) {
                                _focusNodes[i - 1].requestFocus();
                              }
                              // Auto verify on last digit (4th digit)
                              if (i == 3 && val.isNotEmpty) {
                                _verifyOtp();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading || _isSendingOtp ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading || _isSendingOtp
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Verify OTP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: _resendTimer > 0
                          ? Text(
                        'Resend OTP in ${_resendTimer}s',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      )
                          : TextButton(
                        onPressed: _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Change mobile number',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                // Loading overlay
                if (_isSendingOtp)
                  Container(
                    color: Colors.white.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFFE91E63),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sending OTP to your phone...',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}