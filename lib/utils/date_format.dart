/// Funções utilitárias de data (sem dependências externas).
library;

/// Remove a parte de horário de uma data.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Diferença em dias de calendário entre [from] e [to].
/// Usa UTC para não sofrer com horário de verão.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

const _weekdays = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// dd/MM/aaaa
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// Texto amigável para o prazo: "Hoje", "Amanhã", "Sexta", "05/11"...
String formatDueDate(DateTime due, DateTime today) {
  final diff = daysBetween(today, due);
  final short = '${_two(due.day)}/${_two(due.month)}';
  if (diff < 0) return 'Atrasada · $short';
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  if (diff < 7) return _weekdays[due.weekday - 1];
  if (due.year == today.year) return short;
  return formatDate(due);
}
