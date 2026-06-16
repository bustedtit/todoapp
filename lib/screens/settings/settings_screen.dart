// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';

// ─── Providers ────────────────────────────────────────────────────────────────
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final dailyReminderTimeProvider =
    StateProvider<TimeOfDay>((ref) => const TimeOfDay(hour: 8, minute: 0));
final soundEnabledProvider = StateProvider<bool>((ref) => true);
final hapticEnabledProvider = StateProvider<bool>((ref) => true);
final defaultPriorityProvider = StateProvider<String>((ref) => 'medium');
final showCompletedProvider = StateProvider<bool>((ref) => true);
final streakGoalProvider = StateProvider<int>((ref) => 7);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final notifications = ref.watch(notificationsEnabledProvider);
    final sound = ref.watch(soundEnabledProvider);
    final haptic = ref.watch(hapticEnabledProvider);
    final showCompleted = ref.watch(showCompletedProvider);
    final reminderTime = ref.watch(dailyReminderTimeProvider);

    final bg = isDark ? BingoColors.darkForest : BingoColors.cream;
    final cardBg = isDark ? BingoColors.darkCanopy : Colors.white;
    final textColor = isDark ? BingoColors.paleGreen : BingoColors.forestGreen;
    final subColor = isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.stone;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 24),
                child: Text(
                  'Settings',
                  style: BingoTextStyles.displaySmall.copyWith(color: textColor),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

              // Profile card (premium gradient)
              _ProfileCard(isDark: isDark, cardBg: cardBg, textColor: textColor, subColor: subColor),
              const SizedBox(height: 28),

              // Notifications
              _SectionHeader(title: 'Notifications', isDark: isDark),
              _SettingsCard(
                isDark: isDark,
                cardBg: cardBg,
                children: [
                  _SwitchTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Task reminders & updates',
                    value: notifications,
                    onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).state = v,
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  _Divider(isDark: isDark),
                  _SwitchTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound Effects',
                    subtitle: 'Subtle nature sounds on actions',
                    value: sound,
                    onChanged: (v) => ref.read(soundEnabledProvider.notifier).state = v,
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  _Divider(isDark: isDark),
                  _SwitchTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    subtitle: 'Gentle vibration on interactions',
                    value: haptic,
                    onChanged: (v) => ref.read(hapticEnabledProvider.notifier).state = v,
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  if (notifications) ...[
                    _Divider(isDark: isDark),
                    _TappableTile(
                      icon: Icons.alarm_rounded,
                      title: 'Daily Reminder',
                      subtitle: reminderTime.format(context),
                      isDark: isDark,
                      textColor: textColor,
                      subColor: subColor,
                      onTap: () async {
                        if (ref.read(hapticEnabledProvider)) HapticFeedback.lightImpact();
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: reminderTime,
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: BingoColors.emeraldGreen),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          ref.read(dailyReminderTimeProvider.notifier).state = picked;
                        }
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Tasks
              _SectionHeader(title: 'Tasks', isDark: isDark),
              _SettingsCard(
                isDark: isDark,
                cardBg: cardBg,
                children: [
                  _SwitchTile(
                    icon: Icons.visibility_rounded,
                    title: 'Show Completed',
                    subtitle: 'Display finished tasks in list',
                    value: showCompleted,
                    onChanged: (v) => ref.read(showCompletedProvider.notifier).state = v,
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  _Divider(isDark: isDark),
                  _TappableTile(
                    icon: Icons.flag_rounded,
                    title: 'Default Priority',
                    subtitle: ref.watch(defaultPriorityProvider).capitalize(),
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () => _pickPriority(context, ref, isDark),
                  ),
                  _Divider(isDark: isDark),
                  _TappableTile(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Streak Goal',
                    subtitle: '${ref.watch(streakGoalProvider)} days',
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () => _pickStreakGoal(context, ref, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Data & Privacy
              _SectionHeader(title: 'Data & Privacy', isDark: isDark),
              _SettingsCard(
                isDark: isDark,
                cardBg: cardBg,
                children: [
                  _TappableTile(
                    icon: Icons.ios_share_rounded,
                    title: 'Export Data',
                    subtitle: 'Save tasks & notes as JSON',
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () => _showExportDialog(context, isDark),
                  ),
                  _Divider(isDark: isDark),
                  _TappableTile(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Clear Completed Tasks',
                    subtitle: 'Remove all done tasks',
                    isDark: isDark,
                    textColor: BingoColors.priorityHigh,
                    subColor: subColor,
                    onTap: () => _confirmClear(context, isDark, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Follow the Creator
              _SectionHeader(title: 'Follow the Creator', isDark: isDark),
              _SettingsCard(
                isDark: isDark,
                cardBg: cardBg,
                children: [
                  _CreatorTile(
                    icon: Icons.link,
                    title: 'Instagram',
                    subtitle: '@bustedtit',
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () => _openInstagram('bustedtit'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 💖 SPECIAL THANKS SECTION (NEW)
              _SectionHeader(title: '💖 Special Thanks', isDark: isDark),
              _SettingsCard(
                isDark: isDark,
                cardBg: cardBg,
                children: [
                  _SpecialThanksTile(
                    icon: Icons.favorite_rounded,
                    title: 'Say Thank You',
                    subtitle: 'To someone special ❤️',
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () => _showLoveMessage(context, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // About
              _SectionHeader(title: 'About', isDark: isDark),
              _SettingsCard(
                isDark: isDark,
                cardBg: cardBg,
                children: [
                  _InfoTile(
                    icon: Icons.eco_rounded,
                    title: 'Bingo',
                    subtitle: 'Version 1.0.0',
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  _Divider(isDark: isDark),
                  _TappableTile(
                    icon: Icons.star_rounded,
                    title: 'Rate on App Store',
                    subtitle: 'Tell others about Bingo',
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () {},
                  ),
                  _Divider(isDark: isDark),
                  _TappableTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () {},
                  ),
                  _Divider(isDark: isDark),
                  _TappableTile(
                    icon: Icons.description_rounded,
                    title: 'Terms of Service',
                    subtitle: 'Usage terms & conditions',
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text('🌿 Bingo', style: BingoTextStyles.tagline.copyWith(color: subColor.withOpacity(0.6))),
                    const SizedBox(height: 4),
                    Text('Stay calm. Stay organized. Grow every day.',
                        style: BingoTextStyles.bodySmall.copyWith(color: subColor.withOpacity(0.5))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _pickPriority(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Default Priority',
        options: const ['low', 'medium', 'high'],
        selected: ref.read(defaultPriorityProvider),
        isDark: isDark,
        onSelect: (v) => ref.read(defaultPriorityProvider.notifier).state = v,
      ),
    );
  }

  void _pickStreakGoal(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Streak Goal',
        options: const ['3', '5', '7', '14', '21', '30'],
        selected: '${ref.read(streakGoalProvider)}',
        isDark: isDark,
        onSelect: (v) => ref.read(streakGoalProvider.notifier).state = int.parse(v),
      ),
    );
  }

  void _showExportDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? BingoColors.darkCanopy : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Export Data', style: BingoTextStyles.headlineMedium.copyWith(color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen)),
        content: Text('Your tasks and notes will be exported as a JSON file.', style: BingoTextStyles.bodyMedium.copyWith(color: isDark ? BingoColors.mintGreen : BingoColors.bark)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: BingoTextStyles.labelLarge.copyWith(color: BingoColors.stone))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: BingoColors.emeraldGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text('Export', style: BingoTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, bool isDark, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? BingoColors.darkCanopy : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Clear Completed?', style: BingoTextStyles.headlineMedium.copyWith(color: BingoColors.priorityHigh)),
        content: Text('This will permanently delete all completed tasks.', style: BingoTextStyles.bodyMedium.copyWith(color: isDark ? BingoColors.mintGreen : BingoColors.bark)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: BingoTextStyles.labelLarge.copyWith(color: BingoColors.stone))),
          ElevatedButton(
            onPressed: () {
              final notifier = ref.read(tasksProvider.notifier);
              final completed = ref.read(tasksProvider).where((t) => t.isCompleted).map((t) => t.id).toList();
              for (final id in completed) notifier.deleteTask(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: BingoColors.priorityHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text('Clear', style: BingoTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLoveMessage(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D6A4F), Color(0xFF52B788), Color(0xFF1B4332)],
            ),
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated heart
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Heartbeat animation text
              const Text(
                '💖✨💖',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 16),
              
              // The love message
              Text(
                'wanna thanks love of my life toshani for always supporting me. Really love you from my entire soul',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),
              
              // Floating hearts
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('❤️', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Text('💖', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Text('❤️', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 16),
              
              // Close button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInstagram(String username) async {
    final instagramUrl = Uri.parse('https://www.instagram.com/$username/');
    final instagramAppUrl = Uri.parse('instagram://user?username=$username');
    
    try {
      if (await canLaunchUrl(instagramAppUrl)) {
        await launchUrl(instagramAppUrl);
      } else {
        await launchUrl(instagramUrl);
      }
    } catch (e) {
      await launchUrl(instagramUrl);
    }
  }
}

// ─── Premium Profile Card ─────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg, textColor, subColor;
  const _ProfileCard({required this.isDark, required this.cardBg, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF52B788)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: BingoColors.emeraldGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(22)),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Garden Keeper', style: BingoTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Growing since today 🌱', style: BingoTextStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(30)),
            child: Text('wassup bitch', style: BingoTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: BingoTextStyles.labelSmall.copyWith(color: BingoColors.midGreen, letterSpacing: 1.2, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.cardBg, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: isDark ? Colors.black12 : BingoColors.leafGreen.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value, isDark;
  final Color textColor, subColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.onChanged,
  });

@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 22, color: BingoColors.emeraldGreen),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BingoTextStyles.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: BingoTextStyles.bodySmall.copyWith(color: subColor)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: BingoColors.emeraldGreen,
        ),
      ],
    ),
  );

  }
}

class _TappableTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  final Color textColor, subColor;
  final VoidCallback onTap;

  const _TappableTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isDark) HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: BingoColors.emeraldGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BingoTextStyles.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: BingoTextStyles.bodySmall.copyWith(color: subColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subColor, size: 22),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  final Color textColor, subColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: BingoColors.emeraldGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: BingoTextStyles.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.w600)),
          ),
          Text(subtitle, style: BingoTextStyles.bodySmall.copyWith(color: subColor)),
        ],
      ),
    );
  }
}

// Creator Tile for Instagram
class _CreatorTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  final Color textColor, subColor;
  final VoidCallback onTap;

  const _CreatorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isDark) HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BingoTextStyles.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: BingoTextStyles.bodySmall.copyWith(color: subColor)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: subColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// 🆕 SPECIAL THANKS TILE
class _SpecialThanksTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  final Color textColor, subColor;
  final VoidCallback onTap;

  const _SpecialThanksTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isDark) HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E), Color(0xFFFFB5B5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: BingoTextStyles.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const Text('💖', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: BingoTextStyles.bodySmall.copyWith(color: subColor)),
                ],
              ),
            ),
            Icon(Icons.favorite_rounded, color: BingoColors.priorityHigh, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 54,
      endIndent: 16,
      color: isDark ? BingoColors.darkFern : BingoColors.pebble.withOpacity(0.4),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  final String title, selected;
  final List<String> options;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? BingoColors.darkCanopy : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 44, height: 5, margin: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: BingoColors.pebble, borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Text(widget.title, style: BingoTextStyles.headlineMedium.copyWith(color: widget.isDark ? BingoColors.paleGreen : BingoColors.forestGreen)),
          ),
          ...widget.options.map((opt) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(opt.capitalize(), style: BingoTextStyles.bodyLarge.copyWith(color: widget.isDark ? BingoColors.paleGreen : BingoColors.forestGreen, fontWeight: FontWeight.w500)),
                trailing: _selected == opt ? Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: BingoColors.emeraldGreen, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 16, color: Colors.white)) : null,
                onTap: () {
                  setState(() => _selected = opt);
                  widget.onSelect(opt);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}