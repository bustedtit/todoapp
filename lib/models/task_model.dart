// lib/models/task_model.dart

enum Priority { low, medium, high }
enum TaskStatus { pending, inProgress, completed }
enum Recurrence { none, daily, weekly, monthly }

class Task {
  final String id;
  final String title;
  final String? description;
  final Priority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? linkedNoteId;
  final List<String> tags;
  final bool isStarred;
  final Recurrence recurrence;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = Priority.medium,
    this.status = TaskStatus.pending,
    this.dueDate,
    DateTime? createdAt,
    this.completedAt,
    this.linkedNoteId,
    List<String>? tags,
    this.isStarred = false,
    this.recurrence = Recurrence.none,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  Task copyWith({
    String? title,
    String? description,
    Priority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? completedAt,
    String? linkedNoteId,
    List<String>? tags,
    bool? isStarred,
    Recurrence? recurrence,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      linkedNoteId: linkedNoteId ?? this.linkedNoteId,
      tags: tags ?? this.tags,
      isStarred: isStarred ?? this.isStarred,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': status.name,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'linkedNoteId': linkedNoteId,
        'tags': tags,
        'isStarred': isStarred,
        'recurrence': recurrence.name,
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        priority: Priority.values.firstWhere(
          (e) => e.name == j['priority'],
          orElse: () => Priority.medium,
        ),
        status: TaskStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => TaskStatus.pending,
        ),
        dueDate: j['dueDate'] != null ? DateTime.parse(j['dueDate']) : null,
        createdAt: DateTime.parse(j['createdAt']),
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'])
            : null,
        linkedNoteId: j['linkedNoteId'] as String?,
        tags: List<String>.from(j['tags'] ?? []),
        isStarred: j['isStarred'] as bool? ?? false,
        recurrence: Recurrence.values.firstWhere(
          (e) => e.name == (j['recurrence'] ?? 'none'),
          orElse: () => Recurrence.none,
        ),
      );
}

// ─── Note ─────────────────────────────────────────────────────────────────────

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final List<String> tags;
  final bool isPinned;
  final String? linkedTaskId;
  final String colorHex;

  Note({
    required this.id,
    required this.title,
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.folderId,
    List<String>? tags,
    this.isPinned = false,
    this.linkedTaskId,
    this.colorHex = '#FFFFFF',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  String get preview {
    if (content.isEmpty) return 'No additional text';
    return content.length > 120 ? '${content.substring(0, 120)}...' : content;
  }

  int get wordCount => content.isEmpty
      ? 0
      : content.trim().split(RegExp(r'\s+')).length;

  Note copyWith({
    String? title,
    String? content,
    String? folderId,
    List<String>? tags,
    bool? isPinned,
    String? linkedTaskId,
    String? colorHex,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'folderId': folderId,
        'tags': tags,
        'isPinned': isPinned,
        'linkedTaskId': linkedTaskId,
        'colorHex': colorHex,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: j['title'] as String,
        content: j['content'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'])
            : DateTime.now(),
        folderId: j['folderId'] as String?,
        tags: List<String>.from(j['tags'] ?? []),
        isPinned: j['isPinned'] as bool? ?? false,
        linkedTaskId: j['linkedTaskId'] as String?,
        colorHex: j['colorHex'] as String? ?? '#FFFFFF',
      );
}
