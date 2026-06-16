// lib/widgets/bingo_widgets.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/task_model.dart';

// ─── Floating Leaf Background ─────────────────────────────────────────────────

class FloatingLeaf {
  double x, y, size, opacity, speed, angle;
  FloatingLeaf({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.angle,
  });
}

class LeafBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  final List<FloatingLeaf> leaves;

  LeafBackgroundPainter({
    required this.animationValue,
    required this.isDark,
    required this.leaves,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final leaf in leaves) {
      final dy = (leaf.y + animationValue * leaf.speed * 50) % size.height;
      final dx = leaf.x + math.sin(animationValue * 2 * math.pi + leaf.angle) * 15;

      final color = isDark
          ? BingoColors.glowGreen.withOpacity(leaf.opacity * 0.4)
          : BingoColors.leafGreen.withOpacity(leaf.opacity * 0.15);

      paint.color = color;
      _drawLeaf(canvas, paint, Offset(dx, dy), leaf.size,
          animationValue * 2 * math.pi * leaf.speed);
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint, Offset center, double size, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    path.moveTo(0, -size);
    path.cubicTo(size * 0.8, -size * 0.5, size * 0.8, size * 0.5, 0, size);
    path.cubicTo(-size * 0.8, size * 0.5, -size * 0.8, -size * 0.5, 0, -size);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LeafBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class AnimatedLeafBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final int leafCount;

  const AnimatedLeafBackground({
    super.key,
    required this.child,
    this.isDark = false,
    this.leafCount = 12,
  });

  @override
  State<AnimatedLeafBackground> createState() => _AnimatedLeafBackgroundState();
}

class _AnimatedLeafBackgroundState extends State<AnimatedLeafBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<FloatingLeaf> _leaves;
  final _rand = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _leaves = List.generate(
      widget.leafCount,
      (i) => FloatingLeaf(
        x: _rand.nextDouble() * 400,
        y: _rand.nextDouble() * 800,
        size: 6 + _rand.nextDouble() * 12,
        opacity: 0.3 + _rand.nextDouble() * 0.7,
        speed: 0.3 + _rand.nextDouble() * 0.7,
        angle: _rand.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: LeafBackgroundPainter(
            animationValue: _controller.value,
            isDark: widget.isDark,
            leaves: _leaves,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── Glass Card ───────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isDark;
  final Color? borderColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.isDark = false,
    this.borderColor,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BingoDecorations.glassCard(
          borderColor: borderColor,
          radius: borderRadius,
          isDark: isDark,
        ),
        child: child,
      ),
    );
  }
}

// ─── Priority Badge ───────────────────────────────────────────────────────────

class PriorityBadge extends StatelessWidget {
  final Priority priority;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  Color get _color {
    switch (priority) {
      case Priority.high:
        return BingoColors.priorityHigh;
      case Priority.medium:
        return BingoColors.priorityMed;
      case Priority.low:
        return BingoColors.priorityLow;
    }
  }

  String get _label {
    switch (priority) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Mid';
      case Priority.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              _label,
              style: BingoTextStyles.labelSmall.copyWith(
                color: _color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tag Chip ─────────────────────────────────────────────────────────────────

class BingoTag extends StatelessWidget {
  final String label;
  final bool isDark;

  const BingoTag({super.key, required this.label, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? BingoColors.midGreen.withOpacity(0.15)
            : BingoColors.mistGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$label',
        style: BingoTextStyles.labelSmall.copyWith(
          color: isDark ? BingoColors.mintGreen : BingoColors.leafGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Bingo FAB ────────────────────────────────────────────────────────────────

class BingoFAB extends StatefulWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddNote;

  const BingoFAB({
    super.key,
    required this.onAddTask,
    required this.onAddNote,
  });

  @override
  State<BingoFAB> createState() => _BingoFABState();
}

class _BingoFABState extends State<BingoFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini actions
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: _isOpen ? null : 0,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniAction(
                label: 'New Task',
                icon: Icons.check_circle_outline_rounded,
                onTap: () {
                  _toggle();
                  widget.onAddTask();
                },
              ).animate().slideX(begin: 0.5, duration: 200.ms).fadeIn(),
              const SizedBox(height: 10),
              _MiniAction(
                label: 'New Note',
                icon: Icons.edit_note_rounded,
                onTap: () {
                  _toggle();
                  widget.onAddNote();
                },
              ).animate().slideX(begin: 0.5, duration: 250.ms).fadeIn(),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Main FAB
        GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * math.pi / 4,
                child: child,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: BingoColors.forestMist,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: BingoColors.emeraldGreen.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: BingoColors.emeraldGreen.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              label,
              style: BingoTextStyles.labelLarge.copyWith(
                color: BingoColors.forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BingoColors.mistGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: BingoColors.emeraldGreen, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Ring ────────────────────────────────────────────────────────────

class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final bool isDark;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.child,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: isDark
                ? BingoColors.darkFern
                : BingoColors.paleGreen,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? BingoColors.glowGreen : BingoColors.emeraldGreen,
            ),
            strokeCap: StrokeCap.round,
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class BingoEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onAction;

  const BingoEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            )
                .animate(onPlay: (c) => c.repeat())
                .moveY(
                  begin: 0,
                  end: -10,
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                )
                .then()
                .moveY(
                  begin: -10,
                  end: 0,
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 20),
            Text(
              title,
              style: BingoTextStyles.headlineMedium.copyWith(
                color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: BingoTextStyles.bodyMedium.copyWith(
                color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.stone,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BingoColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonLabel!,
                  style: BingoTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
