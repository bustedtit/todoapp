// lib/screens/focus/focus_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/task_model.dart';

enum FocusMode { pomodoro, shortBreak, longBreak }
enum TimerState { idle, running, paused, done }

const _pomoDuration = Duration(minutes: 25);
const _shortBreakDuration = Duration(minutes: 5);
const _longBreakDuration = Duration(minutes: 15);

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with TickerProviderStateMixin {
  FocusMode _mode = FocusMode.pomodoro;
  TimerState _timerState = TimerState.idle;
  Timer? _timer;
  Duration _remaining = _pomoDuration;
  int _completedPomos = 0;
  Task? _activeTask;
  int _sessionsToday = 0; // number of completed pomodoros today

  late AnimationController _breatheController;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _remaining = _durationForMode(_mode);
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadTodaySessions();
  }

  void _loadTodaySessions() {
    // In a real app, load from shared_preferences or a provider.
    // For demo, we'll keep it in memory.
    // We'll increment when a pomodoro finishes.
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breatheController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Duration _durationForMode(FocusMode mode) {
    switch (mode) {
      case FocusMode.pomodoro:
        return _pomoDuration;
      case FocusMode.shortBreak:
        return _shortBreakDuration;
      case FocusMode.longBreak:
        return _longBreakDuration;
    }
  }

  void _setMode(FocusMode mode) {
    if (_mode == mode) return;
    _timer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      _remaining = _durationForMode(mode);
      _timerState = TimerState.idle;
    });
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() => _timerState = TimerState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        _complete();
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    setState(() => _timerState = TimerState.paused);
  }

  void _reset() {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    setState(() {
      _remaining = _durationForMode(_mode);
      _timerState = TimerState.idle;
    });
  }

  void _complete() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    _playCompletionSound();
    if (_mode == FocusMode.pomodoro) {
      _completedPomos++;
      _sessionsToday++;
      // Optionally, mark linked task as partially completed? (future)
    }
    _ringController.forward(from: 0);
    setState(() {
      _remaining = Duration.zero;
      _timerState = TimerState.done;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _timerState == TimerState.done) {
        if (_mode == FocusMode.pomodoro) {
          _setMode(FocusMode.shortBreak);
        } else {
          _setMode(FocusMode.pomodoro);
        }
      }
    });
  }

  void _playCompletionSound() {
    // Use a simple beep – can be extended with an audio player package later.
    // For now, just haptic (already done) – we'll add a system beep.
    SystemSound.play(SystemSoundType.click);
  }

  double get _progress {
    final total = _durationForMode(_mode).inSeconds;
    final elapsed = total - _remaining.inSeconds;
    return total == 0 ? 0 : elapsed / total;
  }

  String get _timeLabel {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _modeColor {
    switch (_mode) {
      case FocusMode.pomodoro:
        return BingoColors.emeraldGreen;
      case FocusMode.shortBreak:
        return BingoColors.midGreen;
      case FocusMode.longBreak:
        return BingoColors.mintGreen;
    }
  }

  String get _totalFocusTimeToday {
    final minutes = _sessionsToday * 25;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours h ${mins} min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final tasks = ref.watch(tasksProvider).where((t) => !t.isCompleted).toList();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? BingoColors.darkGarden
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD8F3DC), Color(0xFFB7E4C7), Color(0xFF95D5B2)],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView( // FIX overflow
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Header with stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _modeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(Icons.timer_rounded, color: _modeColor, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Focus',
                            style: BingoTextStyles.headlineLarge.copyWith(
                              color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      // Sessions today pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? BingoColors.darkCanopy : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _modeColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.today_rounded, size: 14, color: BingoColors.emeraldGreen),
                            const SizedBox(width: 6),
                            Text(
                              '$_sessionsToday / 4',
                              style: BingoTextStyles.labelSmall.copyWith(
                                color: _modeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row (focus time, pomos count)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatChip(
                        icon: Icons.timer_rounded,
                        label: 'Today',
                        value: _totalFocusTimeToday,
                        color: _modeColor,
                        isDark: isDark,
                      ),
                      _StatChip(
                        icon: Icons.flag_rounded,
                        label: 'Sessions',
                        value: '$_completedPomos',
                        color: _modeColor,
                        isDark: isDark,
                      ),
                      if (_activeTask != null)
                        _StatChip(
                          icon: Icons.task_alt_rounded,
                          label: 'Task',
                          value: _activeTask!.title.length > 12
                              ? '${_activeTask!.title.substring(0, 12)}...'
                              : _activeTask!.title,
                          color: _modeColor,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Mode tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? BingoColors.darkCanopy : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _modeColor.withOpacity(0.15), width: 0.5),
                  ),
                  child: Row(
                    children: FocusMode.values.map((m) {
                      final isActive = _mode == m;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _setMode(m),
                          child: AnimatedContainer(
                            duration: 240.ms,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? _modeColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m.label,
                              textAlign: TextAlign.center,
                              style: BingoTextStyles.labelLarge.copyWith(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : (isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.bark),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Timer ring – responsive size
                Center(
                  child: AnimatedBuilder(
                    animation: _breatheController,
                    builder: (context, child) {
                      final breatheScale = _timerState == TimerState.running
                          ? 1.0 + _breatheController.value * 0.015
                          : 1.0;
                      return Transform.scale(
                        scale: breatheScale,
                        child: Container(
                          width: size.width * 0.65, // Smaller for safety
                          height: size.width * 0.65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? BingoColors.darkCanopy : Colors.white.withOpacity(0.5),
                            boxShadow: [
                              BoxShadow(
                                color: _modeColor.withOpacity(0.25),
                                blurRadius: 48,
                                spreadRadius: 12,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size(size.width * 0.65, size.width * 0.65),
                                painter: _TimerArcPainter(
                                  progress: _progress,
                                  color: _modeColor,
                                  isDark: isDark,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: 200.ms,
                                    child: Text(
                                      _timeLabel,
                                      key: ValueKey(_timeLabel),
                                      style: BingoTextStyles.displayLarge.copyWith(
                                        color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                                        fontSize: 56,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _modeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      _timerState == TimerState.done
                                          ? '🎉 Complete!'
                                          : _timerState == TimerState.running
                                              ? 'Stay focused'
                                              : _timerState == TimerState.paused
                                                  ? 'Paused'
                                                  : _mode.subtitle,
                                      style: BingoTextStyles.labelLarge.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _modeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleBtn(
                        icon: Icons.refresh_rounded,
                        size: 56,
                        bgColor: isDark ? BingoColors.darkCanopy : Colors.white,
                        iconColor: _modeColor,
                        onTap: _reset,
                      ),
                      const SizedBox(width: 28),
                      GestureDetector(
                        onTap: _timerState == TimerState.running ? _pause : _start,
                        child: AnimatedContainer(
                          duration: 240.ms,
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_modeColor, _modeColor.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _modeColor.withOpacity(0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _timerState == TimerState.running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      _CircleBtn(
                        icon: Icons.skip_next_rounded,
                        size: 56,
                        bgColor: isDark ? BingoColors.darkCanopy : Colors.white,
                        iconColor: _modeColor,
                        onTap: _complete,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Task picker (enhanced)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: GestureDetector(
                    onTap: tasks.isEmpty ? null : () => _pickTask(context, tasks, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? BingoColors.darkCanopy : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: _modeColor.withOpacity(0.2), width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: _modeColor.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _modeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.task_alt_rounded, color: _modeColor, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeTask?.title ?? 'Link a task',
                                  style: BingoTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _activeTask != null
                                        ? (isDark ? BingoColors.paleGreen : BingoColors.forestGreen)
                                        : (isDark ? BingoColors.mintGreen.withOpacity(0.5) : BingoColors.stone),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_activeTask != null)
                                  Text(
                                    'Linked to focus • $_sessionsToday pomos completed for this task',
                                    style: BingoTextStyles.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.stone,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: _modeColor, size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickTask(BuildContext context, List<Task> tasks, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? BingoColors.darkCanopy : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? BingoColors.darkFern : BingoColors.pebble,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Focus on',
                style: BingoTextStyles.headlineMedium.copyWith(
                  color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            LimitedBox(
              maxHeight: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final t = tasks[index];
                  final isSelected = _activeTask?.id == t.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.priority == Priority.high
                            ? BingoColors.priorityHigh
                            : t.priority == Priority.medium
                                ? BingoColors.priorityMed
                                : BingoColors.priorityLow,
                      ),
                    ),
                    title: Text(
                      t.title,
                      style: BingoTextStyles.bodyLarge.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _modeColor : (isDark ? BingoColors.paleGreen : BingoColors.forestGreen),
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _modeColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_rounded, color: _modeColor, size: 18),
                          )
                        : null,
                    onTap: () {
                      setState(() => _activeTask = t);
                      Navigator.pop(context);
                      HapticFeedback.selectionClick();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Small stat chip
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? BingoColors.darkCanopy : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: BingoTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: BingoTextStyles.bodySmall.copyWith(
              color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.stone,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timer Arc Painter (unchanged) ───────────────────────────────────────────
class _TimerArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _TimerArcPainter({required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final trackPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    if (progress == 0) return;
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi * progress,
      colors: [color.withOpacity(0.5), color, color],
      tileMode: TileMode.clamp,
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    final progressPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerArcPainter old) => old.progress != progress || old.color != color;
}

// ─── Circle Button ───────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.size,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 160.ms,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: iconColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: size * 0.44),
        ),
      ),
    );
  }
}

extension on FocusMode {
  String get label {
    switch (this) {
      case FocusMode.pomodoro:
        return 'Focus';
      case FocusMode.shortBreak:
        return 'Break';
      case FocusMode.longBreak:
        return 'Rest';
    }
  }

  String get subtitle {
    switch (this) {
      case FocusMode.pomodoro:
        return '25 min deep work';
      case FocusMode.shortBreak:
        return '5 min recharge';
      case FocusMode.longBreak:
        return '15 min restore';
    }
  }
}