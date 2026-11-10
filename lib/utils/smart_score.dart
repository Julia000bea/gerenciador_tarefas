import 'dart:math';

import '../models/task.dart';
import 'date_format.dart';

/// Pontuação usada na ordenação "Inteligente".
///
/// Combina prioridade e urgência do prazo: uma tarefa de prioridade média
/// que vence hoje passa na frente de uma de prioridade alta sem prazo.
int smartScore(Task task, DateTime today) {
  var score = task.priority.weight * 10;
  final due = task.dueDate;
  if (due != null) {
    final days = daysBetween(today, due);
    if (days < 0) {
      score += 40 + min(-days, 10); // atrasadas sobem mais quanto mais atrasadas
    } else if (days == 0) {
      score += 30;
    } else if (days == 1) {
      score += 20;
    } else if (days <= 3) {
      score += 12;
    } else if (days <= 7) {
      score += 6;
    }
  }
  return score;
}
