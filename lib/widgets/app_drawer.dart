import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();

    return Drawer(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: const Border(
                  bottom: BorderSide(color: AppTheme.dividerColor),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.atsignWhite,
                          AppTheme.atsignWhite,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.atsignOrange.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset('assets/atsign_logo.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AtManagement',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.atsignOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            provider.currentAtSign.isNotEmpty
                                ? provider.currentAtSign
                                : '...',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.atsignOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Projects section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                children: [
                  const Text(
                    'PROJECTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  _AddProjectButton(
                    onTap: () => _showNewProjectDialog(context),
                  ),
                ],
              ),
            ),

            // Project list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                itemCount: provider.projects.length,
                itemBuilder: (_, i) {
                  final project = provider.projects[i];
                  final isSelected =
                      provider.currentProject?.id == project.id;
                  final isOwner =
                      provider.currentAtSign == project.ownerAtSign;

                  return _ProjectTile(
                    name: project.name,
                    isSelected: isSelected,
                    onDelete: (isSelected && isOwner)
                        ? () => provider.deleteProject(project.id)
                        : null,
                    onTap: () {
                      provider.selectProject(project);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),

            // Divider
            const Divider(color: AppTheme.dividerColor, height: 1),

            // Team Members tile
            _DrawerAction(
              icon: Icons.group_outlined,
              label: 'Team Members',
              onTap: () {
                Navigator.of(context).pop();
                _showTeamSheet(context);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => AlertDialog(
        title: const Text('New Project',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<ProjectProvider>().createProject(
                      nameController.text.trim(),
                      descController.text.trim(),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showTeamSheet(BuildContext context) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => Consumer<ProjectProvider>(
        builder: (ctx, provider, _) {
          final members = provider.currentProject?.memberAtSigns ?? [];

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.65,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Team Members',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Invite input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Invite by AtSign  (@someone)',
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          if (text.isNotEmpty) {
                            provider.inviteMember(text);
                            controller.clear();
                          }
                        },
                        child: const Text('Invite'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Owner row
                _memberTile(
                  provider.currentAtSign,
                  'Owner',
                  isOwner: true,
                ),

                if (members.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: members.length,
                      itemBuilder: (_, i) => _memberTile(
                        members[i],
                        'Member',
                        onRemove: () => provider.removeMember(members[i]),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _memberTile(
    String atSign,
    String role, {
    bool isOwner = false,
    VoidCallback? onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.atsignOrange, AppTheme.atsignOrangeDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.atsignOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  atSign.length > 1 ? atSign[1].toUpperCase() : '@',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    atSign,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 11,
                      color: isOwner
                          ? AppTheme.atsignOrange
                          : AppTheme.textMuted,
                      fontWeight: isOwner ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    size: 18, color: AppTheme.priorityCritical),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatefulWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProjectTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<_ProjectTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.atsignOrange.withValues(alpha: 0.08)
                : _hovered
                    ? AppTheme.surfaceHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: widget.isSelected
                ? Border.all(
                    color: AppTheme.atsignOrange.withValues(alpha: 0.3))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected
                      ? AppTheme.atsignOrange
                      : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? AppTheme.atsignOrange
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (widget.isSelected && widget.onDelete == null)
                const Icon(Icons.check_rounded,
                    size: 16, color: AppTheme.atsignOrange),
              if (widget.isSelected && widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.priorityCritical),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProjectButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddProjectButton({required this.onTap});

  @override
  State<_AddProjectButton> createState() => _AddProjectButtonState();
}

class _AddProjectButtonState extends State<_AddProjectButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.atsignOrange.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.add_rounded,
            size: 18,
            color: _hovered ? AppTheme.atsignOrange : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DrawerAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_DrawerAction> createState() => _DrawerActionState();
}

class _DrawerActionState extends State<_DrawerAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 20,
                  color: _hovered
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _hovered
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
