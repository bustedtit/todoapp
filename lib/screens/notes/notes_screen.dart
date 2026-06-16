import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bingo_widgets.dart';
import '../../providers/app_providers.dart';
import '../../models/task_model.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final allNotes = ref.watch(notesProvider);
    
    final notes = _searchQuery.isEmpty
        ? allNotes
        : allNotes
            .where((n) =>
                n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                n.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                n.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();

    final pinned = notes.where((n) => n.isPinned).toList();
    final unpinned = notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: isDark ? BingoColors.darkForest : BingoColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animation
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_isSearching)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                          ),
                        ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: 300.ms,
                        child: _isSearching
                            ? SizedBox(
                                width: MediaQuery.of(context).size.width - 160,
                                child: TextField(
                                  key: const ValueKey('search'),
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  style: BingoTextStyles.bodyMedium.copyWith(
                                    color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search notes...',
                                    hintStyle: BingoTextStyles.bodyMedium.copyWith(
                                      color: isDark ? BingoColors.mintGreen.withOpacity(0.35) : BingoColors.stone,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              )
                            : Text(
                                'Notes',
                                key: const ValueKey('title'),
                                style: BingoTextStyles.displaySmall.copyWith(
                                  color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                                ),
                              ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!_isSearching)
                        IconButton(
                          onPressed: () => setState(() => _isSearching = true),
                          icon: Icon(
                            Icons.search_rounded,
                            color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                            size: 24,
                          ),
                        ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _showAddNote(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: BingoColors.forestMist,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: BingoColors.emeraldGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

            const SizedBox(height: 8),

            // Notes grid
            Expanded(
              child: notes.isEmpty
                  ? _buildEmptyState(isDark)
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        if (pinned.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              icon: Icons.push_pin_rounded,
                              title: 'PINNED',
                              isDark: isDark,
                              count: pinned.length,
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.95,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _AnimatedNoteCard(
                                  note: pinned[index],
                                  isDark: isDark,
                                  index: index,
                                  onPin: () => ref.read(notesProvider.notifier).togglePin(pinned[index].id),
                                  onDelete: () => _showDeleteConfirmation(context, pinned[index].id),
                                  onTap: () => _openNote(context, pinned[index]),
                                ),
                                childCount: pinned.length,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                        if (unpinned.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              icon: pinned.isEmpty ? Icons.note_alt_rounded : Icons.more_horiz_rounded,
                              title: pinned.isEmpty ? 'ALL NOTES' : 'OTHERS',
                              isDark: isDark,
                              count: unpinned.length,
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.95,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _AnimatedNoteCard(
                                  note: unpinned[index],
                                  isDark: isDark,
                                  index: pinned.length + index,
                                  onPin: () => ref.read(notesProvider.notifier).togglePin(unpinned[index].id),
                                  onDelete: () => _showDeleteConfirmation(context, unpinned[index].id),
                                  onTap: () => _openNote(context, unpinned[index]),
                                ),
                                childCount: unpinned.length,
                              ),
                            ),
                          ),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [BingoColors.darkFern, BingoColors.darkCanopy]
                    : [BingoColors.fog, BingoColors.cream],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_add_rounded,
              size: 56,
              color: isDark ? BingoColors.mintGreen.withOpacity(0.5) : BingoColors.stone.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notes yet',
            style: BingoTextStyles.headlineMedium.copyWith(
              color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start capturing your thoughts and ideas.',
            style: BingoTextStyles.bodyMedium.copyWith(
              color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.stone,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddNote(context),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Create your first note',
              style: BingoTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: BingoColors.emeraldGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? BingoColors.mintGreen : BingoColors.midGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: BingoTextStyles.labelLarge.copyWith(
              color: isDark ? BingoColors.mintGreen.withOpacity(0.7) : BingoColors.stone,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? BingoColors.darkFern : BingoColors.fog,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: BingoTextStyles.bodySmall.copyWith(
                color: isDark ? BingoColors.mintGreen : BingoColors.midGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddNoteSheet(),
    );
  }

  void _openNote(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(noteId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note deleted'), duration: Duration(seconds: 2)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: BingoColors.priorityHigh),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Note Card ───────────────────────────────────────────────────────

class _AnimatedNoteCard extends StatelessWidget {
  final Note note;
  final bool isDark;
  final int index;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _AnimatedNoteCard({
    required this.note,
    required this.isDark,
    required this.index,
    required this.onPin,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    try {
      final hex = note.colorHex.replaceAll('#', '');
      cardColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      cardColor = BingoColors.mistGreen;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptionsSheet(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [cardColor.withOpacity(0.15), cardColor.withOpacity(0.08)]
                : [cardColor.withOpacity(0.7), cardColor.withOpacity(0.5)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? cardColor.withOpacity(0.2) : cardColor.withOpacity(0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black12 : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with date and pin icon
                  Row(
                    children: [
                      if (note.isPinned)
                        Icon(
                          Icons.push_pin_rounded,
                          size: 14,
                          color: isDark ? BingoColors.mintGreen : BingoColors.emeraldGreen,
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black12 : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('MMM d').format(note.updatedAt),
                          style: BingoTextStyles.bodySmall.copyWith(
                            color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.bark.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    note.title,
                    style: BingoTextStyles.headlineSmall.copyWith(
                      color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Content preview
                  Expanded(
                    child: Text(
                      note.content.isEmpty ? 'No content' : note.content,
                      style: BingoTextStyles.bodySmall.copyWith(
                        color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.bark.withOpacity(0.7),
                        height: 1.4,
                        fontSize: 11,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tags
                  if (note.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: note.tags.take(2).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : cardColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? cardColor.withOpacity(0.3) : cardColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: BingoTextStyles.bodySmall.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isDark ? BingoColors.mintGreen : BingoColors.midGreen,
                          ),
                        ),
                      )).toList(),
                    ),
                ],
              ),
            ),
            // Subtle gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      isDark ? Colors.black12 : Colors.white12,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 60), duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms);
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? BingoColors.darkCanopy : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? BingoColors.darkFern : BingoColors.pebble,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? BingoColors.darkFern : BingoColors.fog,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: BingoColors.emeraldGreen,
                  size: 20,
                ),
              ),
              title: Text(
                note.isPinned ? 'Unpin note' : 'Pin to top',
                style: BingoTextStyles.bodyLarge.copyWith(
                  color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                onPin();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? BingoColors.darkFern : BingoColors.fog,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: BingoColors.priorityHigh, size: 20),
              ),
              title: Text(
                'Delete note',
                style: BingoTextStyles.bodyLarge.copyWith(
                  color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Note Detail Screen (Enhanced) ───────────────────────────────────────────

class NoteDetailScreen extends ConsumerStatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  bool _isSaving = false;

  // ── limits ──────────────────────────────
  static const int _titleMaxLength = 60;
  static const int _contentMaxLength = 2000;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    await Future.delayed(100.ms);

    final updated = widget.note.copyWith(
      title: _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim(),
      content: _contentController.text,
    );
    ref.read(notesProvider.notifier).updateNote(updated);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: isDark ? BingoColors.darkForest : BingoColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? BingoColors.darkFern : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedContainer(
              duration: 200.ms,
              height: _isSaving ? 44 : 46,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Save',
                  style: BingoTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BingoColors.emeraldGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            // Title field — single line, 60 char max
            TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              maxLines: 1,
              maxLength: _titleMaxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: BingoTextStyles.displaySmall.copyWith(
                color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: BingoTextStyles.displaySmall.copyWith(
                  color: isDark ? BingoColors.mintGreen.withOpacity(0.25) : BingoColors.stone.withOpacity(0.4),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '', // hide the built-in counter label
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              color: isDark ? BingoColors.darkFern : BingoColors.pebble.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            // Content field — 2000 char max
            Expanded(
              child: TextField(
                controller: _contentController,
                focusNode: _contentFocus,
                maxLines: null,
                expands: true,
                maxLength: _contentMaxLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textAlignVertical: TextAlignVertical.top,
                style: BingoTextStyles.bodyLarge.copyWith(
                  color: isDark ? BingoColors.paleGreen.withOpacity(0.85) : BingoColors.bark,
                  height: 1.7,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing your thoughts...',
                  hintStyle: BingoTextStyles.bodyLarge.copyWith(
                    color: isDark ? BingoColors.mintGreen.withOpacity(0.25) : BingoColors.stone.withOpacity(0.4),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '', // hide the built-in counter label
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Note Sheet (Enhanced) ───────────────────────────────────────────────

class AddNoteSheet extends ConsumerStatefulWidget {
  const AddNoteSheet({super.key});

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  String _colorHex = '#D8F3DC';
  List<String> _tags = [];
  bool _isSaving = false;

  // ── limits ──────────────────────────────
  static const int _titleMaxLength = 60;
  static const int _contentMaxLength = 500;

  final List<Map<String, dynamic>> _colors = [
    {'hex': '#D8F3DC', 'name': 'Mint'},
    {'hex': '#B7E4C7', 'name': 'Sage'},
    {'hex': '#95D5B2', 'name': 'Green'},
    {'hex': '#FFF3E0', 'name': 'Peach'},
    {'hex': '#FFE0B2', 'name': 'Apricot'},
    {'hex': '#FFDDD2', 'name': 'Coral'},
    {'hex': '#E3F2FD', 'name': 'Sky'},
    {'hex': '#E8EAF6', 'name': 'Lavender'},
    {'hex': '#FCE4EC', 'name': 'Rose'},
  ];

  void _addTag() {
    final tag = _tagsController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title'), duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(200.ms);

    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text,
      colorHex: _colorHex,
      tags: _tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    ref.read(notesProvider.notifier).addNote(note);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note created!'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? BingoColors.darkCanopy : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? BingoColors.darkFern : BingoColors.pebble,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'New Note',
                  style: BingoTextStyles.headlineLarge.copyWith(
                    color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Text('🍃', style: TextStyle(fontSize: 32)),
              ],
            ),
            const SizedBox(height: 20),
            // Title field — single line, 60 char max
            TextField(
              controller: _titleController,
              autofocus: true,
              maxLines: 1,
              maxLength: _titleMaxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: BingoTextStyles.headlineSmall.copyWith(
                color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Note title',
                hintStyle: BingoTextStyles.headlineSmall.copyWith(
                  color: isDark ? BingoColors.mintGreen.withOpacity(0.3) : BingoColors.stone.withOpacity(0.5),
                ),
                filled: true,
                fillColor: isDark ? BingoColors.darkFern : BingoColors.fog,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                counterText: '', // hide the built-in counter label
              ),
            ),
            const SizedBox(height: 12),
            // Content field — 4 lines visible, 500 char max
            TextField(
              controller: _contentController,
              maxLines: 4,
              maxLength: _contentMaxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: BingoTextStyles.bodyMedium.copyWith(
                color: isDark ? BingoColors.paleGreen : BingoColors.bark,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Write something...',
                hintStyle: BingoTextStyles.bodyMedium.copyWith(
                  color: isDark ? BingoColors.mintGreen.withOpacity(0.3) : BingoColors.stone.withOpacity(0.5),
                ),
                filled: true,
                fillColor: isDark ? BingoColors.darkFern : BingoColors.fog,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                counterText: '', // hide the built-in counter label
              ),
            ),
            const SizedBox(height: 16),
            // Tags section
            Text(
              'TAGS',
              style: BingoTextStyles.labelLarge.copyWith(
                color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.stone,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagsController,
                    onSubmitted: (_) => _addTag(),
                    style: BingoTextStyles.bodyMedium.copyWith(
                      color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add tag...',
                      hintStyle: BingoTextStyles.bodyMedium.copyWith(
                        color: isDark ? BingoColors.mintGreen.withOpacity(0.3) : BingoColors.stone.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: isDark ? BingoColors.darkFern : BingoColors.fog,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: BingoColors.forestMist,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? BingoColors.darkFern : BingoColors.fog,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? BingoColors.mintGreen.withOpacity(0.3) : BingoColors.midGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: BingoTextStyles.bodySmall.copyWith(
                          color: isDark ? BingoColors.mintGreen : BingoColors.midGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeTag(tag),
                        child: Icon(Icons.close_rounded, size: 14, color: isDark ? BingoColors.mintGreen : BingoColors.midGreen),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            // Color picker
            Text(
              'COLOR',
              style: BingoTextStyles.labelLarge.copyWith(
                color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.stone,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colors.map((colorData) {
                  final hex = colorData['hex'];
                  Color c;
                  try {
                    c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                  } catch (_) {
                    c = BingoColors.mistGreen;
                  }
                  final isSelected = _colorHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _colorHex = hex),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: const EdgeInsets.only(right: 12),
                      width: isSelected ? 44 : 40,
                      height: isSelected ? 44 : 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? BingoColors.emeraldGreen : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            // Save button
            AnimatedContainer(
              duration: 200.ms,
              height: _isSaving ? 54 : 56,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BingoColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: BingoColors.midGreen.withOpacity(0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Create Note',
                          style: BingoTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}