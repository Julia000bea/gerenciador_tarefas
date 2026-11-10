import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/date_format.dart';
import '../utils/smart_parser.dart';

/// Formulário completo de criação/edição.
///
/// * [task] preenchido -> modo edição
/// * [initial] preenchido -> veio da adição rápida ("Mais detalhes")
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task, this.initial});

  final Task? task;
  final ParsedTask? initial;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TaskCategory _category;
  late TaskPriority _priority;
  DateTime? _due;
  late bool _done;

  /// Enquanto o usuário não escolher a categoria manualmente,
  /// ela é sugerida a partir do título.
  bool _categoryTouched = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    final i = widget.initial;
    _titleCtrl = TextEditingController(text: t?.title ?? i?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _category = t?.category ?? i?.category ?? TaskCategory.outros;
    _priority = t?.priority ?? i?.priority ?? TaskPriority.media;
    _due = t?.dueDate ?? i?.dueDate;
    _done = t?.done ?? false;
    _categoryTouched = t != null || (i?.category != null && !i!.categoryInferred);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onTitleChanged(String value) {
    if (_categoryTouched) return;
    final suggestion = SmartParser.inferCategory(value);
    if (suggestion != null && suggestion != _category) {
      setState(() => _category = suggestion);
    }
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final initial = _due ?? today;
    final first = initial.isBefore(today) ? initial : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(today.year + 5),
      helpText: 'Prazo da tarefa',
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TaskProvider>();
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();

    final existing = widget.task;
    if (existing == null) {
      provider.add(Task.create(
        title: title,
        description: description,
        category: _category,
        priority: _priority,
        dueDate: _due,
      ));
    } else {
      provider.update(existing.copyWith(
        title: title,
        description: description,
        category: _category,
        priority: _priority,
        dueDate: _due,
        clearDueDate: _due == null,
        done: _done,
        completedAt: _done ? (existing.completedAt ?? DateTime.now()) : null,
        clearCompletedAt: !_done,
      ));
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text('"${widget.task!.title}" será removida permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<TaskProvider>().delete(widget.task!.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar tarefa' : 'Nova tarefa'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _titleCtrl,
              autofocus: !_isEditing && widget.initial == null,
              onChanged: _onTitleChanged,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Informe um título'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Prioridade', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: [
                for (final p in TaskPriority.values)
                  ButtonSegment(
                    value: p,
                    label: Text(p.label),
                    icon: Icon(Icons.flag, color: p.color),
                  ),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 24),
            Text('Categoria', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in TaskCategory.values)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 18, color: c.color),
                    label: Text(c.label),
                    selected: _category == c,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _category = c;
                      _categoryTouched = true;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Prazo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(_due == null
                    ? 'Sem prazo'
                    : '${formatDate(_due!)} · ${formatDueDate(_due!, today)}'),
                trailing: _due == null
                    ? null
                    : IconButton(
                        tooltip: 'Remover prazo',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _due = null),
                      ),
                onTap: _pickDate,
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Concluída'),
                value: _done,
                onChanged: (v) => setState(() => _done = v),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Salvar alterações' : 'Criar tarefa'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
