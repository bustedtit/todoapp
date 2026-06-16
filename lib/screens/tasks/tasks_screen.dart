// lib/screens/tasks/tasks_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bingo_widgets.dart';
import '../../providers/app_providers.dart';
import '../../models/task_model.dart';
import 'add_task_sheet.dart';
import 'edit_task_sheet.dart';

enum TaskFilter { all, today, overdue, starred, completed }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

// ─── Sky tint helper (same logic as shell) ────────────────────────────────────
Color _skyTint() {
  final h = DateTime.now().hour.toDouble();
  if (h < 5)  return const Color(0xFF9B8EC4);
  if (h < 7)  return const Color(0xFFD4785A);
  if (h < 9)  return const Color(0xFFE8A020);
  if (h < 12) return const Color(0xFF2D9E75);
  if (h < 15) return const Color(0xFF1A7A5E);
  if (h < 18) return const Color(0xFF5A7ABB);
  if (h < 20) return const Color(0xFFC4684A);
  return const Color(0xFF6B5EA8);
}

// ─── Header nature scenes by time ─────────────────────────────────────────────
class _SceneConfig {
  final List<Color> gradientColors;
  final String emoji;
  final String timeLabel;

  const _SceneConfig({
    required this.gradientColors,
    required this.emoji,
    required this.timeLabel,
  });
}

_SceneConfig _getScene() {
  final h = DateTime.now().hour;
  if (h < 5)  return const _SceneConfig(gradientColors: [Color(0xFF0D0B1E), Color(0xFF1C1A3A)], emoji: '🌙', timeLabel: 'Night');
  if (h < 7)  return const _SceneConfig(gradientColors: [Color(0xFF1A1035), Color(0xFFD4785A)], emoji: '🌄', timeLabel: 'Dawn');
  if (h < 9)  return const _SceneConfig(gradientColors: [Color(0xFFC8784A), Color(0xFFEED090)], emoji: '🌅', timeLabel: 'Sunrise');
  if (h < 12) return const _SceneConfig(gradientColors: [Color(0xFF1A7A5E), Color(0xFF4BBFA0)], emoji: '🌿', timeLabel: 'Morning');
  if (h < 15) return const _SceneConfig(gradientColors: [Color(0xFF1565A0), Color(0xFF5AAAE0)], emoji: '☀️', timeLabel: 'Midday');
  if (h < 18) return const _SceneConfig(gradientColors: [Color(0xFF2D6A8A), Color(0xFF7AB8D8)], emoji: '🌊', timeLabel: 'Afternoon');
  if (h < 20) return const _SceneConfig(gradientColors: [Color(0xFF7B3F6E), Color(0xFFD4885A)], emoji: '🌇', timeLabel: 'Dusk');
  return const _SceneConfig(gradientColors: [Color(0xFF1C1040), Color(0xFF3C2860)], emoji: '🌃', timeLabel: 'Evening');
}

// ─── Tasks Screen ─────────────────────────────────────────────────────────────
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _searchOpen = false;
  late AnimationController _headerController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(isDarkModeProvider);
    final allTasks  = ref.watch(tasksProvider);
    final filter    = ref.watch(taskFilterProvider);
    final query     = ref.watch(taskSearchQueryProvider);
    final scene     = _getScene();
    final tint      = _skyTint();

    List<Task> base = query.isEmpty
        ? allTasks
        : ref.read(tasksProvider.notifier).searchTasks(query);

    final now = DateTime.now();
    List<Task> filtered;
    switch (filter) {
      case TaskFilter.all:
        filtered = base;
        break;
      case TaskFilter.today:
        filtered = base.where((t) {
          if (t.dueDate == null) return false;
          final d = t.dueDate!;
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
        break;
      case TaskFilter.overdue:
        filtered = base.where((t) =>
            !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now)).toList();
        break;
      case TaskFilter.starred:
        filtered = base.where((t) => t.isStarred).toList();
        break;
      case TaskFilter.completed:
        filtered = base.where((t) => t.isCompleted).toList();
        break;
    }

    filtered.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.isStarred   != b.isStarred)   return a.isStarred   ? -1 : 1;
      return b.priority.index.compareTo(a.priority.index);
    });

    final completedCount = allTasks.where((t) => t.isCompleted).length;
    final overdueCount   = allTasks.where((t) => t.isOverdue).length;
    final total          = allTasks.length;
    final progress       = total == 0 ? 0.0 : completedCount / total;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0818) : const Color(0xFFF0F4F0),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Nature header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _headerController,
              builder: (_, __) {
                final pulse = 0.92 + _headerController.value * 0.08;
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: scene.gradientColors,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Floating orb
                      Positioned(
                        top: -30,
                        right: -20,
                        child: Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tint.withOpacity(0.12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: -30,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),

                      // Safe area padding + content
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Time label + search row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Text(scene.emoji,
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 7),
                                    Text(
                                      scene.timeLabel,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ]),
                                  Row(children: [
                                    _GlassIconBtn(
                                      icon: _searchOpen
                                          ? Icons.close_rounded
                                          : Icons.search_rounded,
                                      onTap: () {
                                        setState(() {
                                          _searchOpen = !_searchOpen;
                                          if (!_searchOpen) {
                                            _searchController.clear();
                                            ref.read(taskSearchQueryProvider.notifier).state = '';
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _GlassIconBtn(
                                      icon: Icons.add_rounded,
                                      accent: true,
                                      tint: tint,
                                      onTap: () => _showAddTask(context),
                                    ),
                                  ]),
                                ],
                              ),

                              const Spacer(),

                              // Title + overdue
                              Text(
                                'My Tasks',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Progress bar
                              Row(children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 4,
                                      backgroundColor: Colors.white.withOpacity(0.18),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          tint.withOpacity(0.9)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$completedCount / $total done',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ]),

                              if (overdueCount > 0) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: BingoColors.priorityHigh.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: BingoColors.priorityHigh.withOpacity(0.45),
                                        width: 0.8),
                                  ),
                                  child: Text(
                                    '⚠️  $overdueCount overdue',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Search bar ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              child: _searchOpen
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _NatureSearchBar(
                        controller: _searchController,
                        isDark: isDark,
                        tint: tint,
                        onChanged: (v) =>
                            ref.read(taskSearchQueryProvider.notifier).state = v,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: TaskFilter.values.map((f) {
                    final badge = f == TaskFilter.overdue && overdueCount > 0
                        ? overdueCount
                        : null;
                    return _NatureFilterChip(
                      label: f.label,
                      icon: f.icon,
                      isSelected: filter == f,
                      isDark: isDark,
                      tint: tint,
                      badge: badge,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(taskFilterProvider.notifier).state = f;
                      },
                    );
                  }).toList(),
                ),
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 350.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Task list ────────────────────────────────────────────────────
          filtered.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NatureEmptyState(
                    isSearch: _searchOpen,
                    isDark: isDark,
                    onAdd: () => _showAddTask(context),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filtered[index];
                        return _NatureTaskCard(
                          task: task,
                          isDark: isDark,
                          tint: tint,
                          onToggle: () {
                            HapticFeedback.lightImpact();
                            ref.read(tasksProvider.notifier).toggleComplete(task.id);
                          },
                          onStar: () => ref
                              .read(tasksProvider.notifier)
                              .toggleStar(task.id),
                          onDelete: () => ref
                              .read(tasksProvider.notifier)
                              .deleteTask(task.id),
                          onEdit: () => _showEditTask(context, task),
                        )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 40 + index * 50),
                              duration: 320.ms,
                            )
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              delay: Duration(milliseconds: 40 + index * 50),
                              duration: 320.ms,
                              curve: Curves.easeOut,
                            );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _showAddTask(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTaskSheet(),
      );

  void _showEditTask(BuildContext context, Task task) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditTaskSheet(task: task),
      );
}

// ─── Glass Icon Button ────────────────────────────────────────────────────────
class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final bool accent;
  final Color tint;
  final VoidCallback onTap;

  const _GlassIconBtn({
    required this.icon,
    this.accent = false,
    this.tint = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent
                  ? tint.withOpacity(0.30)
                  : Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: accent
                    ? tint.withOpacity(0.55)
                    : Colors.white.withOpacity(0.22),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ─── Nature Search Bar ────────────────────────────────────────────────────────
class _NatureSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color tint;
  final ValueChanged<String> onChanged;

  const _NatureSearchBar({
    required this.controller,
    required this.isDark,
    required this.tint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tint.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: true,
        style: TextStyle(
          color: isDark ? Colors.white : BingoColors.forestGreen,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : BingoColors.stone,
            fontSize: 15,
          ),
          prefixIcon: Icon(Icons.search_rounded,
              color: tint.withOpacity(0.7), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

// ─── Nature Filter Chip ───────────────────────────────────────────────────────
class _NatureFilterChip extends StatelessWidget {
  final String label, icon;
  final bool isSelected, isDark;
  final Color tint;
  final int? badge;
  final VoidCallback onTap;

  const _NatureFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.tint,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(right: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? tint.withOpacity(isDark ? 0.25 : 0.14)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? tint.withOpacity(0.55)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : BingoColors.pebble),
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? tint
                    : (isDark ? Colors.white54 : BingoColors.bark),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: BingoColors.priorityHigh.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: BingoColors.priorityHigh,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

// ─── Nature Task Card ─────────────────────────────────────────────────────────
class _NatureTaskCard extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color tint;
  final VoidCallback onToggle, onStar, onDelete, onEdit;

  const _NatureTaskCard({
    required this.task,
    required this.isDark,
    required this.tint,
    required this.onToggle,
    required this.onStar,
    required this.onDelete,
    required this.onEdit,
  });

  Color _priorityAccent() {
    switch (task.priority) {
      case Priority.high:   return BingoColors.priorityHigh;
      case Priority.medium: return BingoColors.midGreen;
      case Priority.low:    return BingoColors.mintGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done   = task.isCompleted;
    final accent = done ? BingoColors.emeraldGreen : _priorityAccent();

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: _swipeBg(
          Alignment.centerLeft, BingoColors.emeraldGreen, Icons.check_rounded),
      secondaryBackground: _swipeBg(
          Alignment.centerRight, BingoColors.priorityHigh, Icons.delete_outline_rounded),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onToggle();
          return false;
        } else {
          onDelete();
          return true;
        }
      },
      child: GestureDetector(
        onLongPress: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(done ? 0.04 : 0.07)
                : (done ? const Color(0xFFF8FAF8) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: done
                  ? BingoColors.emeraldGreen.withOpacity(0.20)
                  : accent.withOpacity(isDark ? 0.18 : 0.12),
              width: 1,
            ),
            // Left accent stripe via boxShadow trick — no gradient needed
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Priority stripe
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: done
                        ? BingoColors.emeraldGreen.withOpacity(0.40)
                        : accent.withOpacity(0.70),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: onToggle,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: done ? BingoColors.emeraldGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: done
                                    ? BingoColors.emeraldGreen
                                    : (isDark
                                        ? Colors.white.withOpacity(0.20)
                                        : BingoColors.pebble),
                                width: 2,
                              ),
                            ),
                            child: done
                                ? const Icon(Icons.check_rounded,
                                    size: 13, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 11),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      color: done
                                          ? (isDark
                                              ? Colors.white24
                                              : BingoColors.stone)
                                          : (isDark
                                              ? Colors.white.withOpacity(0.92)
                                              : BingoColors.forestGreen),
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: BingoColors.emeraldGreen.withOpacity(0.5),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                if (task.recurrence != Recurrence.none)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(Icons.repeat_rounded,
                                        size: 13,
                                        color: tint.withOpacity(0.55)),
                                  ),
                              ]),

                              if (task.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 3),
                                Text(
                                  task.description!,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.35)
                                        : BingoColors.stone,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: 9),

                              // Meta row
                              Row(children: [
                                _PriorityDot(priority: task.priority),
                                const SizedBox(width: 8),
                                if (task.dueDate != null) ...[
                                  _DueBadge(
                                    dueDate: task.dueDate!,
                                    isOverdue: task.isOverdue,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                ...task.tags.take(2).map((t) => Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: BingoTag(label: t, isDark: isDark),
                                    )),
                              ]),
                            ],
                          ),
                        ),

                        // Actions column
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: onStar,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  task.isStarred
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: task.isStarred
                                      ? BingoColors.softAmber
                                      : (isDark
                                          ? Colors.white.withOpacity(0.20)
                                          : BingoColors.pebble),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: onEdit,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(Icons.more_horiz_rounded,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.22)
                                        : BingoColors.pebble),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBg(AlignmentGeometry align, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25), width: 0.8),
      ),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// ─── Priority Dot ─────────────────────────────────────────────────────────────
class _PriorityDot extends StatelessWidget {
  final Priority priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (priority) {
      case Priority.high:
        color = BingoColors.priorityHigh;
        label = 'High';
        break;
      case Priority.medium:
        color = BingoColors.midGreen;
        label = 'Mid';
        break;
      case Priority.low:
        color = BingoColors.mintGreen;
        label = 'Low';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─── Due Badge ────────────────────────────────────────────────────────────────
class _DueBadge extends StatelessWidget {
  final DateTime dueDate;
  final bool isOverdue, isDark;

  const _DueBadge(
      {required this.dueDate, required this.isOverdue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isOverdue
        ? BingoColors.priorityHigh
        : (isDark ? Colors.white38 : BingoColors.stone);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.schedule_rounded, size: 11, color: color),
      const SizedBox(width: 3),
      Text(
        DateFormat('MMM d, h:mm a').format(dueDate),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ]);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _NatureEmptyState extends StatelessWidget {
  final bool isSearch, isDark;
  final VoidCallback onAdd;

  const _NatureEmptyState({
    required this.isSearch,
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSearch ? '🔍' : '🌱',
              style: const TextStyle(fontSize: 56),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 0.95,
                  end: 1.05,
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 18),
            Text(
              isSearch ? 'Nothing found' : 'Garden is clear',
              style: TextStyle(
                color: isDark ? Colors.white70 : BingoColors.forestGreen,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try different words'
                  : 'Plant your first seed — add a task and watch it grow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : BingoColors.stone,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (!isSearch) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    color: BingoColors.emeraldGreen,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: BingoColors.emeraldGreen.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌿', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('Plant a task',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
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

extension on TaskFilter {
  String get label {
    switch (this) {
      case TaskFilter.all:       return 'All';
      case TaskFilter.today:     return 'Today';
      case TaskFilter.overdue:   return 'Overdue';
      case TaskFilter.starred:   return 'Starred';
      case TaskFilter.completed: return 'Done';
    }
  }

  String get icon {
    switch (this) {
      case TaskFilter.all:       return '🌿';
      case TaskFilter.today:     return '☀️';
      case TaskFilter.overdue:   return '⚠️';
      case TaskFilter.starred:   return '⭐';
      case TaskFilter.completed: return '✅';
    }
  }
}