import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

/// Result object returned when payment screen pops
class PaymentResult {
  final bool success;
  final String message;
  final String cfOrderId;

  const PaymentResult({
    required this.success,
    required this.message,
    required this.cfOrderId,
  });
}

/// Cashfree Payment Screen
/// Opens Cashfree checkout in external browser.
/// User completes payment → comes back to app → taps "I've Paid" → verified.
class CashfreePaymentScreen extends StatefulWidget {
  final String checkoutUrl;
  final String cfOrderId;
  final String planLabel;
  final double amount;

  const CashfreePaymentScreen({
    super.key,
    required this.checkoutUrl,
    required this.cfOrderId,
    required this.planLabel,
    required this.amount,
  });

  @override
  State<CashfreePaymentScreen> createState() => _CashfreePaymentScreenState();
}

class _CashfreePaymentScreenState extends State<CashfreePaymentScreen>
    with WidgetsBindingObserver {
  bool _browserOpened  = false;
  bool _verifying      = false;
  bool _done           = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-open browser when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) => _openBrowser());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App foreground pe aane pe auto-verify karo
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _browserOpened && !_done) {
      // User browser se wapas aaya — auto verify
      _verifyPayment();
    }
  }

  Future<void> _openBrowser() async {
    final uri = Uri.parse(widget.checkoutUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _browserOpened = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Browser open nahi hua: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyPayment() async {
    if (_verifying || _done || !mounted) return;
    setState(() => _verifying = true);

    // Poll up to 3 times
    PaymentResult? result;
    for (int attempt = 1; attempt <= 3; attempt++) {
      final res = await ApiService.verifyPayment(cfOrderId: widget.cfOrderId);
      final status = (res['data']?['status'] ?? '').toString().toUpperCase();

      if (status == 'SUCCESS') {
        result = PaymentResult(
          success: true,
          message: res['message'] ?? 'Payment successful! Subscription activated.',
          cfOrderId: widget.cfOrderId,
        );
        break;
      }
      if (status == 'CANCELLED' || status == 'FAILED') {
        result = PaymentResult(
          success: false,
          message: res['message'] ?? 'Payment failed or cancelled.',
          cfOrderId: widget.cfOrderId,
        );
        break;
      }
      if (attempt < 3) await Future.delayed(const Duration(seconds: 3));
    }

    result ??= PaymentResult(
      success: false,
      message: 'Payment pending. Please wait a moment and retry.',
      cfOrderId: widget.cfOrderId,
    );

    if (!mounted) return;
    setState(() => _verifying = false);

    if (result!.success) {
      _done = true;
      Navigator.pop(context, result);
    } else {
      // Show failure but don't pop — user can retry
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  void _cancelPayment() {
    if (_verifying) return;
    _done = true;
    Navigator.pop(
      context,
      PaymentResult(
        success: false,
        message: 'Payment cancelled.',
        cfOrderId: widget.cfOrderId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && !_verifying) _cancelPayment();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          title: const Text('Complete Payment',
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _verifying ? null : _cancelPayment,
          ),
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Order summary card ────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFE91E63).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.workspace_premium,
                          color: Color(0xFFE91E63), size: 40),
                      const SizedBox(height: 12),
                      Text(
                        widget.planLabel,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Steps ─────────────────────────────────────
                _buildStep('1', 'Browser mein payment page khul gaya hai',
                    done: _browserOpened),
                const SizedBox(height: 12),
                _buildStep(
                    '2', 'Card / UPI / Netbanking se payment complete karein',
                    done: false),
                const SizedBox(height: 12),
                _buildStep('3', 'Payment ke baad wapas app mein aayein',
                    done: false),

                const Spacer(),

                // ── Action buttons ────────────────────────────
                if (!_browserOpened)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open Payment Page',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                if (_browserOpened) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _verifying ? null : _verifyPayment,
                      icon: _verifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _verifying ? 'Verifying...' : 'I\'ve Paid — Verify Now',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _verifying ? null : _openBrowser,
                      icon: const Icon(Icons.refresh,
                          color: Color(0xFFE91E63)),
                      label: const Text('Re-open Payment Page',
                          style: TextStyle(color: Color(0xFFE91E63))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE91E63)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Secured badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Secured by Cashfree',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text, {required bool done}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done ? Colors.green : const Color(0xFFE91E63),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(number,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 14,
                  color: done ? Colors.grey : Colors.black87)),
        ),
      ],
    );
  }
}
