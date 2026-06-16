// lib/screens/home/home_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/task_model.dart';

// ─── SKY THEME ────────────────────────────────────────────────────────────────
class _SkyTheme {
  final Color skyTop;
  final Color skyBottom;
  final Color mountainFar;
  final Color mountainMid;
  final Color mountainNear;
  final Color celestialColor;
  final Color cardBg;          // garden section below scene
  final bool  showStars;
  final bool  isMoon;
  final String phase;          // "Dawn", "Sunrise", etc.
  final String greeting;
  final String gardenMessage;
  final List<String> plantEmojis;

  const _SkyTheme({
    required this.skyTop,
    required this.skyBottom,
    required this.mountainFar,
    required this.mountainMid,
    required this.mountainNear,
    required this.celestialColor,
    required this.cardBg,
    required this.showStars,
    required this.isMoon,
    required this.phase,
    required this.greeting,
    required this.gardenMessage,
    required this.plantEmojis,
  });
}

// ─── CELESTIAL PAINTER ───────────────────────────────────────────────────────
class _CelestialPainter extends CustomPainter {
  final double progress; // 0 = left horizon, 0.5 = peak, 1 = right horizon
  final Color  color;
  final bool   isMoon;
  final double opacity;

  const _CelestialPainter({
    required this.progress,
    required this.color,
    required this.isMoon,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final cx = size.width / 2;
    final cy = size.height + 20;
    final rx = size.width  * 0.45;
    final ry = size.height * 0.95;
    final angle = pi - progress * pi;
    final x = cx + rx * cos(angle);
    final y = cy - ry * sin(angle).abs();

    final paint = Paint()..color = color.withOpacity(opacity)..style = PaintingStyle.fill;

    if (isMoon) {
      canvas.drawCircle(Offset(x, y), 16, paint);
      canvas.drawCircle(
        Offset(x + 7, y - 2), 12,
        Paint()..color = const Color(0xFF1A1035).withOpacity(opacity)..style = PaintingStyle.fill,
      );
    } else {
      canvas.drawCircle(Offset(x, y), 22, paint);
      canvas.drawCircle(Offset(x, y), 34,
          Paint()..color = color.withOpacity(opacity * 0.18)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 48,
          Paint()..color = color.withOpacity(opacity * 0.07)..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_CelestialPainter o) =>
      o.progress != progress || o.color != color || o.opacity != opacity || o.isMoon != isMoon;
}

// ─── MOUNTAIN PAINTER ────────────────────────────────────────────────────────
class _MountainPainter extends CustomPainter {
  final Color far;
  final Color mid;
  final Color near;

  const _MountainPainter({required this.far, required this.mid, required this.near});

  void _range(Canvas c, Size s, Color col, List<Offset> pts) {
    final path = Path()..moveTo(0, s.height);
    for (final p in pts) path.lineTo(p.dx, p.dy);
    path..lineTo(s.width, s.height)..close();
    c.drawPath(path, Paint()..color = col..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Far — tallest, most distant
    _range(canvas, size, far, [
      Offset(0,        h * 0.55),
      Offset(w * 0.10, h * 0.20),
      Offset(w * 0.22, h * 0.38),
      Offset(w * 0.35, h * 0.10),
      Offset(w * 0.48, h * 0.30),
      Offset(w * 0.60, h * 0.08),
      Offset(w * 0.72, h * 0.25),
      Offset(w * 0.84, h * 0.18),
      Offset(w,        h * 0.45),
    ]);

    // Mid
    _range(canvas, size, mid, [
      Offset(0,        h * 0.68),
      Offset(w * 0.12, h * 0.42),
      Offset(w * 0.25, h * 0.55),
      Offset(w * 0.38, h * 0.33),
      Offset(w * 0.52, h * 0.48),
      Offset(w * 0.65, h * 0.30),
      Offset(w * 0.77, h * 0.44),
      Offset(w * 0.90, h * 0.36),
      Offset(w,        h * 0.58),
    ]);

    // Near — lowest, darkest, smoothest curves
    _range(canvas, size, near, [
      Offset(0,        h * 0.80),
      Offset(w * 0.15, h * 0.58),
      Offset(w * 0.32, h * 0.70),
      Offset(w * 0.50, h * 0.54),
      Offset(w * 0.68, h * 0.66),
      Offset(w * 0.84, h * 0.56),
      Offset(w,        h * 0.72),
    ]);
  }

  @override
  bool shouldRepaint(_MountainPainter o) =>
      o.far != far || o.mid != mid || o.near != near;
}

// ─── STAR FIELD ───────────────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  _StarField({super.key});

  final _stars = List.generate(50, (i) {
    final r = Random(i * 6271 + 77);
    return (x: r.nextDouble(), y: r.nextDouble(), size: 1.0 + r.nextDouble() * 2.0, op: 0.2 + r.nextDouble() * 0.8);
  });

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    return Stack(
      children: _stars.map((st) => Positioned(
        left: s.width  * st.x,
        top:  s.height * st.y * 0.85, // keep stars in sky portion
        child: Opacity(
          opacity: st.op,
          child: Container(
            width: st.size, height: st.size,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      )).toList(),
    );
  }
}

// ─── HOME SCREEN ─────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _gardenController;
  late AnimationController _skyController;

  int        _previousCompleted = 0;
  _SkyTheme? _currentSky;
  _SkyTheme? _previousSky;
  bool       _isRefreshing = false;
  final      _refreshKey = GlobalKey<RefreshIndicatorState>();

  // ── helpers ──────────────────────────────────────────────────────────────
  static Color _c(String hex) =>
      Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  static Color _l(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  // ── sky engine ────────────────────────────────────────────────────────────
  _SkyTheme _buildSky() {
    final now = DateTime.now();
    final t   = now.hour + now.minute / 60.0;

    // Night 0–5
    if (t < 5.0) return _SkyTheme(
      skyTop: _c('#0D0B1E'), skyBottom: _c('#1C1A3A'),
      mountainFar: _c('#1A1830'), mountainMid: _c('#141228'), mountainNear: _c('#0E0C1E'),
      celestialColor: _c('#D0D8F0'), cardBg: _c('#12101E'),
      showStars: true, isMoon: true,
      phase: 'Night', greeting: 'Good night',
      gardenMessage: 'Night is deep. Sweet dreams.',
      plantEmojis: ['🌙', '🌲', '🌿'],
    );

    // Dawn 5–7
    if (t < 7.0) {
      final p = (t - 5.0) / 2.0;
      return _SkyTheme(
        skyTop:    _l(_c('#1A1035'), _c('#D4785A'), p),
        skyBottom: _l(_c('#3A1545'), _c('#F0B87A'), p),
        mountainFar:  _l(_c('#2A1C40'), _c('#7A3A25'), p),
        mountainMid:  _l(_c('#1E1430'), _c('#5C2A1A'), p),
        mountainNear: _l(_c('#14102A'), _c('#3C1C10'), p),
        celestialColor: _l(_c('#C0CCDD'), _c('#FFD080'), p),
        cardBg: _l(_c('#1A1035'), _c('#2A1810'), p),
        showStars: p < 0.5, isMoon: p < 0.3,
        phase: 'Dawn', greeting: 'Rise & shine',
        gardenMessage: 'Dawn is breaking. Seeds awakening!',
        plantEmojis: ['🌸', '🌳', '🌱'],
      );
    }

    // Sunrise 7–9
    if (t < 9.0) return _SkyTheme(
      skyTop: _c('#C8784A'), skyBottom: _c('#EED090'),
      mountainFar: _c('#6B5040'), mountainMid: _c('#524030'), mountainNear: _c('#3A2C20'),
      celestialColor: _c('#FFE890'),
      cardBg: _c('#2A1E10'),
      showStars: false, isMoon: false,
      phase: 'Sunrise', greeting: 'Good morning',
      gardenMessage: 'Sunrise! Your garden wakes up!',
      plantEmojis: ['🌸', '🌳', '🌿'],
    );

    // Morning 9–12
    if (t < 12.0) return _SkyTheme(
      skyTop: _c('#B8D8C8'), skyBottom: _c('#D8EED8'),
      mountainFar: _c('#5A7A60'), mountainMid: _c('#486050'), mountainNear: _c('#364840'),
      celestialColor: _c('#FFFBE8'),
      cardBg: _c('#2A3A2A'),
      showStars: false, isMoon: false,
      phase: 'Morning', greeting: 'Good morning',
      gardenMessage: 'Fresh morning! Time to bloom!',
      plantEmojis: ['🌸', '🌳', '🌿'],
    );

    // Midday 12–15
    if (t < 15.0) return _SkyTheme(
      skyTop: _c('#5AAAE0'), skyBottom: _c('#A0D4F0'),
      mountainFar: _c('#2A6A5A'), mountainMid: _c('#1E5048'), mountainNear: _c('#143830'),
      celestialColor: _c('#FFFCE0'),
      cardBg: _c('#1A3028'),
      showStars: false, isMoon: false,
      phase: 'Midday', greeting: 'Good afternoon',
      gardenMessage: 'Peak bloom! You are crushing it!',
      plantEmojis: ['🌸', '🌳', '🌿'],
    );

    // Afternoon 15–17.5
    if (t < 17.5) return _SkyTheme(
      skyTop: _c('#7898D0'), skyBottom: _c('#B0CCE8'),
      mountainFar: _c('#3A5070'), mountainMid: _c('#2C3C58'), mountainNear: _c('#1E2840'),
      celestialColor: _c('#FFF5C0'),
      cardBg: _c('#1A2030'),
      showStars: false, isMoon: false,
      phase: 'Afternoon', greeting: 'Good afternoon',
      gardenMessage: 'Halfway there! Keep going!',
      plantEmojis: ['🌸', '🌳', '🌿'],
    );

    // Dusk 17.5–19
    if (t < 19.0) {
      final p = (t - 17.5) / 1.5;
      return _SkyTheme(
        skyTop:    _l(_c('#7B3F6E'), _c('#1A0E35'), p),
        skyBottom: _l(_c('#D4885A'), _c('#5A3A7A'), p),
        mountainFar:  _l(_c('#5A2A50'), _c('#1E0A30'), p),
        mountainMid:  _l(_c('#3E1C3A'), _c('#160828'), p),
        mountainNear: _l(_c('#2A1228'), _c('#0E0518'), p),
        celestialColor: _l(_c('#FFD080'), _c('#D0C0FF'), p),
        cardBg: _l(_c('#2A1020'), _c('#0A0818'), p),
        showStars: p > 0.5, isMoon: p > 0.7,
        phase: 'Dusk', greeting: 'Good evening',
        gardenMessage: 'Dusk falls. Almost full bloom!',
        plantEmojis: ['🌸', '🌳', '🌙'],
      );
    }

    // Evening 19–21
    if (t < 21.0) return _SkyTheme(
      skyTop: _c('#1C1040'), skyBottom: _c('#3C2860'),
      mountainFar: _c('#1E0A38'), mountainMid: _c('#160828'), mountainNear: _c('#0E0518'),
      celestialColor: _c('#D8C8FF'),
      cardBg: _c('#0A0818'),
      showStars: true, isMoon: true,
      phase: 'Evening', greeting: 'Good evening',
      gardenMessage: 'Evening glow. Wind down time.',
      plantEmojis: ['🌙', '🌲', '🍃'],
    );

    // Late night 21–24
    return _SkyTheme(
      skyTop: _c('#090C1C'), skyBottom: _c('#10183A'),
      mountainFar: _c('#0C1020'), mountainMid: _c('#090C18'), mountainNear: _c('#060810'),
      celestialColor: _c('#A8B8D8'),
      cardBg: _c('#080C18'),
      showStars: true, isMoon: true,
      phase: 'Night', greeting: 'Good night',
      gardenMessage: 'Night is deep. Sweet dreams.',
      plantEmojis: ['🌙', '🌲', '🌿'],
    );
  }

  double _celestialProgress() {
    final t = DateTime.now().hour + DateTime.now().minute / 60.0;
    if (t >= 6 && t <= 18) return (t - 6.0) / 12.0;
    if (t > 18) return (t - 18.0) / 12.0 * 0.5;
    return 0.5 + t / 6.0 * 0.5;
  }

  double _celestialOpacity() {
    final t = DateTime.now().hour + DateTime.now().minute / 60.0;
    if (t >= 5.5 && t < 6.5) return (t - 5.5).clamp(0.0, 1.0);
    if (t >= 17.5 && t < 18.5) return (1.0 - (t - 17.5)).clamp(0.0, 1.0);
    return 1.0;
  }

  Color _lerpColor(Color Function(_SkyTheme) pick) {
    final prev = _previousSky;
    final cur  = _currentSky!;
    if (prev == null) return pick(cur);
    return Color.lerp(pick(prev), pick(cur), _skyController.value)!;
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _gardenController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _skyController = AnimationController(
        duration: const Duration(seconds: 2), vsync: this);
    _currentSky = _buildSky();

    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 1));
      if (!mounted) return false;
      setState(() { _previousSky = _currentSky; _currentSky = _buildSky(); });
      _skyController.forward(from: 0.0);
      return true;
    });
  }

  @override
  void dispose() {
    _gardenController.dispose();
    _skyController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      HapticFeedback.mediumImpact();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Garden refreshed!'),
        backgroundColor: BingoColors.emeraldGreen,
        duration: Duration(seconds: 1),
      ));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(isDarkModeProvider);
    final tasks    = ref.watch(tasksProvider);
    final notes    = ref.watch(notesProvider);
    final notifier = ref.read(tasksProvider.notifier);

    final todayTasks     = notifier.todayTasks;
    final completedToday = todayTasks.where((t) => t.isCompleted).length;
    final totalToday     = todayTasks.length;
    final completionRate = totalToday == 0 ? 0.0 : completedToday / totalToday;
    final now            = DateTime.now();

    if (completedToday != _previousCompleted) {
      _previousCompleted = completedToday;
      _gardenController.forward(from: 0.0);
      HapticFeedback.heavyImpact();
    }

    final sky         = _currentSky!;
    final celProgress = _celestialProgress();
    final celOpacity  = _celestialOpacity();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0818) : const Color(0xFFF4F4F4),
      body: RefreshIndicator(
        key:             _refreshKey,
        onRefresh:       _onRefresh,
        color:           BingoColors.emeraldGreen,
        backgroundColor: isDark ? BingoColors.darkCanopy : Colors.white,
        strokeWidth:     2.5,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ── SCENE CARD (sky + mountains) ──────────────────────────────
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _skyController,
                builder: (_, __) {
                  final skyTop    = _lerpColor((s) => s.skyTop);
                  final skyBot    = _lerpColor((s) => s.skyBottom);
                  final mtnFar    = _lerpColor((s) => s.mountainFar);
                  final mtnMid    = _lerpColor((s) => s.mountainMid);
                  final mtnNear   = _lerpColor((s) => s.mountainNear);
                  final celColor  = _lerpColor((s) => s.celestialColor);

                  return Container(
                    height: 260,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end:   Alignment.bottomCenter,
                        colors: [skyTop, skyBot],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Stars
                        if (sky.showStars)
                          AnimatedOpacity(
                            duration: const Duration(seconds: 2),
                            opacity: sky.showStars ? 1.0 : 0.0,
                            child: _StarField(),
                          ),

                        // Sun / Moon
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CelestialPainter(
                              progress: celProgress,
                              color:    celColor,
                              isMoon:   sky.isMoon,
                              opacity:  celOpacity,
                            ),
                          ),
                        ),

                        // Mountains — sit at bottom of scene card
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          height: 130,
                          child: CustomPaint(
                            painter: _MountainPainter(
                              far:  mtnFar,
                              mid:  mtnMid,
                              near: mtnNear,
                            ),
                          ),
                        ),

                        // Phase label top-left
                        Positioned(
                          top: 44, left: 20,
                          child: Text(
                            sky.phase,
                            style: TextStyle(
                              color:      Colors.white.withOpacity(0.85),
                              fontSize:   14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        // Time badge top-right
                        Positioned(
                          top: 38, right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              DateFormat('h:mm a').format(now),
                              style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── GARDEN SECTION (below scene, plain bg) ────────────────────
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _skyController,
                builder: (_, __) {
                  final cardBg = _lerpColor((s) => s.cardBg);
                  return Container(
                    color: cardBg,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Magic Garden',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'YAYAYAYA',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Plants row — 3 emoji icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: sky.plantEmojis.map((emoji) {
                            return AnimatedBuilder(
                              animation: _gardenController,
                              builder: (_, __) => Transform.scale(
                                scale: 1.0 + _gardenController.value * 0.12,
                                child: Text(emoji,
                                  style: const TextStyle(fontSize: 42)),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Message pill
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            sky.gardenMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.90),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── WHITE BODY SECTION ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF12101E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting + title + done pill
                    Text(sky.greeting,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : BingoColors.stone,
                        fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('Your Garden',
                        style: TextStyle(
                          color: isDark ? Colors.white : BingoColors.forestGreen,
                          fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: completionRate),
                        duration: 600.ms,
                        builder: (_, v, __) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: BingoColors.emeraldGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${(v * 100).toInt()}% done',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    // Date
                    Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 12,
                          color: isDark ? Colors.white38 : BingoColors.stone),
                      const SizedBox(width: 6),
                      Text(DateFormat('EEEE, MMMM d').format(now),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : BingoColors.stone,
                          fontSize: 12, fontWeight: FontWeight.w400)),
                    ]),
                  ],
                ),
              ),
            ),

            // ── STATS ROW ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? const Color(0xFF12101E) : Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(children: [
                  Expanded(child: _StatCard(label: 'Tasks',  value: '${tasks.length}',  icon: Icons.checklist_rounded,           color: BingoColors.leafGreen, isDark: isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Notes',  value: '${notes.length}',  icon: Icons.note_alt_rounded,             color: BingoColors.midGreen,  isDark: isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Streak', value: '7',                icon: Icons.local_fire_department_rounded, color: BingoColors.mintGreen, isDark: isDark)),
                ]),
              ),
            ),

            // ── TASK LIST ─────────────────────────────────────────────────
            if (todayTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Container(
                  color: isDark ? const Color(0xFF12101E) : Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Today's Tasks",
                        style: TextStyle(
                          color: isDark ? Colors.white : BingoColors.forestGreen,
                          fontSize: 16, fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () {},
                        child: Text('View All',
                          style: TextStyle(color: BingoColors.midGreen, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = todayTasks[index];
                    return Container(
                      color: isDark ? const Color(0xFF12101E) : Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _TaskCard(
                        task: task, isDark: isDark,
                        onToggle: () {
                          HapticFeedback.lightImpact();
                          ref.read(tasksProvider.notifier).toggleComplete(task.id);
                        },
                      ),
                    );
                  },
                  childCount: todayTasks.length.clamp(0, 5),
                ),
              ),
            ],

            // ── NOTES ─────────────────────────────────────────────────────
            if (notes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Container(
                  color: isDark ? const Color(0xFF12101E) : Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Row(children: [
                    Icon(Icons.auto_awesome_rounded, size: 18,
                        color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen),
                    const SizedBox(width: 8),
                    Text('Recent Notes',
                      style: TextStyle(
                        color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: isDark ? const Color(0xFF12101E) : Colors.white,
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: notes.length.clamp(0, 6),
                    itemBuilder: (_, i) => _NoteCard(
                      note: notes.toList()[i], isDark: isDark),
                  ),
                ),
              ),
            ] else
              SliverToBoxAdapter(
                child: Container(
                  color: isDark ? const Color(0xFF12101E) : Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: _EmptyState(isDark: isDark),
                ),
              ),

            SliverToBoxAdapter(
              child: Container(
                color: isDark ? const Color(0xFF12101E) : Colors.white,
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label; final String value;
  final IconData icon; final Color color; final bool isDark;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.20), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(
          color: isDark ? Colors.white : BingoColors.forestGreen,
          fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(
          color: isDark ? Colors.white38 : BingoColors.stone,
          fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── TASK CARD ────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final Task task; final bool isDark; final VoidCallback onToggle;
  const _TaskCard({required this.task, required this.isDark, required this.onToggle});

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:   return BingoColors.priorityHigh;
      case Priority.medium: return BingoColors.midGreen;
      case Priority.low:    return BingoColors.mintGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(done ? 0.04 : 0.07)
              : (done ? const Color(0xFFF8FAF8) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done
                ? BingoColors.emeraldGreen.withOpacity(0.30)
                : (isDark ? Colors.white12 : const Color(0xFFE8EEE8)),
            width: 1,
          ),
        ),
        child: Row(children: [
          // Checkbox
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: done ? BingoColors.emeraldGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: done ? BingoColors.emeraldGreen
                    : (isDark ? Colors.white30 : const Color(0xFFBBCCBB)),
                width: 2),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title,
                style: TextStyle(
                  color: done
                      ? (isDark ? Colors.white30 : BingoColors.stone)
                      : (isDark ? Colors.white : BingoColors.forestGreen),
                  decoration: done ? TextDecoration.lineThrough : null,
                  fontSize: 14, fontWeight: FontWeight.w600)),
              if (task.dueDate != null) ...[
                const SizedBox(height: 3),
                Text(DateFormat('h:mm a').format(task.dueDate!),
                  style: TextStyle(
                    color: task.isOverdue ? BingoColors.priorityHigh
                        : (isDark ? Colors.white30 : BingoColors.stone),
                    fontSize: 11)),
              ],
            ]),
          ),
          // Priority badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _priorityColor(task.priority).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(
              task.priority.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: _priorityColor(task.priority)),
            )),
          ),
        ]),
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BingoColors.emeraldGreen.withOpacity(0.18)),
      ),
      child: Column(children: [
        const Text('🌱', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 14),
        Text('Your garden is resting',
          style: TextStyle(
            color: isDark ? Colors.white70 : BingoColors.forestGreen,
            fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Add a note to get started!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white38 : BingoColors.stone, fontSize: 13)),
      ]),
    );
  }
}

// ─── NOTE CARD ────────────────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Note note; final bool isDark;
  const _NoteCard({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color col;
    try {
      col = Color(int.parse('FF${note.colorHex.replaceAll('#', '')}', radix: 16));
    } catch (_) { col = BingoColors.mistGreen; }

    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? col.withOpacity(0.14) : col.withOpacity(0.50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? col.withOpacity(0.28) : col.withOpacity(0.45), width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (note.isPinned)
            Icon(Icons.push_pin_rounded, size: 11,
                color: isDark ? BingoColors.mintGreen : BingoColors.leafGreen),
          const Spacer(),
          Text(DateFormat('MMM d').format(note.updatedAt),
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : BingoColors.bark.withOpacity(0.65))),
        ]),
        const SizedBox(height: 10),
        Text(note.title,
          style: TextStyle(
            color: isDark ? Colors.white : BingoColors.forestGreen,
            fontSize: 13, fontWeight: FontWeight.w700),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 5),
        Text(note.content.isEmpty ? 'Empty note' : note.content,
          style: TextStyle(
            color: isDark ? Colors.white38 : BingoColors.bark.withOpacity(0.65),
            fontSize: 11),
          maxLines: 3, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─── PROFILE BUTTON ───────────────────────────────────────────────────────────
class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF52B788), Color(0xFF2D6A4F)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: Text('🌿', style: TextStyle(fontSize: 24))),
    );
  }
}