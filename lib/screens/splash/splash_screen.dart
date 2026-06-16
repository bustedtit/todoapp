// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bingo_widgets.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Auto-navigate after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1F14),
              Color(0xFF0D3320),
              Color(0xFF1A4731),
              Color(0xFF0D3320),
              Color(0xFF0A1F14),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: AnimatedLeafBackground(
          isDark: true,
          leafCount: 20,
          child: Stack(
            children: [
              // Light rays
              _buildLightRays(),

              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo icon
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                BingoColors.midGreen.withOpacity(0.3 +
                                    _glowController.value * 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BingoColors.midGreen,
                              BingoColors.leafGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: BingoColors.glowGreen.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🌿',
                            style: TextStyle(fontSize: 34),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 600.ms),

                    const SizedBox(height: 24),

                    // App name
                    Text(
                      'Bingo',
                      style: BingoTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 64,
                        letterSpacing: 2,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 800.ms)
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          delay: 400.ms,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'Stay calm. Stay organized. Grow every day.',
                      style: BingoTextStyles.tagline.copyWith(
                        color: BingoColors.softMint.withOpacity(0.8),
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 1000.ms, duration: 800.ms)
                        .slideY(
                          begin: 0.5,
                          end: 0,
                          delay: 1000.ms,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        ),
                  ],
                ),
              ),

              // Bottom loading dots
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: _buildLoadingDots(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightRays() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return CustomPaint(
            painter: _LightRayPainter(
              value: _glowController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: BingoColors.midGreen,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.4, 1.4),
              delay: Duration(milliseconds: i * 200),
              duration: 600.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.4, 1.4),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.easeInOut,
            );
      }),
    )
        .animate()
        .fadeIn(delay: 1500.ms, duration: 500.ms);
  }
}

class _LightRayPainter extends CustomPainter {
  final double value;
  _LightRayPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          BingoColors.midGreen.withOpacity(0.08 + value * 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.4),
        radius: size.width * 0.8,
      ));

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.4),
      size.width * 0.8,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LightRayPainter old) => old.value != value;
}
