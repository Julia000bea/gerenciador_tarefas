import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';

/// Resumo do progresso + sugestão inteligente de foco.
class StatsHeader extends StatelessWidget {
  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    final s = p.stats;
    final focus = p.nextFocus;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onColor = scheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Card(
        elevation: 0,
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.done} de ${s.total} concluídas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${(s.progress * 100).round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(color: onColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: s.progress,
                  minHeight: 8,
                  backgroundColor: onColor.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(label: 'Pendentes', value: s.pending),
                  _Pill(label: 'Para hoje', value: s.dueToday),
                  _Pill(
                    label: 'Atrasadas',
                    value: s.overdue,
                    alert: s.overdue > 0,
                  ),
                ],
              ),
              if (focus != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: onColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Comece por: ',
                          children: [
                            TextSpan(
                              text: focus.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: onColor),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, this.alert = false});

  final String label;
  final int value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = alert ? scheme.errorContainer : scheme.surface;
    final fg = alert ? scheme.onErrorContainer : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
