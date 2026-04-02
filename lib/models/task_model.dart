import 'dart:convert';

enum TaskPriority { low, medium, high, critical }

enum TaskStatus { todo, inProgress, review, done }

class TaskModel {
  final String id;
  String title;
  String description;
  String assigneeAtSign;
  String creatorAtSign;
  TaskPriority priority;
  TaskStatus status;
  DateTime createdAt;
  DateTime? dueDate;
  List<TaskComment> comments;
  String projectId;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.assigneeAtSign = '',
    required this.creatorAtSign,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    DateTime? createdAt,
    this.dueDate,
    List<TaskComment>? comments,
    this.projectId = 'default',
  })  : createdAt = createdAt ?? DateTime.now(),
        comments = comments ?? [];

  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'Review';
      case TaskStatus.done:
        return 'Done';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'assigneeAtSign': assigneeAtSign,
        'creatorAtSign': creatorAtSign,
        'priority': priority.index,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'projectId': projectId,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        assigneeAtSign: json['assigneeAtSign'] as String? ?? '',
        creatorAtSign: json['creatorAtSign'] as String,
        priority: TaskPriority.values[json['priority'] as int? ?? 1],
        status: TaskStatus.values[json['status'] as int? ?? 0],
        createdAt: DateTime.parse(json['createdAt'] as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        comments: (json['comments'] as List<dynamic>?)
                ?.map((c) =>
                    TaskComment.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        projectId: json['projectId'] as String? ?? 'default',
      );

  factory TaskModel.fromJsonString(String jsonString) =>
      TaskModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());

  TaskModel copyWith({
    String? title,
    String? description,
    String? assigneeAtSign,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    List<TaskComment>? comments,
  }) =>
      TaskModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        assigneeAtSign: assigneeAtSign ?? this.assigneeAtSign,
        creatorAtSign: creatorAtSign,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        createdAt: createdAt,
        dueDate: dueDate ?? this.dueDate,
        comments: comments ?? this.comments,
        projectId: projectId,
      );
}

class TaskComment {
  final String id;
  final String authorAtSign;
  final String text;
  final DateTime createdAt;

  TaskComment({
    required this.id,
    required this.authorAtSign,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorAtSign': authorAtSign,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TaskComment.fromJson(Map<String, dynamic> json) => TaskComment(
        id: json['id'] as String,
        authorAtSign: json['authorAtSign'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
