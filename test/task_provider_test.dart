import 'package:flutter_test/flutter_test.dart';
import 'package:gerenciador_tarefas/data/task_repository.dart';
import 'package:gerenciador_tarefas/models/task.dart';
import 'package:gerenciador_tarefas/providers/task_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<TaskProvider> newProvider() async {
    final p = TaskProvider(TaskRepository());
    await p.load();
    return p;
  }

  test('cria, busca, filtra, conclui e persiste', () async {
    final p = await newProvider();
    await p.add(Task.create(
      title: 'Mercado',
      category: TaskCategory.pessoal,
      priority: TaskPriority.baixa,
    ));
    await p.add(Task.create(
      title: 'Estudar Flutter',
      description: 'widgets e estado',
      category: TaskCategory.estudo,
      priority: TaskPriority.alta,
    ));

    // Ordenação inteligente: alta prioridade primeiro
    expect(p.visibleTasks.map((t) => t.title).toList(),
        ['Estudar Flutter', 'Mercado']);

    // Busca sem diferenciar acentos/maiúsculas, inclusive na descrição
    p.setQuery('WIDGETS');
    expect(p.visibleTasks.single.title, 'Estudar Flutter');
    p.setQuery('');

    p.setCategory(TaskCategory.pessoal);
    expect(p.visibleTasks.single.title, 'Mercado');
    p.clearFilters();

    final id = p.visibleTasks.first.id;
    await p.toggleDone(id);
    p.setStatus(StatusFilter.concluidas);
    expect(p.visibleTasks.single.id, id);
    expect(p.visibleTasks.single.completedAt, isNotNull);

    // Recarrega do armazenamento local
    final reloaded = await newProvider();
    expect(reloaded.stats.total, 2);
    expect(reloaded.stats.done, 1);
  });

  test('prazo vencendo hoje passa na frente de prioridade alta', () async {
    final p = await newProvider();
    await p.add(Task.create(title: 'Alta sem prazo', priority: TaskPriority.alta));
    await p.add(Task.create(
      title: 'Média para hoje',
      priority: TaskPriority.media,
      dueDate: DateTime.now(),
    ));
    expect(p.visibleTasks.first.title, 'Média para hoje');
    expect(p.nextFocus?.title, 'Média para hoje');
  });

  test('editar, excluir e desfazer', () async {
    final p = await newProvider();
    final task = Task.create(title: 'Original');
    await p.add(task);

    await p.update(task.copyWith(title: 'Editada', priority: TaskPriority.alta));
    expect(p.allTasks.single.title, 'Editada');
    expect(p.allTasks.single.priority, TaskPriority.alta);

    final edited = p.allTasks.single;
    await p.delete(edited.id);
    expect(p.allTasks, isEmpty);

    await p.restore(edited);
    expect(p.allTasks.single.title, 'Editada');
  });

  test('tarefa atrasada aparece no filtro Atrasadas', () async {
    final p = await newProvider();
    await p.add(Task.create(
      title: 'Atrasada',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
    ));
    await p.add(Task.create(title: 'Em dia'));
    p.setStatus(StatusFilter.atrasadas);
    expect(p.visibleTasks.single.title, 'Atrasada');
    expect(p.stats.overdue, 1);
  });
}
