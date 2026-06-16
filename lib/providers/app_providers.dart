// lib/providers/app_providers.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

// ─── Theme Provider ──────────────────────────────────────────────────────────

final isDarkModeProvider = StateProvider<bool>((ref) => false);

// ─── SharedPreferences ────────────────────────────────────────────────────────

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

// ─── Tasks Provider (with persistence) ───────────────────────────────────────

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier() : super([]) {
    _load();
  }

  static const _key = 'bingo_tasks';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
        return;
      }
    } catch (_) {}
    state = _sampleTasks();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(state.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  static List<Task> _sampleTasks() {
    return [
      Task(
        id: '1',
        title: 'Morning meditation',
        description: '15 minutes of mindful breathing',
        priority: Priority.high,
        status: TaskStatus.completed,
        dueDate: DateTime.now(),
        tags: ['wellness', 'morning'],
        isStarred: true,
      ),
      Task(
        id: '2',
        title: 'Water the plants',
        description: 'Check soil moisture before watering',
        priority: Priority.medium,
        status: TaskStatus.pending,
        dueDate: DateTime.now().add(const Duration(hours: 2)),
        tags: ['home'],
      ),
      Task(
        id: '3',
        title: 'Review project proposal',
        description: 'Add comments on the design section',
        priority: Priority.high,
        status: TaskStatus.inProgress,
        dueDate: DateTime.now().add(const Duration(hours: 4)),
        tags: ['work'],
        isStarred: true,
      ),
      Task(
        id: '4',
        title: 'Read 30 pages',
        description: 'Continue "The Alchemist"',
        priority: Priority.low,
        status: TaskStatus.pending,
        dueDate: DateTime.now().add(const Duration(hours: 6)),
        tags: ['personal', 'reading'],
      ),
      Task(
        id: '5',
        title: 'Evening walk in the park',
        priority: Priority.low,
        status: TaskStatus.pending,
        dueDate: DateTime.now().add(const Duration(hours: 8)),
        tags: ['wellness'],
      ),
    ];
  }

  void addTask(Task task) {
    state = [...state, task];
    _save();
  }

  void updateTask(Task task) {
    state = state.map((t) => t.id == task.id ? task : t).toList();
    _save();
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
    _save();
  }

  void reorderTasks(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    state = list;
    _save();
  }

  void toggleComplete(String id) {
    state = state.map((t) {
      if (t.id != id) return t;
      final newStatus =
          t.isCompleted ? TaskStatus.pending : TaskStatus.completed;
      return Task(
        id: t.id,
        title: t.title,
        description: t.description,
        priority: t.priority,
        status: newStatus,
        dueDate: t.dueDate,
        createdAt: t.createdAt,
        completedAt:
            newStatus == TaskStatus.completed ? DateTime.now() : null,
        tags: t.tags,
        isStarred: t.isStarred,
        recurrence: t.recurrence,
      );
    }).toList();
    _save();
  }

  void toggleStar(String id) {
    state = state.map((t) {
      if (t.id != id) return t;
      return Task(
        id: t.id,
        title: t.title,
        description: t.description,
        priority: t.priority,
        status: t.status,
        dueDate: t.dueDate,
        createdAt: t.createdAt,
        completedAt: t.completedAt,
        tags: t.tags,
        isStarred: !t.isStarred,
        recurrence: t.recurrence,
      );
    }).toList();
    _save();
  }

  void clearCompleted() {
    state = state.where((t) => !t.isCompleted).toList();
    _save();
  }

  List<Task> get todayTasks {
    final now = DateTime.now();
    return state.where((t) {
      if (t.dueDate == null) return false;
      final d = t.dueDate!;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<Task> get overdueTasks {
    final now = DateTime.now();
    return state.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      return t.dueDate!.isBefore(now);
    }).toList();
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return state;
    final q = query.toLowerCase();
    return state.where((t) {
      return t.title.toLowerCase().contains(q) ||
          (t.description?.toLowerCase().contains(q) ?? false) ||
          t.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  int get completedCount => state.where((t) => t.isCompleted).length;
  double get completionRate =>
      state.isEmpty ? 0 : completedCount / state.length;

  List<int> get weeklyCompletions {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return state.where((t) {
        if (t.completedAt == null) return false;
        final c = t.completedAt!;
        return c.year == day.year &&
            c.month == day.month &&
            c.day == day.day;
      }).length;
    });
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<Task>>((ref) => TasksNotifier());

// ─── Notes Provider (with persistence) ───────────────────────────────────────

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]) {
    _load();
  }

  static const _key = 'bingo_notes';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
        return;
      }
    } catch (_) {}
    state = _sampleNotes();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(state.map((n) => n.toJson()).toList()));
    } catch (_) {}
  }

  static List<Note> _sampleNotes() {
    return [
      Note(
        id: '1',
        title: 'Morning Reflections',
        content:
            'Today I woke up feeling grateful for the small things. The sound of birds outside, the warmth of morning light through the curtains...',
        isPinned: true,
        tags: ['journal', 'morning'],
        colorHex: '#D8F3DC',
      ),
      Note(
        id: '2',
        title: 'Project Ideas',
        content:
            'A few ideas I want to explore this quarter:\n\n1. Build a personal knowledge base\n2. Start a weekly reading habit\n3. Learn watercolor painting',
        tags: ['work', 'ideas'],
        colorHex: '#B7E4C7',
      ),
      Note(
        id: '3',
        title: 'Garden Notes',
        content:
            'The basil is thriving. Need to repot the monstera. Tomatoes should be ready by end of month.',
        isPinned: true,
        tags: ['home', 'garden'],
        colorHex: '#95D5B2',
      ),
      Note(
        id: '4',
        title: 'Book Quotes',
        content:
            '"It\'s the possibility of having a dream come true that makes life interesting." — Paulo Coelho',
        tags: ['reading', 'inspiration'],
        colorHex: '#FFDDD2',
      ),
    ];
  }

  void addNote(Note note) {
    state = [...state, note];
    _save();
  }

  void updateNote(Note note) {
    state = state.map((n) => n.id == note.id ? note : n).toList();
    _save();
  }

  void deleteNote(String id) {
    state = state.where((n) => n.id != id).toList();
    _save();
  }

  void togglePin(String id) {
    state = state.map((n) {
      if (n.id != id) return n;
      return Note(
        id: n.id,
        title: n.title,
        content: n.content,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
        folderId: n.folderId,
        tags: n.tags,
        isPinned: !n.isPinned,
        colorHex: n.colorHex,
        linkedTaskId: n.linkedTaskId,
      );
    }).toList();
    _save();
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return state;
    final q = query.toLowerCase();
    return state.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          n.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  List<Note> get pinnedNotes => state.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes => state.where((n) => !n.isPinned).toList();
}

final notesProvider =
    StateNotifierProvider<NotesNotifier, List<Note>>((ref) => NotesNotifier());

// ─── Streak Provider (with persistence) ──────────────────────────────────────

class StreakNotifier extends StateNotifier<int> {
  StreakNotifier() : super(0) {
    _load();
  }

  static const _key = 'bingo_streak';
  static const _lastKey = 'bingo_last_active';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streak = prefs.getInt(_key) ?? 0;
      final lastStr = prefs.getString(_lastKey);
      if (lastStr != null) {
        final last = DateTime.parse(lastStr);
        final now = DateTime.now();
        final diff = now.difference(last).inDays;
        if (diff == 0) {
          state = streak;
        } else if (diff == 1) {
          state = streak + 1;
          await _saveState(state);
        } else {
          state = 0;
          await _saveState(0);
        }
      } else {
        state = 1;
        await _saveState(1);
      }
    } catch (_) {
      state = 7;
    }
  }

  Future<void> _saveState(int s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, s);
      await prefs.setString(_lastKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  void recordActivity() {
    state = state + 1;
    _saveState(state);
  }
}

final streakProvider =
    StateNotifierProvider<StreakNotifier, int>((ref) => StreakNotifier());

// ─── Search Providers ─────────────────────────────────────────────────────────

final taskSearchQueryProvider = StateProvider<String>((ref) => '');
final noteSearchQueryProvider = StateProvider<String>((ref) => '');

// ─── Navigation Provider ──────────────────────────────────────────────────────

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

// ─── Onboarding (persistent) ──────────────────────────────────────────────────

const _kOnboardingKey = 'has_seen_onboarding';

// Reads from SharedPreferences — survives app restarts
final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingKey) ?? false;
});

// Call this when onboarding completes or is skipped
Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingKey, true);
}

// Still keeping this for page tracking within the onboarding flow
final onboardingPageProvider = StateProvider<int>((ref) => 0);