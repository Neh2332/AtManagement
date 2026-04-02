import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'task_detail_sheet.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final Color accentColor;

  const TaskCard({
    super.key,
    required this.task,
    required this.accentColor,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => TaskDetailSheet(task: widget.task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.priorityColor(widget.task.priority.index);

    return Draggable<TaskModel>(
      data: widget.task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 260,
          child: _buildCardContent(priorityColor, isLifted: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: _buildCardContent(priorityColor),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => _showDetail(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0.0, _hovered ? -2.0 : 0.0, 0.0),
            child: _buildCardContent(priorityColor),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(Color priorityColor, {bool isLifted = false}) {
    final task = widget.task;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _hovered || isLifted
              ? widget.accentColor.withValues(alpha: 0.3)
              : AppTheme.dividerColor,
        ),
        boxShadow: isLifted
            ? AppTheme.liftedShadow
            : _hovered
                ? AppTheme.cardShadow
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                topRight: Radius.circular(AppTheme.radiusMd),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Bottom row
                Row(
                  children: [
                    // Priority pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        task.priorityLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    const Spacer(),

                    if (task.comments.isNotEmpty) ...[
                      const Icon(Icons.chat_bubble_outline,
                          size: 11, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${task.comments.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    if (task.dueDate != null) ...[
                      const Icon(Icons.schedule,
                          size: 11, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('MMM d').format(task.dueDate!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Assignee avatar
                    if (task.assigneeAtSign.isNotEmpty)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              widget.accentColor,
                              widget.accentColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            task.assigneeAtSign.length > 1
                                ? task.assigneeAtSign[1].toUpperCase()
                                : '@',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
