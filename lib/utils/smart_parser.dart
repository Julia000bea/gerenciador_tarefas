import '../models/task.dart';
import 'date_format.dart';

/// Resultado da interpretação de um texto livre.
class ParsedTask {
  const ParsedTask({
    required this.title,
    this.category,
    this.priority,
    this.dueDate,
    this.categoryInferred = false,
  });

  final String title;
  final TaskCategory? category;
  final TaskPriority? priority;
  final DateTime? dueDate;

  /// true quando a categoria foi deduzida por palavras-chave (sem #tag).
  final bool categoryInferred;
}

/// "Adição rápida inteligente": transforma uma frase em uma tarefa.
///
/// Exemplos:
///  * "Entregar relatório amanhã #trabalho !alta"
///  * "Estudar para prova sexta"  -> categoria Estudo deduzida
///  * "Consulta no médico 05/11 urgente"
///
/// Reconhece:
///  * Categorias: #trabalho #estudo #pessoal #saude #outros
///  * Prioridade: !alta !media !baixa, ou as palavras "urgente"/"importante"
///  * Prazo: hoje, amanhã, depois de amanhã, dias da semana, dd/mm[/aaaa]
class SmartParser {
  SmartParser._();

  static final Map<TaskCategory, List<String>> _keywords = {
    TaskCategory.estudo: [
      'prova', 'provas', 'estudar', 'estudo', 'revisar', 'faculdade',
      'aula', 'tcc', 'exercicio', 'exercicios', 'seminario', 'artigo',
      'livro', 'resumo', 'trabalho academico',
    ],
    TaskCategory.trabalho: [
      'reuniao', 'relatorio', 'cliente', 'clientes', 'email', 'projeto',
      'deploy', 'planilha', 'chefe', 'apresentar', 'proposta',
    ],
    TaskCategory.saude: [
      'medico', 'medica', 'consulta', 'academia', 'dentista', 'exame',
      'exames', 'remedio', 'treino', 'corrida', 'caminhada',
    ],
    TaskCategory.pessoal: [
      'mercado', 'compras', 'aniversario', 'pagar', 'conta', 'contas',
      'casa', 'familia', 'limpar', 'lavar', 'presente',
    ],
  };

  static const _weekdayNames = {
    'segunda': DateTime.monday,
    'terca': DateTime.tuesday,
    'quarta': DateTime.wednesday,
    'quinta': DateTime.thursday,
    'sexta': DateTime.friday,
    'sabado': DateTime.saturday,
    'domingo': DateTime.sunday,
  };

  static ParsedTask parse(String input, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());

    // Trabalhamos em duas versões do texto com o MESMO comprimento:
    // o original (para manter acentos no título) e o normalizado
    // (minúsculo e sem acentos, para facilitar as expressões regulares).
    var text = ' ${input.trim()} ';
    var norm = normalize(text);

    void removeRange(int start, int end) {
      text = text.replaceRange(start, end, ' '.padRight(end - start));
      norm = normalize(text);
    }

    // 1) Categorias por #tag
    TaskCategory? category;
    for (final m in RegExp(r'#([a-z]+)').allMatches(norm).toList()) {
      final cat = _categoryFromWord(m.group(1)!);
      if (cat != null) {
        category ??= cat;
        removeRange(m.start, m.end);
      }
    }

    // 2) Prioridade
    TaskPriority? priority;
    final prio = RegExp(r'!(alta|media|baixa)\b').firstMatch(norm);
    if (prio != null) {
      priority = TaskPriority.values.byName(prio.group(1)!);
      removeRange(prio.start, prio.end);
    }
    final urgent = RegExp(r'\b(urgente|importante)\b').firstMatch(norm);
    if (urgent != null) {
      priority ??= TaskPriority.alta;
      removeRange(urgent.start, urgent.end);
    }

    // 3) Prazo (a primeira expressão encontrada vence)
    DateTime? due;
    const prefix = r'(?:\b(?:para|pra|ate|ate o dia|no dia|dia|na|no|em)\s+)?';

    final relative = <RegExp, int>{
      RegExp('$prefix\\bdepois de amanha\\b'): 2,
      RegExp('$prefix\\bamanha\\b'): 1,
      RegExp('$prefix\\bhoje\\b'): 0,
    };
    for (final entry in relative.entries) {
      final m = entry.key.firstMatch(norm);
      if (m != null) {
        due = today.add(Duration(days: entry.value));
        removeRange(m.start, m.end);
        break;
      }
    }

    if (due == null) {
      final m = RegExp('$prefix\\b(\\d{1,2})/(\\d{1,2})(?:/(\\d{2,4}))?\\b')
          .firstMatch(norm);
      if (m != null) {
        final day = int.parse(m.group(1)!);
        final month = int.parse(m.group(2)!);
        var year = m.group(3) == null ? today.year : int.parse(m.group(3)!);
        if (year < 100) year += 2000;
        var date = DateTime(year, month, day);
        final valid = month >= 1 && month <= 12 && date.day == day;
        if (valid) {
          // Sem ano informado e data já passou -> próximo ano.
          if (m.group(3) == null && daysBetween(today, date) < 0) {
            date = DateTime(year + 1, month, day);
          }
          due = date;
          removeRange(m.start, m.end);
        }
      }
    }

    if (due == null) {
      final m = RegExp(
        '$prefix\\b(segunda|terca|quarta|quinta|sexta|sabado|domingo)(?:-feira)?\\b',
      ).firstMatch(norm);
      if (m != null) {
        final target = _weekdayNames[m.group(1)!]!;
        var ahead = (target - today.weekday + 7) % 7;
        if (ahead == 0) ahead = 7; // "quinta" dita numa quinta = próxima semana
        due = today.add(Duration(days: ahead));
        removeRange(m.start, m.end);
      }
    }

    // 4) Limpeza do título
    var title = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[\s,;:\-]+|[\s,;:\-]+$'), '');
    if (title.isEmpty) title = input.trim();
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    // 5) Categoria deduzida por palavras-chave
    var inferred = false;
    if (category == null) {
      category = inferCategory(title);
      inferred = category != null;
    }

    return ParsedTask(
      title: title,
      category: category,
      priority: priority,
      dueDate: due,
      categoryInferred: inferred,
    );
  }

  /// Deduz a categoria a partir de palavras-chave no texto.
  static TaskCategory? inferCategory(String text) {
    final n = normalize(text);
    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        if (RegExp('\\b$kw\\b').hasMatch(n)) return entry.key;
      }
    }
    return null;
  }

  static TaskCategory? _categoryFromWord(String word) {
    for (final c in TaskCategory.values) {
      if (normalize(c.label) == word || c.name == word) return c;
    }
    return null;
  }
}

const _accents = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
const _plain = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

/// Minúsculas e sem acentos, preservando o comprimento do texto.
String normalize(String s) {
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final i = _accents.indexOf(ch);
    buf.write(i >= 0 ? _plain[i] : ch);
  }
  return buf.toString().toLowerCase();
}
