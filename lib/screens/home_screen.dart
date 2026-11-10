import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/stats_header.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearAll(TaskProvider p) {
    _searchCtrl.clear();
    p.clearFilters(includeQuery: true);
  }

  Future<void> _clearCompleted(TaskProvider p) async {
    final messenger = ScaffoldMessenger.of(context);
    final removed = await p.clearCompleted();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(removed == 0
            ? 'Nenhuma tarefa concluída para remover'
            : '$removed tarefa(s) concluída(s) removida(s)'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    final tasks = p.visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          PopupMenuButton<SortMode>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort),
            onSelected: p.setSort,
            itemBuilder: (_) => [
              for (final m in SortMode.values)
                PopupMenuItem(
                  value: m,
                  child: Row(
                    children: [
                      Icon(m == p.sort ? Icons.check : null, size: 18),
                      const SizedBox(width: 12),
                      Text(m.label),
                    ],
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (_) => _clearCompleted(p),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Remover concluídas'),
              ),
            ],
          ),
        ],
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: StatsHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: p.setQuery,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar tarefas...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: p.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  p.setQuery('');
                                },
                              ),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: FilterBar()),
                if (tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: p.stats.total == 0
                        ? const EmptyState(
                            icon: Icons.task_alt,
                            title: 'Nenhuma tarefa ainda',
                            message:
                                'Toque em "Nova tarefa" e experimente a adição rápida: '
                                '"Estudar para prova sexta #estudo !alta"',
                          )
                        : EmptyState(
                            icon: Icons.search_off,
                            title: 'Nada encontrado',
                            message: 'Ajuste a busca ou os filtros.',
                            actionLabel: 'Limpar filtros',
                            onAction: () => _clearAll(p),
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                    sliver: SliverList.builder(
                      itemCount: tasks.length,
                      itemBuilder: (_, i) => TaskTile(task: tasks[i]),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
    );
  }
}
