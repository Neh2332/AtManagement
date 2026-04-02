import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  final TaskStatus status;
  final List<TaskModel> tasks;
  final void Function(String taskId, TaskStatus newStatus) onStatusChanged;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onStatusChanged,
  });

  String get _title {
    switch (status) {
      case TaskStatus.todo:        return 'To Do';
      case TaskStatus.inProgress:  return 'In Progress';
      case TaskStatus.review:      return 'Review';
      case TaskStatus.done:        return 'Done';
    }
  }

  Color get _accentColor {
    switch (status) {
      case TaskStatus.todo:        return AppTheme.textSecondary;
      case TaskStatus.inProgress:  return AppTheme.atsignOrange;
      case TaskStatus.review:      return AppTheme.accentPurple;
      case TaskStatus.done:        return AppTheme.accentTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<TaskModel>(
      onAcceptWithDetails: (details) => onStatusChanged(details.data.id, status),
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovering
                ? _accentColor.withValues(alpha: 0.05)
                : AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isHovering
                  ? _accentColor.withValues(alpha: 0.5)
                  : AppTheme.dividerColor,
              width: isHovering ? 1.5 : 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusLg),
                    topRight: Radius.circular(AppTheme.radiusLg),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accentColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cards
              if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 14),
                  child: Column(
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 24, color: AppTheme.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'Drop tasks here',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(10),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskCard(
                        task: tasks[i],
                        accentColor: _accentColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
