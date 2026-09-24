import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'cashfree_payment_screen.dart';

class UpgradeScreen extends StatefulWidget {
  final VoidCallback? onPackageActivated;

  const UpgradeScreen({super.key, this.onPackageActivated});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  int  _selectedPlan = 0;
  List<Map<String, dynamic>> _plans    = [];
  List<Map<String, dynamic>> _features = [];
  bool _loading          = true;
  bool _isPurchasing     = false;

  // Gateway status loaded once
  bool _gatewayEnabled   = false;
  bool _gatewayLoading   = true;
  String _gatewayEnv     = 'sandbox';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Run both calls in parallel
    final results = await Future.wait([
      ApiService.getUpgradeData(),
      ApiService.getGatewayStatus(),
    ]);

    final upgradeRes  = results[0];
    final gatewayRes  = results[1];

    if (!mounted) return;

    // Plans + features
    if (upgradeRes['status'] == true) {
      final plans = List<Map<String, dynamic>>.from(
          upgradeRes['data']['plans'] ?? []);
      final bestIndex =
          plans.indexWhere((p) => p['is_best_value'].toString() == '1');
      setState(() {
        _plans        = plans;
        _features     = List<Map<String, dynamic>>.from(
            upgradeRes['data']['features'] ?? []);
        _selectedPlan = bestIndex >= 0 ? bestIndex : 0;
      });
    }

    // Gateway status
    if (gatewayRes['status'] == true) {
      setState(() {
        _gatewayEnabled = gatewayRes['data']?['enabled'] == true;
        _gatewayEnv     = gatewayRes['data']?['environment'] ?? 'sandbox';
      });
    } else {
      // API fail hoi — default enabled maano, createOrder pe fail hoga
      setState(() {
        _gatewayEnabled = true;
        _gatewayEnv     = 'production';
      });
    }

    setState(() {
      _loading        = false;
      _gatewayLoading = false;
    });
  }

  // ── Icon map ──────────────────────────────────────────────────────────────
  static const _iconMap = {
    'visibility': Icons.visibility,
    'send'      : Icons.send,
    'chat'      : Icons.chat,
    'verified'  : Icons.verified,
    'block'     : Icons.block,
    'star'      : Icons.star,
  };

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildBanner(),
                      const SizedBox(height: 24),
                      if (_plans.isNotEmpty) _buildPlans(),
                      const SizedBox(height: 24),
                      if (_features.isNotEmpty) _buildFeatures(),
                      const SizedBox(height: 28),
                      // Sandbox notice
                      if (!_gatewayLoading &&
                          _gatewayEnabled &&
                          _gatewayEnv == 'sandbox')
                        _buildSandboxBanner(),
                      // Gateway disabled notice
                      if (!_gatewayLoading && !_gatewayEnabled)
                        _buildGatewayDisabledBanner(),
                      if (_plans.isNotEmpty) _buildCTAButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 14),
          const Text('Upgrade to Premium',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Find your perfect match faster',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPlans() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Your Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            children: List.generate(_plans.length, (i) {
              final p        = _plans[i];
              final isSelected = _selectedPlan == i;
              final isBest   = p['is_best_value'].toString() == '1';
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPlan = i),
                  child: Container(
                    margin:
                        EdgeInsets.only(right: i < _plans.length - 1 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFE4EF)
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE91E63)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (isBest)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Best Value',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        Text(p['label'] ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected
                                    ? const Color(0xFFE91E63)
                                    : Colors.black)),
                        const SizedBox(height: 4),
                        Text(p['price'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                            '${p['profile_limit'] ?? 2} profiles / ${p['duration_months'] ?? 1} month(s)',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 10)),
                        Text(p['original_price'] ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Premium Features',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconMap[f['icon']] ?? Icons.star,
                        color: const Color(0xFFE91E63),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(f['description'] ?? '',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSandboxBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        border: Border.all(color: const Color(0xFFFF9800)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Text('🧪', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sandbox / Test Mode',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  'Test card: 4111 1111 1111 1111\nUPI: success@upi',
                  style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayDisabledBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Text('⚠️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Online payment temporarily unavailable. Contact support.',
              style: TextStyle(fontSize: 13, color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton() {
    final plan = _plans[_selectedPlan];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isPurchasing
              ? null
              : () => _startPayment(plan),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _isPurchasing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pay ${plan['price']} — ${plan['label']}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Payment flow ──────────────────────────────────────────────────────────

  Future<void> _startPayment(Map<String, dynamic> plan) async {
    if (!mounted) return;

    setState(() => _isPurchasing = true);

    // Pehle gateway status check karo agar abhi tak load nahi hua
    if (_gatewayLoading) {
      final gatewayRes = await ApiService.getGatewayStatus();
      if (gatewayRes['status'] == true) {
        _gatewayEnabled = gatewayRes['data']?['enabled'] == true;
        _gatewayEnv     = gatewayRes['data']?['environment'] ?? 'production';
      } else {
        _gatewayEnabled = true;
      }
      _gatewayLoading = false;
    }

    // If gateway disabled — fallback manual dialog
    if (!_gatewayEnabled) {
      setState(() => _isPurchasing = false);
      await _fallbackManualDialog(plan);
      return;
    }

    // Step 1: Create order on our backend → get checkout URL
    final planId = int.tryParse(plan['id'].toString()) ?? 0;
    final orderRes = await ApiService.createPaymentOrder(planId: planId);

    if (!mounted) return;

    if (orderRes['status'] != true) {
      setState(() => _isPurchasing = false);
      _showSnack(orderRes['message'] ?? 'Could not create payment order', isError: true);
      return;
    }

    final checkoutUrl = orderRes['data']['checkout_url']?.toString() ?? '';
    final cfOrderId   = orderRes['data']['cf_order_id']?.toString()   ?? '';
    final rawAmount   = orderRes['data']['amount'];
    final amount      = (rawAmount is num)
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

    if (checkoutUrl.isEmpty || cfOrderId.isEmpty) {
      setState(() => _isPurchasing = false);
      _showSnack('Invalid payment response. Please try again.', isError: true);
      return;
    }

    setState(() => _isPurchasing = false);

    // Step 2: Open Cashfree WebView checkout
    final result = await Navigator.push<PaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CashfreePaymentScreen(
          checkoutUrl: checkoutUrl,
          cfOrderId: cfOrderId,
          planLabel: plan['label']?.toString() ?? '',
          amount: amount,
        ),
      ),
    );

    if (!mounted) return;

    // Step 3: Handle result
    if (result == null) return; // User closed without completing

    if (result.success) {
      _showSnack('🎉 Payment successful! Subscription activated.', isError: false);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (widget.onPackageActivated != null) {
        widget.onPackageActivated!();
      } else {
        Navigator.pop(context, true);
      }
    } else {
      _showSnack(result.message, isError: true);
    }
  }

  /// Fallback when gateway is disabled — manual payment reference
  Future<void> _fallbackManualDialog(Map<String, dynamic> plan) async {
    final refCtrl = TextEditingController();
    final reference = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Online payment unavailable. Please pay via bank transfer and enter your UTR/reference number below.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: refCtrl,
              decoration: const InputDecoration(
                labelText: 'Payment Reference / UTR',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, refCtrl.text.trim()),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
    refCtrl.dispose();

    if (reference == null || reference.isEmpty || !mounted) return;

    setState(() => _isPurchasing = true);
    final result = await ApiService.subscribeToPlan(
      planId: int.tryParse(plan['id'].toString()) ?? 0,
      paymentReference: reference,
    );
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    _showSnack(
      result['message'] ?? 'Could not activate package',
      isError: result['status'] != true,
    );
    if (result['status'] == true) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (widget.onPackageActivated != null) {
        widget.onPackageActivated!();
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }
}
