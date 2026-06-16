// lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/bingo_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      emoji: '🌿',
      title: 'Welcome to\nBingo',
      subtitle: 'A calm space to organize your life and grow every day.',
      buttonLabel: 'Start Growing',
      accentColor: BingoColors.emeraldGreen,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A4731), Color(0xFF2D6A4F)],
      ),
    ),
    OnboardingData(
      emoji: '✅',
      title: 'Organize\nyour tasks',
      subtitle: 'Create tasks instantly, set priorities, and track your daily progress with ease.',
      buttonLabel: 'Next',
      accentColor: BingoColors.leafGreen,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
      ),
    ),
    OnboardingData(
      emoji: '📝',
      title: 'Capture your\nthoughts',
      subtitle: 'Write distraction-free notes, organize with tags, and link notes directly to your tasks.',
      buttonLabel: 'Next',
      accentColor: BingoColors.midGreen,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF40916C), Color(0xFF52B788)],
      ),
    ),
    OnboardingData(
      emoji: '🌱',
      title: 'Grow every\nday',
      subtitle: 'Track streaks, see your progress, and build powerful productivity habits over time.',
      buttonLabel: 'Enter Bingo',
      accentColor: BingoColors.mintGreen,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF52B788), Color(0xFF74C69D)],
      ),
      isLast: true,
    ),
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background (lightweight)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Container(
              key: ValueKey(_currentPage),
              decoration: BoxDecoration(
                gradient: _pages[_currentPage].gradient,
              ),
            ),
          ),

          // Subtle leaf pattern (performance‑friendly)
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: LeafPainter(),
                ),
              ),
            ),
          ),

          // Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _OnboardingPage(
                data: _pages[index],
                isActive: _currentPage == index,
                onNext: _nextPage,
                currentPage: _currentPage,
                totalPages: _pages.length,
              );
            },
          ),

          // Premium Skip button
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onComplete();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                  ),
                  child: Text(
                    'Skip',
                    style: BingoTextStyles.labelLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isActive;
  final VoidCallback onNext;
  final int currentPage;
  final int totalPages;

  const _OnboardingPage({
    required this.data,
    required this.isActive,
    required this.onNext,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // Premium Emoji Container with glow & floating animation
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: child,
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        data.accentColor.withOpacity(0.2),
                        data.accentColor.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: data.accentColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: data.accentColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: AlwaysStoppedAnimation(0),
                      builder: (context, _) {
                        return Text(
                          data.emoji,
                          style: const TextStyle(fontSize: 64),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ).animate(target: isActive ? 1 : 0).fadeIn(duration: 400.ms),

            const SizedBox(height: 56),

            // Premium Title
            Text(
              data.title,
              style: BingoTextStyles.displayMedium.copyWith(
                color: Colors.white,
                height: 1.15,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ).animate(target: isActive ? 1 : 0).fadeIn(
              delay: 120.ms,
              duration: 500.ms,
            ).slideX(
              begin: 0.15,
              end: 0,
              delay: 120.ms,
              duration: 500.ms,
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 20),

            // Premium Subtitle
            Text(
              data.subtitle,
              style: BingoTextStyles.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.8),
                height: 1.55,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ).animate(target: isActive ? 1 : 0).fadeIn(
              delay: 220.ms,
              duration: 500.ms,
            ).slideX(
              begin: 0.15,
              end: 0,
              delay: 220.ms,
              duration: 500.ms,
              curve: Curves.easeOut,
            ),

            const Spacer(),

            // Premium Page Indicators (animated)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalPages,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: i == currentPage ? 28 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: i == currentPage
                          ? data.accentColor
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: i == currentPage
                          ? [
                              BoxShadow(
                                color: data.accentColor.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Premium CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: data.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                  shadowColor: data.accentColor.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.buttonLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      data.isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ).animate(target: isActive ? 1 : 0).fadeIn(
              delay: 320.ms,
              duration: 500.ms,
            ).slideY(
              begin: 0.3,
              end: 0,
              delay: 320.ms,
              duration: 500.ms,
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Lightweight leaf painter (performance‑optimised)
class LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 6 elegant leaves positioned asymmetrically
    final leaves = [
      Offset(40, 80),
      Offset(size.width - 70, 120),
      Offset(20, size.height - 180),
      Offset(size.width - 50, size.height - 280),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.7),
    ];

    for (var leaf in leaves) {
      final path = Path();
      path.moveTo(leaf.dx, leaf.dy);
      path.quadraticBezierTo(
        leaf.dx + 12,
        leaf.dy - 18,
        leaf.dx + 24,
        leaf.dy,
      );
      path.quadraticBezierTo(
        leaf.dx + 12,
        leaf.dy + 18,
        leaf.dx,
        leaf.dy,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color accentColor;
  final LinearGradient gradient; // elegant gradient per page
  final bool isLast;

  const OnboardingData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.accentColor,
    required this.gradient,
    this.isLast = false,
  });
}