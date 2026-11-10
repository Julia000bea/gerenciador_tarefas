import 'package:flutter/foundation.dart';

import '../data/task_repository.dart';
import '../models/task.dart';
import '../utils/date_format.dart';
import '../utils/smart_parser.dart' show normalize;
import '../utils/smart_score.dart';

enum StatusFilter {
  todas('Todas'),
  pendentes('Pendentes'),
  concluidas('Concluídas'),
  atrasadas('Atrasadas');

  const StatusFilter(this.label);
  final String label;
}

enum SortMode {
  inteligente('Inteligente (prazo + prioridade)'),
  prioridade('Prioridade'),
  prazo('Prazo'),
  recentes('Mais recentes');

  const SortMode(this.label);
  final String label;
}

class TaskStats {
  const TaskStats({
    required this.total,
    required this.done,
    required this.overdue,
    required this.dueToday,
  });

  final int total;
  final int done;
  final int overdue;
  final int dueToday;

  int get pending => total - done;
  double get progress => total == 0 ? 0 : done / total;
}

/// Estado global do app: lista de tarefas, busca, filtros e ordenação.
///
/// A UI observa este objeto com `context.watch<TaskProvider>()` e é
/// reconstruída automaticamente a cada `notifyListeners()`.
class TaskProvider extends ChangeNotifier {
  TaskProvider(this._repository);

  final TaskRepository _repository;

  List<Task> _tasks = [];
  bool _loading = true;

  String _query = '';
  TaskCategory? _category;
  TaskPriority? _priority;
  StatusFilter _status = StatusFilter.todas;
  SortMode _sort = SortMode.inteligente;

  // ---------- Getters ----------
  bool get isLoading => _loading;
  List<Task> get allTasks => List.unmodifiable(_tasks);
  String get query => _query;
  TaskCategory? get category => _category;
  TaskPriority? get priority => _priority;
  StatusFilter get status => _status;
  SortMode get sort => _sort;

  bool get hasChipFilters =>
      _category != null || _priority != null || _status != StatusFilter.todas;
  bool get hasAnyFilter => hasChipFilters || _query.isNotEmpty;

  DateTime get _today => dateOnly(DateTime.now());

  /// Tarefas após busca, filtros e ordenação.
  List<Task> get visibleTasks {
    final today = _today;
    final q = normalize(_query.trim());

    final result = _tasks.where((t) {
      if (_category != null && t.category != _category) return false;
      if (_priority != null && t.priority != _priority) return false;
      switch (_status) {
        case StatusFilter.todas:
          break;
        case StatusFilter.pendentes:
          if (t.done) return false;
        case StatusFilter.concluidas:
          if (!t.done) return false;
        case StatusFilter.atrasadas:
          if (!t.isOverdueOn(today)) return false;
      }
      if (q.isNotEmpty) {
        final haystack = normalize('${t.title} ${t.description}');
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) => _compare(a, b, today));
    return result;
  }

  int _compare(Task a, Task b, DateTime today) {
    // Pendentes sempre antes das concluídas.
    if (a.done != b.done) return a.done ? 1 : -1;

    var c = 0;
    switch (_sort) {
      case SortMode.inteligente:
        c = smartScore(b, today).compareTo(smartScore(a, today));
      case SortMode.prioridade:
        c = b.priority.weight.compareTo(a.priority.weight);
      case SortMode.prazo:
        if (a.dueDate == null && b.dueDate != null) {
          c = 1;
        } else if (a.dueDate != null && b.dueDate == null) {
          c = -1;
        } else if (a.dueDate != null && b.dueDate != null) {
          c = a.dueDate!.compareTo(b.dueDate!);
        }
      case SortMode.recentes:
        c = 0;
    }
    if (c != 0) return c;
    return b.createdAt.compareTo(a.createdAt);
  }

  TaskStats get stats {
    final today = _today;
    return TaskStats(
      total: _tasks.length,
      done: _tasks.where((t) => t.done).length,
      overdue: _tasks.where((t) => t.isOverdueOn(today)).length,
      dueToday: _tasks.where((t) => t.isDueOn(today)).length,
    );
  }

  /// Sugestão inteligente: a tarefa pendente mais urgente.
  Task? get nextFocus {
    final today = _today;
    Task? best;
    var bestScore = -1;
    for (final t in _tasks.where((t) => !t.done)) {
      final s = smartScore(t, today);
      if (s > bestScore) {
        best = t;
        bestScore = s;
      }
    }
    return best;
  }

  // ---------- Carregamento ----------
  Future<void> load() async {
    _tasks = await _repository.load();
    _loading = false;
    notifyListeners();
  }

  Future<void> _persist() => _repository.save(_tasks);

  // ---------- CRUD ----------
  Future<void> add(Task task) async {
    _tasks = [..._tasks, task];
    notifyListeners();
    await _persist();
  }

  Future<void> update(Task task) async {
    _tasks = [
      for (final t in _tasks) t.id == task.id ? task : t,
    ];
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
    await _persist();
  }

  /// Usado pelo "Desfazer" após excluir.
  Future<void> restore(Task task) async {
    if (_tasks.any((t) => t.id == task.id)) return;
    await add(task);
  }

  Future<void> toggleDone(String id) async {
    _tasks = [
      for (final t in _tasks)
        if (t.id == id)
          t.done
              ? t.copyWith(done: false, clearCompletedAt: true)
              : t.copyWith(done: true, completedAt: DateTime.now())
        else
          t,
    ];
    notifyListeners();
    await _persist();
  }

  /// Remove todas as concluídas e retorna quantas foram removidas.
  Future<int> clearCompleted() async {
    final before = _tasks.length;
    _tasks = _tasks.where((t) => !t.done).toList();
    final removed = before - _tasks.length;
    if (removed > 0) {
      notifyListeners();
      await _persist();
    }
    return removed;
  }

  // ---------- Busca, filtros e ordenação ----------
  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(TaskCategory? value) {
    _category = value;
    notifyListeners();
  }

  void setPriority(TaskPriority? value) {
    _priority = value;
    notifyListeners();
  }

  void setStatus(StatusFilter value) {
    _status = value;
    notifyListeners();
  }

  void setSort(SortMode value) {
    _sort = value;
    notifyListeners();
  }

  void clearFilters({bool includeQuery = false}) {
    _category = null;
    _priority = null;
    _status = StatusFilter.todas;
    if (includeQuery) _query = '';
    notifyListeners();
  }
}
