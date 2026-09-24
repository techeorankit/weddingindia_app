import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import '../services/api_service.dart';

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

/// Cashfree native Flutter checkout.
///
/// Backend creates the Cashfree order and returns:
///   - cf_order_id
///   - payment_session_id
///   - environment
///
/// This screen then opens Cashfree's own checkout UI using the official
/// Flutter SDK. No external browser and no manually-built checkout URL.
class CashfreePaymentScreen extends StatefulWidget {
  final String paymentSessionId;
  final String cfOrderId;
  final String planLabel;
  final double amount;
  final String environment;

  const CashfreePaymentScreen({
    super.key,
    required this.paymentSessionId,
    required this.cfOrderId,
    required this.planLabel,
    required this.amount,
    required this.environment,
  });

  @override
  State<CashfreePaymentScreen> createState() => _CashfreePaymentScreenState();
}

class _CashfreePaymentScreenState extends State<CashfreePaymentScreen> {
  final CFPaymentGatewayService _cashfree = CFPaymentGatewayService();
  bool _opening = true;
  bool _verifying = false;
  bool _finished = false;
  String _message = 'Opening Cashfree secure payment...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCashfree());
  }

  Future<void> _openCashfree() async {
    if (_finished || !mounted) return;

    try {
      final env = widget.environment.toLowerCase() == 'production'
          ? CFEnvironment.PRODUCTION
          : CFEnvironment.SANDBOX;

      final session = CFSessionBuilder()
          .setEnvironment(env)
          .setOrderId(widget.cfOrderId)
          .setPaymentSessionId(widget.paymentSessionId)
          .build();

      final checkout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _cashfree.setCallback(_onVerify, _onError);

      if (mounted) {
        setState(() {
          _opening = false;
          _message = 'Cashfree checkout opened. Complete your payment.';
        });
      }

      // This opens Cashfree's native hosted checkout with the exact order
      // amount created by the backend.
      _cashfree.doPayment(checkout);
    } on CFException catch (e) {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _message = e.message;
      });
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _message = 'Unable to open Cashfree payment.';
      });
      _showError('Unable to open Cashfree payment. Please try again.');
    }
  }

  Future<void> _onVerify(String orderId) async {
    if (_finished || _verifying || !mounted) return;
    setState(() {
      _verifying = true;
      _message = 'Verifying payment...';
    });

    // Always verify on our backend. The SDK callback only tells us that the
    // checkout flow returned; the server remains the source of truth.
    PaymentResult? result;
    for (int attempt = 1; attempt <= 4; attempt++) {
      final res = await ApiService.verifyPayment(cfOrderId: orderId);
      final data = res['data'];
      final status = (data is Map ? data['status'] : null)
          ?.toString()
          .toUpperCase();

      if (status == 'SUCCESS') {
        result = PaymentResult(
          success: true,
          message: res['message']?.toString() ??
              'Payment successful! Subscription activated.',
          cfOrderId: orderId,
        );
        break;
      }

      if (status == 'CANCELLED' || status == 'FAILED') {
        result = PaymentResult(
          success: false,
          message: res['message']?.toString() ?? 'Payment failed or cancelled.',
          cfOrderId: orderId,
        );
        break;
      }

      if (attempt < 4) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    result ??= PaymentResult(
      success: false,
      message: 'Payment is still pending. Please check again in a moment.',
      cfOrderId: orderId,
    );

    if (!mounted) return;
    setState(() => _verifying = false);

    if (result.success) {
      _finished = true;
      Navigator.pop(context, result);
    } else {
      _showError(result.message);
    }
  }

  void _onError(CFErrorResponse errorResponse, String orderId) {
    if (!mounted || _finished) return;
    final msg = errorResponse.getMessage() ?? 'Payment failed. Please try again.';
    setState(() {
      _opening = false;
      _message = msg;
    });
    _showError(msg);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _close() {
    if (_verifying || _finished) return;
    _finished = true;
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
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Cashfree Payment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _verifying ? null : _close,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFE91E63),
                    size: 56,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.planLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_opening || _verifying)
                    const CircularProgressIndicator(
                      color: Color(0xFFE91E63),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Secure checkout powered by Cashfree',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
