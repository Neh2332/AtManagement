import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/project_model.dart';
import '../services/at_platform_service.dart';
import '../main.dart';

/// Central state manager for AtManagement.
/// Handles local + atPlatform synchronization of tasks and projects.
class ProjectProvider extends ChangeNotifier {
  final AtPlatformService _service = AtPlatformService();

  List<TaskModel> _tasks = [];
  List<ProjectModel> _projects = [];
  ProjectModel? _currentProject;
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  List<ProjectModel> get projects => _projects;
  ProjectModel? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String get currentAtSign => _service.currentAtSign;

  // ── Filtered tasks by status ──
  List<TaskModel> tasksByStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).toList();

  int taskCountByStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).length;

  // ── Initialization ──

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await loadProjects();
    await loadTasks();

    // Start listening for tasks and projects shared from other AtSigns
    _service.listenForTaskNotifications(_onRemoteTaskReceived);
    _service.listenForProjectNotifications(_onRemoteProjectReceived);

    _isLoading = false;
    notifyListeners();
  }

  void _onRemoteTaskReceived(TaskModel remoteTask) {
    // Only update the live UI list if we are currently looking at
    // the project this task belongs to. (It's already saved to disk safely).
    if (_currentProject?.id != remoteTask.projectId) return;

    // Merge: update if exists, add if new
    final idx = _tasks.indexWhere((t) => t.id == remoteTask.id);
    if (idx >= 0) {
      _tasks[idx] = remoteTask;
    } else {
      _tasks.add(remoteTask);
    }
    notifyListeners();
  }

  void _onRemoteProjectReceived(ProjectModel remoteProject) {
    // Check if this is a new project invite
    final isNew = !_projects.any((p) => p.id == remoteProject.id);

    final idx = _projects.indexWhere((p) => p.id == remoteProject.id);
    if (idx >= 0) {
      _projects[idx] = remoteProject;
    } else {
      _projects.add(remoteProject);
    }

    if (isNew) {
      // Show an in-app popup invite
      AtManagementApp.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '🎉 You were invited to "${remoteProject.name}" by ${remoteProject.ownerAtSign}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    notifyListeners();
  }

  // ── Projects ──

  Future<void> loadProjects() async {
    _projects = await _service.getAllProjects();
    if (_projects.isEmpty) {
      // Create a default project on first launch
      final defaultProject = ProjectModel(
        id: const Uuid().v4(),
        name: 'My First Project',
        description: 'Default project board',
        ownerAtSign: _service.currentAtSign,
      );
      await _service.putProject(defaultProject);
      _projects = [defaultProject];
    }
    _currentProject ??= _projects.first;
    notifyListeners();
  }

  Future<void> createProject(String name, String description) async {
    final project = ProjectModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      ownerAtSign: _service.currentAtSign,
    );
    await _service.putProject(project);
    _projects.add(project);
    _currentProject = project;
    notifyListeners();
  }

  void selectProject(ProjectModel project) {
    _currentProject = project;
    loadTasks();
  }

  Future<void> deleteProject(String projectId) async {
    await _service.deleteProject(projectId);
    _projects.removeWhere((p) => p.id == projectId);
    _tasks.removeWhere((t) => t.projectId == projectId);
    if (_currentProject?.id == projectId) {
      _currentProject = _projects.isNotEmpty ? _projects.first : null;
    }
    notifyListeners();
  }

  // ── Tasks ──

  Future<void> loadTasks() async {
    _tasks = await _service.getAllTasks();
    if (_currentProject != null) {
      _tasks =
          _tasks.where((t) => t.projectId == _currentProject!.id).toList();
    }
    notifyListeners();
  }

  Future<void> createTask({
    required String title,
    String description = '',
    String assigneeAtSign = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      assigneeAtSign: assigneeAtSign,
      creatorAtSign: _service.currentAtSign,
      priority: priority,
      status: TaskStatus.todo,
      dueDate: dueDate,
      projectId: _currentProject?.id ?? 'default',
    );
    await _service.putTask(task);
    _tasks.add(task);

    // If assigned to someone else, share via atPlatform
    if (assigneeAtSign.isNotEmpty &&
        assigneeAtSign != _service.currentAtSign) {
      await _service.shareTask(task, assigneeAtSign);
    }

    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    await _service.putTask(task);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      _tasks[idx] = task;
    }

    // Re-share if assigned
    if (task.assigneeAtSign.isNotEmpty &&
        task.assigneeAtSign != _service.currentAtSign) {
      await _service.shareTask(task, task.assigneeAtSign);
    }

    notifyListeners();
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx >= 0) {
      _tasks[idx].status = newStatus;
      await _service.putTask(_tasks[idx]);

      if (_tasks[idx].assigneeAtSign.isNotEmpty &&
          _tasks[idx].assigneeAtSign != _service.currentAtSign) {
        await _service.shareTask(_tasks[idx], _tasks[idx].assigneeAtSign);
      }

      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId,
        orElse: () => throw StateError('Task not found'));

    // Revoke shared copies
    if (task.assigneeAtSign.isNotEmpty &&
        task.assigneeAtSign != _service.currentAtSign) {
      await _service.revokeTask(taskId, task.assigneeAtSign);
    }

    await _service.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  Future<void> addComment(
      String taskId, String text) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx >= 0) {
      _tasks[idx].comments.add(TaskComment(
        id: const Uuid().v4(),
        authorAtSign: _service.currentAtSign,
        text: text,
      ));
      await _service.putTask(_tasks[idx]);
      notifyListeners();
    }
  }

  // ── Team Management ──

  /// Invite a member and immediately share all current-project tasks with them
  /// so they see the full board when they open the app.
  Future<void> inviteMember(String rawAtSign) async {
    if (_currentProject == null) return;
    
    final atSign = rawAtSign.startsWith('@') ? rawAtSign : '@$rawAtSign';
    
    if (_currentProject!.memberAtSigns.contains(atSign)) return;

    _currentProject!.memberAtSigns.add(atSign);
    await _service.putProject(_currentProject!);

    // 1. Share the project board itself
    await _service.shareProject(_currentProject!, atSign);

    // 2. Share every task in this project so they see the board immediately
    final projectTasks =
        _tasks.where((t) => t.projectId == _currentProject!.id);
    for (final task in projectTasks) {
      await _service.shareTask(task, atSign);
    }

    notifyListeners();
  }

  Future<void> removeMember(String atSign) async {
    if (_currentProject != null) {
      _currentProject!.memberAtSigns.remove(atSign);
      await _service.putProject(_currentProject!);

      // Revoke all tasks shared with this member
      for (final task in _tasks.where((t) => t.assigneeAtSign == atSign)) {
        await _service.revokeTask(task.id, atSign);
        task.assigneeAtSign = '';
        await _service.putTask(task);
      }

      notifyListeners();
    }
  }
}
