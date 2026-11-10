import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

/// Chips de filtro por status, categoria e prioridade.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(children: [
          for (final s in StatusFilter.values)
            ChoiceChip(
              label: Text(s.label),
              selected: p.status == s,
              onSelected: (_) => p.setStatus(s),
            ),
        ]),
        _ChipRow(children: [
          for (final c in TaskCategory.values)
            FilterChip(
              showCheckmark: false,
              avatar: Icon(c.icon, size: 16, color: c.color),
              label: Text(c.label),
              selected: p.category == c,
              onSelected: (sel) => p.setCategory(sel ? c : null),
            ),
          for (final pr in TaskPriority.values)
            FilterChip(
              showCheckmark: false,
              avatar: Icon(Icons.flag, size: 16, color: pr.color),
              label: Text(pr.label),
              selected: p.priority == pr,
              onSelected: (sel) => p.setPriority(sel ? pr : null),
            ),
          if (p.hasChipFilters)
            ActionChip(
              avatar: const Icon(Icons.filter_alt_off_outlined, size: 16),
              label: const Text('Limpar'),
              onPressed: p.clearFilters,
            ),
        ]),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final c in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }
}
