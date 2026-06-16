// lib/screens/shell.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/bingo_widgets.dart';

import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'notes/notes_screen.dart';
import 'stats/stats_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/add_task_sheet.dart';

// ─── Sky-reactive nav color provider ─────────────────────────────────────────
// Reads the current hour and returns a tint color for the nav bar border/glow
Color _skyNavTint() {
  final h = DateTime.now().hour.toDouble();
  if (h < 5)  return const Color(0xFF9B8EC4); // deep night — violet
  if (h < 7)  return const Color(0xFFD4785A); // dawn — amber rose
  if (h < 9)  return const Color(0xFFFFD080); // sunrise — warm gold
  if (h < 12) return const Color(0xFF5AAAE0); // morning — sky blue
  if (h < 15) return const Color(0xFF2D9E75); // midday — emerald
  if (h < 18) return const Color(0xFF7898D0); // afternoon — slate blue
  if (h < 20) return const Color(0xFFD4885A); // dusk — terracotta
  return const Color(0xFF6B5EA8);              // night — indigo
}

// ─── App Shell ────────────────────────────────────────────────────────────────
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  // Focus removed from list — clean indices: 0 Home, 1 Tasks, 2 Notes, 3 Stats, 4 Settings
  static const _screens = [
    HomeScreen(),
    TasksScreen(),
    NotesScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx    = ref.watch(selectedNavIndexProvider);
    final isDark = ref.watch(isDarkModeProvider);

    final showFab = idx <= 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, // let content bleed under nav bar for frosted effect
      body: IndexedStack(
        index: idx,
        children: _screens,
      ),
      bottomNavigationBar: _NatureNavBar(
        currentIndex: idx,
        isDark: isDark,
      ),
      floatingActionButton: showFab
          ? _NatureFAB(
              onAddTask: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddTaskSheet(),
              ),
              onAddNote: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddNoteSheet(),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── Nav items config ─────────────────────────────────────────────────────────
class _NavConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const _NavConfig({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}

const _navItems = [
  _NavConfig(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
    index: 0,
  ),
  _NavConfig(
    icon: Icons.checklist_outlined,
    activeIcon: Icons.checklist_rounded,
    label: 'Tasks',
    index: 1,
  ),
  _NavConfig(
    icon: Icons.note_alt_outlined,
    activeIcon: Icons.note_alt_rounded,
    label: 'Notes',
    index: 2,
  ),
  _NavConfig(
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    label: 'Stats',
    index: 3,
  ),
  _NavConfig(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'More',
    index: 4,
  ),
];

// ─── Nature Nav Bar ───────────────────────────────────────────────────────────
class _NatureNavBar extends ConsumerStatefulWidget {
  final int currentIndex;
  final bool isDark;

  const _NatureNavBar({
    required this.currentIndex,
    required this.isDark,
  });

  @override
  ConsumerState<_NatureNavBar> createState() => _NatureNavBarState();
}

class _NatureNavBarState extends ConsumerState<_NatureNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skyTint = _skyNavTint();
    final bottom  = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (_, child) {
          final glowOpacity = 0.06 + _glowController.value * 0.08;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: skyTint.withOpacity(0.28),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: skyTint.withOpacity(glowOpacity),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF0D0B1E).withOpacity(0.78)
                        : Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _navItems.map((item) {
            final isActive = widget.currentIndex == item.index;
            return _NavPill(
              config: item,
              isActive: isActive,
              isDark: widget.isDark,
              skyTint: _skyNavTint(),
              onTap: () {
                _hapticNav(item.index, widget.currentIndex);
                ref.read(selectedNavIndexProvider.notifier).state = item.index;
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _hapticNav(int next, int current) {
    if (next == current) return;
    // Deeper haptic when going home, lighter for others
    if (next == 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }
}

// ─── Nav Pill ─────────────────────────────────────────────────────────────────
class _NavPill extends StatefulWidget {
  final _NavConfig config;
  final bool isActive;
  final bool isDark;
  final Color skyTint;
  final VoidCallback onTap;

  const _NavPill({
    required this.config,
    required this.isActive,
    required this.isDark,
    required this.skyTint,
    required this.onTap,
  });

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.05), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 16 : 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.skyTint.withOpacity(widget.isDark ? 0.22 : 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: widget.isActive
                ? Border.all(
                    color: widget.skyTint.withOpacity(0.35),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isActive
                      ? widget.config.activeIcon
                      : widget.config.icon,
                  key: ValueKey(widget.isActive),
                  size: 22,
                  color: widget.isActive
                      ? widget.skyTint
                      : (widget.isDark
                          ? Colors.white.withOpacity(0.35)
                          : BingoColors.stone.withOpacity(0.55)),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                child: widget.isActive
                    ? Row(children: [
                        const SizedBox(width: 7),
                        Text(
                          widget.config.label,
                          style: TextStyle(
                            color: widget.skyTint,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nature FAB ───────────────────────────────────────────────────────────────
class _NatureFAB extends StatefulWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddNote;

  const _NatureFAB({
    required this.onAddTask,
    required this.onAddNote,
  });

  @override
  State<_NatureFAB> createState() => _NatureFABState();
}

class _NatureFABState extends State<_NatureFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _doAction(VoidCallback action) {
    _toggle();
    Future.delayed(const Duration(milliseconds: 150), action);
  }

  @override
  Widget build(BuildContext context) {
    final skyTint = _skyNavTint();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sub-actions
        AnimatedBuilder(
          animation: _expandController,
          builder: (_, __) {
            final v = CurvedAnimation(
                parent: _expandController, curve: Curves.easeOutBack).value;
            return Opacity(
              opacity: _expandController.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.7 + v * 0.3,
                alignment: Alignment.bottomCenter,
                child: Column(
                  children: [
                    _FabAction(
                      label: 'New Task',
                      emoji: '✅',
                      color: BingoColors.emeraldGreen,
                      onTap: () => _doAction(widget.onAddTask),
                    ),
                    const SizedBox(height: 10),
                    _FabAction(
                      label: 'New Note',
                      emoji: '🌿',
                      color: BingoColors.midGreen,
                      onTap: () => _doAction(widget.onAddNote),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            );
          },
        ),

        // Main FAB — leaf shape
        GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _expandController,
            builder: (_, child) {
              return Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      skyTint,
                      Color.lerp(skyTint, BingoColors.emeraldGreen, 0.6)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: skyTint.withOpacity(0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.125 : 0.0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    child: const Text('🌿', style: TextStyle(fontSize: 26)),
                  ),
                ),
              );
            },
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),
      ],
    );
  }
}

class _FabAction extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _FabAction({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}