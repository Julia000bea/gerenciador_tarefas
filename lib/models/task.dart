import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/date_format.dart';

/// Categorias disponíveis para as tarefas.
enum TaskCategory {
  trabalho('Trabalho', Icons.work_outline, Color(0xFF3B6FD8)),
  estudo('Estudo', Icons.school_outlined, Color(0xFF8E44AD)),
  pessoal('Pessoal', Icons.person_outline, Color(0xFF16A085)),
  saude('Saúde', Icons.favorite_outline, Color(0xFFE0567A)),
  outros('Outros', Icons.label_outline, Color(0xFF7F8C8D));

  const TaskCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Níveis de prioridade. [weight] é usado na ordenação inteligente.
enum TaskPriority {
  alta('Alta', 3, Color(0xFFD64545)),
  media('Média', 2, Color(0xFFE6A23C)),
  baixa('Baixa', 1, Color(0xFF43A047));

  const TaskPriority(this.label, this.weight, this.color);

  final String label;
  final int weight;
  final Color color;
}

/// Modelo imutável de uma tarefa.
@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = TaskCategory.outros,
    this.priority = TaskPriority.media,
    this.dueDate,
    this.done = false,
    required this.createdAt,
    this.completedAt,
  });

  /// Cria uma nova tarefa com id e data de criação gerados automaticamente.
  factory Task.create({
    required String title,
    String description = '',
    TaskCategory category = TaskCategory.outros,
    TaskPriority priority = TaskPriority.media,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return Task(
      id: '${now.microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}',
      title: title,
      description: description,
      category: category,
      priority: priority,
      dueDate: dueDate == null ? null : dateOnly(dueDate),
      createdAt: now,
    );
  }

  static final Random _random = Random();

  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool done;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Tarefa pendente cujo prazo já passou.
  bool isOverdueOn(DateTime today) =>
      !done && dueDate != null && daysBetween(today, dueDate!) < 0;

  /// Tarefa pendente com prazo para hoje.
  bool isDueOn(DateTime today) =>
      !done && dueDate != null && daysBetween(today, dueDate!) == 0;

  Task copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? done,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: clearDueDate
          ? null
          : (dueDate != null ? dateOnly(dueDate) : this.dueDate),
      done: done ?? this.done,
      createdAt: createdAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'done': done,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;

    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: TaskCategory.values.asNameMap()[json['category']] ??
          TaskCategory.outros,
      priority: TaskPriority.values.asNameMap()[json['priority']] ??
          TaskPriority.media,
      dueDate: parseDate(json['dueDate']),
      done: json['done'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      completedAt: parseDate(json['completedAt']),
    );
  }
}
