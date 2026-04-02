import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';

class CreateTaskDialog extends StatefulWidget {
  final TaskModel? existingTask;

  const CreateTaskDialog({super.key, this.existingTask});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedAssignee = '';
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingTask?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingTask?.description ?? '');
    _selectedAssignee = widget.existingTask?.assigneeAtSign ?? '';
    if (_isEditing) {
      _priority = widget.existingTask!.priority;
      _dueDate = widget.existingTask!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> _getTeamMembers() {
    final provider = context.read<ProjectProvider>();
    final members = <String>[];

    // Add the current user (yourself)
    if (provider.currentAtSign.isNotEmpty) {
      members.add(provider.currentAtSign);
    }

    // Add all project teammates
    if (provider.currentProject != null) {
      for (final member in provider.currentProject!.memberAtSigns) {
        if (!members.contains(member)) {
          members.add(member);
        }
      }
    }

    return members;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final provider = context.read<ProjectProvider>();

    if (_isEditing) {
      final updatedTask = widget.existingTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assigneeAtSign: _selectedAssignee,
        priority: _priority,
        dueDate: _dueDate,
      );
      await provider.updateTask(updatedTask);
    } else {
      await provider.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assigneeAtSign: _selectedAssignee,
        priority: _priority,
        dueDate: _dueDate,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final teamMembers = _getTeamMembers();

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        _isEditing ? 'Edit Task' : 'New Task',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'What needs to be done?',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title required' : null,
                    autofocus: true,
                  ),

                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add details...',
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 12),

                  // Assignee — Dropdown of team members
                  const Text(
                    'Assign to',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (teamMembers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: const Text(
                        'No team members yet. Invite members from the drawer.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedAssignee.isEmpty
                              ? null
                              : (teamMembers.contains(_selectedAssignee)
                                  ? _selectedAssignee
                                  : null),
                          hint: const Text(
                            'Select a teammate',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          items: [
                            // "Unassigned" option
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text(
                                'Unassigned',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            // Team members
                            ...teamMembers.map((member) {
                              final isMe = member ==
                                  context
                                      .read<ProjectProvider>()
                                      .currentAtSign;
                              return DropdownMenuItem<String>(
                                value: member,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.atsignOrange,
                                      ),
                                      child: Center(
                                        child: Text(
                                          member.length > 1
                                              ? member[1].toUpperCase()
                                              : '@',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      member,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        '(you)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedAssignee = value ?? '';
                            });
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Priority Selector
                  const Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: TaskPriority.values.map((p) {
                      final isSelected = _priority == p;
                      final color = AppTheme.priorityColor(p.index);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _priority = p),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.12)
                                  : AppTheme.surfaceSecondary,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(
                                color:
                                    isSelected ? color : AppTheme.dividerColor,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _priorityLabel(p),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? color
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Due Date
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            _dueDate != null
                                ? 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                : 'Set due date (optional)',
                            style: TextStyle(
                              color: _dueDate != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (_dueDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _dueDate = null),
                              child: const Icon(Icons.close,
                                  size: 16, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditing ? 'Save Changes' : 'Create Task'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Med';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Crit';
    }
  }
}
