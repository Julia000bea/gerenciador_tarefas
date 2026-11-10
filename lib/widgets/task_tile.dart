import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/task_form_screen.dart';
import '../utils/date_format.dart';

/// Item da lista. Toque = editar, caixa = concluir, deslizar = excluir.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  void _onDismissed(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    provider.delete(task.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('"${task.title}" excluída'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => provider.restore(task),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = dateOnly(DateTime.now());
    final overdue = task.isOverdueOn(today);
    final muted = scheme.onSurfaceVariant;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _onDismissed(context),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 5,
                  color: task.done
                      ? task.priority.color.withValues(alpha: 0.3)
                      : task.priority.color,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: task.done,
                  shape: const CircleBorder(),
                  onChanged: (_) =>
                      context.read<TaskProvider>().toggleDone(task.id),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration:
                                task.done ? TextDecoration.lineThrough : null,
                            color: task.done ? muted : null,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: muted),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _Meta(
                              icon: task.category.icon,
                              label: task.category.label,
                              color: task.category.color,
                            ),
                            _Meta(
                              icon: Icons.flag_outlined,
                              label: task.priority.label,
                              color: task.priority.color,
                            ),
                            if (task.dueDate != null)
                              _Meta(
                                icon: Icons.event_outlined,
                                label: formatDueDate(task.dueDate!, today),
                                color: overdue ? scheme.error : muted,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
