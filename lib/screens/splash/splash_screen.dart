import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

/// A Senior Frontend Designed, Hyper-Dynamic Express Splash Screen for CartIT.
///
/// Features:
/// - Deep Emerald to Electric Gold Aurora Mesh Background
/// - Animated Dynamic Energy Speed Lines & Radial Motion Trails
/// - Bento-style Floating Micro-Cards (10-Min Speed, Organic Fresh, Free Delivery, 24/7 Support)
/// - Morphing Hero Produce & Dynamic Basket Showcase with Light Sheen Sweeps
/// - High-Energy Sparkle & Starburst Particles
/// - Kinetic Dual-Tone Brand Typography with Shimmering Speed Badge
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Timeline Animation Controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _bentoFloatController;
  late AnimationController _particleController;

  // Staggered Animations
  late Animation<double> _bgMeshProgress;
  
  // 1. Jet Speed Cart Zoom-In Entrance
  late Animation<Offset> _cartJetSlide;
  late Animation<double> _cartScale;
  late Animation<double> _cartImpactBounce;
  late Animation<double> _jetTrailOpacity;

  // 2. Falling Asteroid Groceries Staggered Animations
  late Animation<Offset> _item1Drop; // Veggie / Store
  late Animation<Offset> _item2Drop; // Fresh Eco Leaf
  late Animation<Offset> _item3Drop; // Shopping Bag
  late Animation<Offset> _item4Drop; // Storefront
  late Animation<Offset> _item5Drop; // Basket

  late Animation<double> _item1Scale;
  late Animation<double> _item2Scale;
  late Animation<double> _item3Scale;
  late Animation<double> _item4Scale;
  late Animation<double> _item5Scale;

  late Animation<double> _item1Opacity;
  late Animation<double> _item2Opacity;
  late Animation<double> _item3Opacity;
  late Animation<double> _item4Opacity;
  late Animation<double> _item5Opacity;

  // 4. Kinetic Brand Typography
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineScale;
  late Animation<double> _shimmerProgress;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _startFlow();
  }

  void _setupControllers() {
    // Snappy 2.8-second master timeline for instant app launch
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _bentoFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // --- CHOREOGRAPHY TIMELINE ---

    _bgMeshProgress = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    );

    // STAGE 1: JET SPEED CART ARRIVAL (0.00 -> 0.28)
    // Starts off-screen left (-2.2, 0.0), shoots in at ultra speed and stops at center
    _cartJetSlide = Tween<Offset>(
      begin: const Offset(-2.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.02, 0.24, curve: Curves.fastOutSlowIn),
      ),
    );

    // Cart impact scale squeeze & rebound slam (0.22 -> 0.35)
    _cartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 1.25).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 0.90).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.90, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.02, 0.35),
      ),
    );

    _cartImpactBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 4.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.24, 0.38, curve: Curves.easeOut),
      ),
    );

    _jetTrailOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.02, 0.22, curve: Curves.easeOut),
    );

    // STAGE 2: ASTEROID GROCERY ITEMS RAINING / DROPPING INTO CART (0.28 -> 0.70)

    // Asteroid #1: 🍎 Red Apple (Drops all the way into cart basket)
    _item1Drop = Tween<Offset>(
      begin: const Offset(-0.8, -7.0),
      end: const Offset(-0.15, 0.05),
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.42, curve: Curves.easeInQuad),
      ),
    );
    _item1Scale = Tween<double>(begin: 1.8, end: 0.35).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.42, curve: Curves.easeInQuad),
      ),
    );
    _item1Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 75),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.26, 0.42, curve: Curves.easeInOut),
      ),
    );

    // Asteroid #2: 🥦 Broccoli (Drops all the way into cart basket)
    _item2Drop = Tween<Offset>(
      begin: const Offset(0.8, -7.5),
      end: const Offset(0.15, 0.05),
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.49, curve: Curves.easeInQuad),
      ),
    );
    _item2Scale = Tween<double>(begin: 1.9, end: 0.35).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.49, curve: Curves.easeInQuad),
      ),
    );
    _item2Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 75),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.33, 0.49, curve: Curves.easeInOut),
      ),
    );

    // Asteroid #3: 🥕 Carrot (Drops all the way into cart basket)
    _item3Drop = Tween<Offset>(
      begin: const Offset(0.0, -8.0),
      end: const Offset(0.0, 0.05),
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.42, 0.56, curve: Curves.easeInQuad),
      ),
    );
    _item3Scale = Tween<double>(begin: 2.0, end: 0.35).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.42, 0.56, curve: Curves.easeInQuad),
      ),
    );
    _item3Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 75),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.40, 0.56, curve: Curves.easeInOut),
      ),
    );

    // Asteroid #4: 🥑 Avocado (Drops all the way into cart basket)
    _item4Drop = Tween<Offset>(
      begin: const Offset(-0.5, -7.2),
      end: const Offset(-0.10, 0.05),
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.50, 0.64, curve: Curves.easeInQuad),
      ),
    );
    _item4Scale = Tween<double>(begin: 1.8, end: 0.35).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.50, 0.64, curve: Curves.easeInQuad),
      ),
    );
    _item4Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 75),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.48, 0.64, curve: Curves.easeInOut),
      ),
    );

    // Asteroid #5: 🍇 Grapes (Drops all the way into cart basket)
    _item5Drop = Tween<Offset>(
      begin: const Offset(0.6, -7.8),
      end: const Offset(0.12, 0.05),
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.58, 0.72, curve: Curves.easeInQuad),
      ),
    );
    _item5Scale = Tween<double>(begin: 2.3, end: 0.35).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.58, 0.72, curve: Curves.easeInQuad),
      ),
    );
    _item5Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 75),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.56, 0.72, curve: Curves.easeInOut),
      ),
    );


    // STAGE 4: BRAND TYPOGRAPHY REVEAL (0.72 -> 0.95)
    _titleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.72, 0.90, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.72, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _taglineScale = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.82, 0.98, curve: Curves.easeOutBack),
    );

    _shimmerProgress = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Track haptic impact flags to trigger sound & vibration exactly once per drop
    final hapticTriggered = <int, bool>{
      1: false, // Item 1 (0.42)
      2: false, // Item 2 (0.49)
      3: false, // Item 3 (0.56)
      4: false, // Item 4 (0.64)
      5: false, // Item 5 (0.72)
    };

    _mainController.addListener(() {
      final val = _mainController.value;

      void triggerDropFeedback(int itemKey) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        hapticTriggered[itemKey] = true;
      }

      if (val >= 0.42 && !(hapticTriggered[1] ?? false)) triggerDropFeedback(1);
      if (val >= 0.49 && !(hapticTriggered[2] ?? false)) triggerDropFeedback(2);
      if (val >= 0.56 && !(hapticTriggered[3] ?? false)) triggerDropFeedback(3);
      if (val >= 0.64 && !(hapticTriggered[4] ?? false)) triggerDropFeedback(4);
      if (val >= 0.72 && !(hapticTriggered[5] ?? false)) triggerDropFeedback(5);
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          _tryNavigate();
        }
      }
    });
  }

  Future<void> _startFlow() async {
    _mainController.forward();
    await _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus();
    } catch (_) {
      // Auth check error fallback
    }
  }

  void _tryNavigate() {
    if (mounted) {
      final authProvider = context.read<AuthProvider>();
      final routeName = authProvider.isLoggedIn
          ? AppRoutes.mainNav
          : AppRoutes.login;
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _bentoFloatController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03140C),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Dynamic Electric Aurora Mesh Gradient Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _bgMeshProgress]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _AuroraExpressPainter(
                    pulseProgress: _pulseController.value,
                    meshProgress: _bgMeshProgress.value,
                  ),
                );
              },
            ),
          ),

          // 2. High-Energy Starburst Particles & Speed Burst Lines
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticleSpeedPainter(
                    progress: _particleController.value,
                  ),
                );
              },
            ),
          ),

          // 3. Central Stage: Jet Speed Cart & Asteroid Dropping Items
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Hero Interactive Box (360x360)
                  SizedBox(
                    width: 360,
                    height: 360,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Shockwave Radial Ring on Cart Jet Impact
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final shockScale = 1.0 + (_pulseController.value * 0.15);
                            final shockOpacity = (0.35 - (_pulseController.value * 0.35)).clamp(0.0, 1.0);
                            return Container(
                              width: 200 * shockScale,
                              height: 200 * shockScale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: shockOpacity),
                                  width: 2.5,
                                ),
                              ),
                            );
                          },
                        ),

                        // =======================================================
                        // MAIN JET SPEED CART HERO CONTAINER (Center Platform)
                        // =======================================================
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _mainController,
                            _cartJetSlide,
                            _cartScale,
                            _cartImpactBounce,
                          ]),
                          builder: (context, child) {
                            return SlideTransition(
                              position: _cartJetSlide,
                              child: Transform.translate(
                                offset: Offset(0, _cartImpactBounce.value),
                                child: ScaleTransition(
                                  scale: _cartScale,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // High-Speed Multi-Line Wind Trail Lines on Left of Cart
                                      FadeTransition(
                                        opacity: _jetTrailOpacity,
                                        child: SizedBox(
                                          width: 320,
                                          height: 140,
                                          child: CustomPaint(
                                            painter: _JetSpeedTrailPainter(),
                                          ),
                                        ),
                                      ),

                                      // ----------------------------------------------------
                                      // FALLING ASTEROID GROCERY ITEMS DROPPING INTO CART
                                      // Rendered BEHIND cart so they enter and get covered by cart
                                      // ----------------------------------------------------

                                      // Asteroid #1: 🍎 Red Apple Drop
                                      SlideTransition(
                                        position: _item1Drop,
                                        child: ScaleTransition(
                                          scale: _item1Scale,
                                          child: FadeTransition(
                                            opacity: _item1Opacity,
                                            child: _buildAsteroidEmoji(
                                              emoji: '🍎',
                                              flameColor: const Color(0xFFE53935),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Asteroid #2: 🥦 Broccoli Drop
                                      SlideTransition(
                                        position: _item2Drop,
                                        child: ScaleTransition(
                                          scale: _item2Scale,
                                          child: FadeTransition(
                                            opacity: _item2Opacity,
                                            child: _buildAsteroidEmoji(
                                              emoji: '🥦',
                                              flameColor: const Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Asteroid #3: 🥕 Carrot Drop
                                      SlideTransition(
                                        position: _item3Drop,
                                        child: ScaleTransition(
                                          scale: _item3Scale,
                                          child: FadeTransition(
                                            opacity: _item3Opacity,
                                            child: _buildAsteroidEmoji(
                                              emoji: '🥕',
                                              flameColor: const Color(0xFFFF6D00),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Asteroid #4: 🥑 Avocado Drop
                                      SlideTransition(
                                        position: _item4Drop,
                                        child: ScaleTransition(
                                          scale: _item4Scale,
                                          child: FadeTransition(
                                            opacity: _item4Opacity,
                                            child: _buildAsteroidEmoji(
                                              emoji: '🥑',
                                              flameColor: const Color(0xFF558B2F),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Asteroid #5: 🍇 Grapes Drop
                                      SlideTransition(
                                        position: _item5Drop,
                                        child: ScaleTransition(
                                          scale: _item5Scale,
                                          child: FadeTransition(
                                            opacity: _item5Opacity,
                                            child: _buildAsteroidEmoji(
                                              emoji: '🍇',
                                              flameColor: const Color(0xFF6A1B9A),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Main Hero Express Shopping Cart Badge (No logo image)
                                      Container(
                                        width: 170,
                                        height: 170,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF00E676),
                                              Color(0xFF00A344),
                                              Color(0xFF00796B),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00B259).withValues(alpha: 0.5),
                                              blurRadius: 36,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                                              blurRadius: 24,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.shopping_cart_rounded,
                                            size: 90,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 4. Kinetic Typography & Brand Identity Section
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        children: [
                          // Brand Name Logo Text with Dual Gradient
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Color(0xFFE8F5E9),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Cart',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.2,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.secondary,
                                    Color(0xFFFFB74D),
                                    Color(0xFFFFE082),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'IT',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.2,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Shimmer Express Speed Tagline Badge
                          ScaleTransition(
                            scale: _taglineScale,
                            child: AnimatedBuilder(
                              animation: _shimmerProgress,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.15),
                                        Colors.white.withValues(alpha: 0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.eco_rounded,
                                        size: 20,
                                        color: Color(0xFF81C784),
                                      ),
                                      const SizedBox(width: 8),
                                      ShaderMask(
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            stops: const [0.0, 0.4, 0.6, 1.0],
                                            colors: [
                                              Colors.white,
                                              const Color(0xFFFFF176),
                                              const Color(0xFF81C784),
                                              Colors.white,
                                            ],
                                          ).createShader(bounds);
                                        },
                                        child: const Text(
                                          'FRESH FRUITS & VEGGIES EXPRESS',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Bottom Spacing Anchor
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Helper widget to render falling asteroid produce item with raw floating emoji (no circle/background)
  Widget _buildAsteroidEmoji({
    required String emoji,
    required Color flameColor,
  }) {
    return Text(
      emoji,
      style: TextStyle(
        fontSize: 42,
        shadows: [
          Shadow(
            color: flameColor.withValues(alpha: 0.9),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for Deep Emerald Electric Aurora Mesh Background
class _AuroraExpressPainter extends CustomPainter {
  final double pulseProgress;
  final double meshProgress;

  const _AuroraExpressPainter({
    required this.pulseProgress,
    required this.meshProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base atmospheric dark green background
    final baseGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0B3820),
        Color(0xFF062213),
        Color(0xFF020D07),
      ],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = baseGradient);

    // Glowing Radial Mesh Blobs
    final center = Offset(size.width * 0.5, size.height * 0.42);

    // Blob 1: Emerald Primary Core Light
    final r1 = size.width * (0.7 + math.sin(pulseProgress * math.pi * 2) * 0.08);
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2E7D32).withValues(alpha: 0.35),
          const Color(0xFF2E7D32).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r1));
    canvas.drawCircle(center, r1, paint1);

    // Blob 2: Warm Accent Gold Solar Flare
    final flareCenter = Offset(
      size.width * (0.5 + math.cos(meshProgress * math.pi * 2) * 0.15),
      size.height * (0.38 + math.sin(meshProgress * math.pi * 2) * 0.1),
    );
    final r2 = size.width * 0.5;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9800).withValues(alpha: 0.22),
          const Color(0xFFFF9800).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: flareCenter, radius: r2));
    canvas.drawCircle(flareCenter, r2, paint2);
  }

  @override
  bool shouldRepaint(covariant _AuroraExpressPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.meshProgress != meshProgress;
  }
}

/// Custom Painter for Starburst Particles & Speed Burst Lines
class _ParticleSpeedPainter extends CustomPainter {
  final double progress;

  const _ParticleSpeedPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final random = math.Random(42); // Static seed for consistent visual positions

    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    // Draw 24 orbiting glowing particles
    for (int i = 0; i < 24; i++) {
      final baseAngle = (i * (2 * math.pi / 24));
      final speedFactor = 0.5 + random.nextDouble();
      final currentAngle = baseAngle + (progress * math.pi * 2 * speedFactor);

      final distance = size.width * (0.2 + random.nextDouble() * 0.4);
      final px = center.dx + math.cos(currentAngle) * distance;
      final py = center.dy + math.sin(currentAngle) * distance;

      final pSize = 1.5 + random.nextDouble() * 2.5;
      final alpha = (0.2 + math.sin((progress + i / 24) * math.pi * 2) * 0.6).clamp(0.0, 1.0);

      particlePaint.color = (i % 3 == 0)
          ? const Color(0xFFFFB74D).withValues(alpha: alpha)
          : Colors.white.withValues(alpha: alpha);

      canvas.drawCircle(Offset(px, py), pSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleSpeedPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Custom Painter for High-Speed Jet Wind Trails on Left of Cart
class _JetSpeedTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    final line1 = Path()
      ..moveTo(size.width * 0.0, centerY - 28)
      ..lineTo(size.width * 0.52, centerY - 28);

    final line2 = Path()
      ..moveTo(size.width * 0.08, centerY - 10)
      ..lineTo(size.width * 0.55, centerY - 10);

    final line3 = Path()
      ..moveTo(size.width * 0.02, centerY + 12)
      ..lineTo(size.width * 0.50, centerY + 12);

    final line4 = Path()
      ..moveTo(size.width * 0.15, centerY + 28)
      ..lineTo(size.width * 0.48, centerY + 28);

    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFFFF9800),
          Colors.white,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFF4CAF50),
          Colors.white,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(line1, paint1);
    canvas.drawPath(line2, paint2);
    canvas.drawPath(line3, paint1);
    canvas.drawPath(line4, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


