import 'dart:developer';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_commons/at_commons.dart';
import '../constants.dart';
import '../models/task_model.dart';
import '../models/project_model.dart';

/// Service layer wrapping the atPlatform SDK for all CRUD and notification
/// operations. Each task and project is stored as an encrypted atRecord on the
/// authenticated user's atServer.
class AtPlatformService {
  static final AtPlatformService _instance = AtPlatformService._();
  factory AtPlatformService() => _instance;
  AtPlatformService._();

  AtClient get _atClient => AtClientManager.getInstance().atClient;
  String get currentAtSign => _atClient.getCurrentAtSign() ?? '';

  // ────────────────── Task CRUD ──────────────────

  /// Build an AtKey for a task record.
  AtKey _taskKey(String taskId) {
    return AtKey()
      ..key = 'task_$taskId'
      ..namespace = appNamespace
      ..sharedBy = currentAtSign;
  }

  /// Create or update a task on the local atServer.
  Future<bool> putTask(TaskModel task) async {
    try {
      final key = _taskKey(task.id);
      final result = await _atClient.put(key, task.toJsonString());
      log('AtPlatformService: putTask ${task.id} → $result');
      return result;
    } catch (e) {
      log('AtPlatformService: putTask error: $e');
      return false;
    }
  }

  /// Get a single task by its ID.
  Future<TaskModel?> getTask(String taskId) async {
    try {
      final key = _taskKey(taskId);
      final atValue = await _atClient.get(key);
      if (atValue.value != null) {
        return TaskModel.fromJsonString(atValue.value as String);
      }
    } catch (e) {
      log('AtPlatformService: getTask error: $e');
    }
    return null;
  }

  /// Get all tasks stored on the local atServer.
  Future<List<TaskModel>> getAllTasks() async {
    final tasks = <TaskModel>[];
    try {
      final keys = await _atClient.getAtKeys(regex: 'task_.*.$appNamespace');
      for (final key in keys) {
        try {
          final atValue = await _atClient.get(key);
          if (atValue.value != null) {
            tasks.add(TaskModel.fromJsonString(atValue.value as String));
          }
        } catch (e) {
          log('AtPlatformService: skipping key ${key.key}: $e');
        }
      }
    } catch (e) {
      log('AtPlatformService: getAllTasks error: $e');
    }
    return tasks;
  }

  /// Delete a task from the local atServer.
  Future<bool> deleteTask(String taskId) async {
    try {
      final key = _taskKey(taskId);
      final result = await _atClient.delete(key);
      log('AtPlatformService: deleteTask $taskId → $result');
      return result;
    } catch (e) {
      log('AtPlatformService: deleteTask error: $e');
      return false;
    }
  }

  // ────────────────── Project CRUD ──────────────────

  AtKey _projectKey(String projectId) {
    return AtKey()
      ..key = 'project_$projectId'
      ..namespace = appNamespace
      ..sharedBy = currentAtSign;
  }

  Future<bool> putProject(ProjectModel project) async {
    try {
      final key = _projectKey(project.id);
      final result = await _atClient.put(key, project.toJsonString());
      log('AtPlatformService: putProject ${project.id} → $result');
      return result;
    } catch (e) {
      log('AtPlatformService: putProject error: $e');
      return false;
    }
  }

  Future<List<ProjectModel>> getAllProjects() async {
    final projects = <ProjectModel>[];
    try {
      final keys =
          await _atClient.getAtKeys(regex: 'project_.*.$appNamespace');
      for (final key in keys) {
        try {
          final atValue = await _atClient.get(key);
          if (atValue.value != null) {
            projects
                .add(ProjectModel.fromJsonString(atValue.value as String));
          }
        } catch (e) {
          log('AtPlatformService: skipping project key ${key.key}: $e');
        }
      }
    } catch (e) {
      log('AtPlatformService: getAllProjects error: $e');
    }
    return projects;
  }

  Future<bool> deleteProject(String projectId) async {
    try {
      final key = _projectKey(projectId);
      return await _atClient.delete(key);
    } catch (e) {
      log('AtPlatformService: deleteProject error: $e');
      return false;
    }
  }

  // ────────────────── Sharing / Notifications ──────────────────

  /// Share a task with another AtSign by writing a shared record and
  /// sending a notification.
  Future<bool> shareTask(TaskModel task, String recipientAtSign) async {
    try {
      final key = AtKey()
        ..key = 'task_${task.id}'
        ..namespace = appNamespace
        ..sharedBy = currentAtSign
        ..sharedWith = recipientAtSign;

      final result = await _atClient.put(key, task.toJsonString());
      log('AtPlatformService: shareTask ${task.id} → $recipientAtSign: $result');

      // Dispatch real-time push notification so other apps update instantly
      await _atClient.notificationService.notify(
        NotificationParams.forUpdate(key, value: task.toJsonString()),
      );

      return result;
    } catch (e) {
      log('AtPlatformService: shareTask error: $e');
      return false;
    }
  }

  /// Listen for incoming task notifications from other AtSigns.
  void listenForTaskNotifications(
      void Function(TaskModel task) onTaskReceived) {
    _atClient.notificationService
        .subscribe(regex: 'task_', shouldDecrypt: true)
        .listen((notification) async {
      try {
        // Explicitly fetch the exact key to guarantee it reads the properly 
        // decrypted payload from the keystore, bypassing payload quirks.
        final keyToFetch = AtKey.fromString(notification.key);
        final atValue = await _atClient.get(keyToFetch);

        if (atValue.value != null) {
          final task = TaskModel.fromJsonString(atValue.value as String);
          onTaskReceived(task);
        }
      } catch (e) {
        log('AtPlatformService: notification parse error: $e');
      }
    });
  }

  /// Share an entire project board with another AtSign.
  Future<bool> shareProject(
      ProjectModel project, String recipientAtSign) async {
    try {
      final key = AtKey()
        ..key = 'project_${project.id}'
        ..namespace = appNamespace
        ..sharedBy = currentAtSign
        ..sharedWith = recipientAtSign;

      final result = await _atClient.put(key, project.toJsonString());
      log('AtPlatformService: shareProject ${project.id} → $recipientAtSign: $result');

      // Dispatch real-time push notification so other apps update instantly
      await _atClient.notificationService.notify(
        NotificationParams.forUpdate(key, value: project.toJsonString()),
      );

      return result;
    } catch (e) {
      log('AtPlatformService: shareProject error: $e');
      return false;
    }
  }

  /// Listen for incoming project invitations from other AtSigns.
  void listenForProjectNotifications(
      void Function(ProjectModel project) onProjectReceived) {
    _atClient.notificationService
        .subscribe(regex: 'project_', shouldDecrypt: true)
        .listen((notification) async {
      try {
        final keyToFetch = AtKey.fromString(notification.key);
        final atValue = await _atClient.get(keyToFetch);

        if (atValue.value != null) {
          final project = ProjectModel.fromJsonString(atValue.value as String);
          onProjectReceived(project);
        }
      } catch (e) {
        log('AtPlatformService: project notification parse error: $e');
      }
    });
  }

  /// Revoke a shared task — delete the shared record for a given AtSign.
  Future<bool> revokeTask(String taskId, String recipientAtSign) async {
    try {
      final key = AtKey()
        ..key = 'task_$taskId'
        ..namespace = appNamespace
        ..sharedBy = currentAtSign
        ..sharedWith = recipientAtSign;
      return await _atClient.delete(key);
    } catch (e) {
      log('AtPlatformService: revokeTask error: $e');
      return false;
    }
  }
}
