import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/task_form_screen.dart';
import '../utils/date_format.dart';
import '../utils/smart_parser.dart';

Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const QuickAddSheet(),
  );
}

/// Adição rápida: o usuário escreve uma frase e o app interpreta
/// categoria, prioridade e prazo em tempo real.
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _ctrl = TextEditingController();
  ParsedTask? _parsed;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _parsed = value.trim().isEmpty ? null : SmartParser.parse(value);
    });
  }

  void _save() {
    final parsed = _parsed;
    if (parsed == null) return;
    context.read<TaskProvider>().add(Task.create(
          title: parsed.title,
          category: parsed.category ?? TaskCategory.outros,
          priority: parsed.priority ?? TaskPriority.media,
          dueDate: parsed.dueDate,
        ));
    Navigator.of(context).pop();
  }

  void _openFullForm() {
    final navigator = Navigator.of(context);
    final parsed = _parsed;
    navigator.pop();
    navigator.push(MaterialPageRoute(
      builder: (_) => TaskFormScreen(initial: parsed),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = _parsed;
    final today = dateOnly(DateTime.now());

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nova tarefa', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Escreva naturalmente. Ex.: "Entregar relatório amanhã #trabalho !alta"',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onChanged,
            onSubmitted: (_) => _save(),
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'O que você precisa fazer?',
              border: OutlineInputBorder(),
            ),
          ),
          if (parsed != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (parsed.category != null)
                  _PreviewChip(
                    icon: parsed.category!.icon,
                    color: parsed.category!.color,
                    label: parsed.categoryInferred
                        ? '${parsed.category!.label} (sugerida)'
                        : parsed.category!.label,
                  ),
                if (parsed.priority != null)
                  _PreviewChip(
                    icon: Icons.flag,
                    color: parsed.priority!.color,
                    label: 'Prioridade ${parsed.priority!.label}',
                  ),
                if (parsed.dueDate != null)
                  _PreviewChip(
                    icon: Icons.event,
                    color: theme.colorScheme.primary,
                    label: formatDueDate(parsed.dueDate!, today),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: _openFullForm,
                icon: const Icon(Icons.tune),
                label: const Text('Mais detalhes'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: parsed == null ? null : _save,
                child: const Text('Adicionar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
    );
  }
}
