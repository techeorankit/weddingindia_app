import 'dart:math';
import 'package:flutter/material.dart';
import 'package:weddingindiaapp/screens/matches_screen.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _petalController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoFlip;

  final Random _random = Random();

  final List<Petal> _petals = [];

  @override
  void initState() {
    super.initState();

    // Create flower petals
    for (int i = 0; i < 25; i++) {
      _petals.add(
        Petal(
          x: _random.nextDouble(),
          delay: _random.nextDouble() * 0.8,
          size: 8 + _random.nextDouble() * 10,
          speed: 0.5 + _random.nextDouble() * 1.2,
          rotation: _random.nextDouble() * pi * 2,
        ),
      );
    }

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(
          0.0,
          0.65,
          curve: Curves.easeIn,
        ),
      ),
    );

    _logoFlip = Tween<double>(
      begin: pi,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _logoController.forward();

    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Go to next screen
    Future.delayed(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;

      final token = await ApiService.getToken();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => token != null
              ? const MatchesScreen()
              : const RegisterScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _petalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Falling flowers
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: PetalPainter(
                  petals: _petals,
                  animation: _petalController,
                ),
              ),
            ),
          ),
          // Animated Logo
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_logoFlip.value),
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Image.asset(
                'asset/splash.jpeg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Petal {
  final double x;
  final double delay;
  final double size;
  final double speed;
  final double rotation;

  Petal({
    required this.x,
    required this.delay,
    required this.size,
    required this.speed,
    required this.rotation,
  });
}

class PetalPainter extends CustomPainter {
  final List<Petal> petals;
  final Animation<double> animation;

  PetalPainter({
    required this.petals,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..style = PaintingStyle.fill;

    final elapsedSeconds = animation.value * 4;

    for (final petal in petals) {

      // Different falling speed
      final progress =
          ((elapsedSeconds * petal.speed + petal.delay) % 4.0) / 4.0;

      final xMovement =
          sin((progress * pi * 4) + petal.rotation) * 35;

      final x =
          petal.x * size.width + xMovement;

      final y =
          progress * (size.height + 100) - 50;

      canvas.save();

      canvas.translate(x, y);

      canvas.rotate(
        petal.rotation + progress * pi * 4,
      );

      paint.color = Colors.pink.withValues(alpha: 0.75);

      // Petal shape
      final path = Path();

      path.moveTo(0, -petal.size);

      path.quadraticBezierTo(
        petal.size,
        -petal.size * 0.4,
        0,
        petal.size,
      );

      path.quadraticBezierTo(
        -petal.size,
        -petal.size * 0.4,
        0,
        -petal.size,
      );

      canvas.drawPath(path, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PetalPainter oldDelegate) {
    return true;
  }
}