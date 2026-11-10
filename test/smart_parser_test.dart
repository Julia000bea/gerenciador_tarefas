import 'package:flutter_test/flutter_test.dart';
import 'package:gerenciador_tarefas/models/task.dart';
import 'package:gerenciador_tarefas/utils/smart_parser.dart';

void main() {
  // Quinta-feira, 22/10/2026
  final now = DateTime(2026, 10, 22, 19, 0);

  group('SmartParser', () {
    test('tag, prioridade e "amanhã"', () {
      final r = SmartParser.parse(
        'Entregar relatório amanhã #trabalho !alta',
        now: now,
      );
      expect(r.title, 'Entregar relatório');
      expect(r.category, TaskCategory.trabalho);
      expect(r.categoryInferred, isFalse);
      expect(r.priority, TaskPriority.alta);
      expect(r.dueDate, DateTime(2026, 10, 23));
    });

    test('dia da semana e categoria deduzida', () {
      final r = SmartParser.parse('Estudar para prova sexta', now: now);
      expect(r.title, 'Estudar para prova');
      expect(r.category, TaskCategory.estudo);
      expect(r.categoryInferred, isTrue);
      expect(r.priority, isNull);
      expect(r.dueDate, DateTime(2026, 10, 23));
    });

    test('mesmo dia da semana vai para a próxima semana', () {
      final r = SmartParser.parse('Academia quinta', now: now);
      expect(r.dueDate, DateTime(2026, 10, 29));
      expect(r.category, TaskCategory.saude);
    });

    test('data dd/mm e "urgente"', () {
      final r = SmartParser.parse('Consulta no médico 05/11 urgente', now: now);
      expect(r.title, 'Consulta no médico');
      expect(r.category, TaskCategory.saude);
      expect(r.priority, TaskPriority.alta);
      expect(r.dueDate, DateTime(2026, 11, 5));
    });

    test('data já passada sem ano vai para o próximo ano', () {
      final r = SmartParser.parse('Pagar conta 10/01', now: now);
      expect(r.dueDate, DateTime(2027, 1, 10));
      expect(r.category, TaskCategory.pessoal);
    });

    test('"depois de amanhã" com prefixo "para"', () {
      final r = SmartParser.parse('Reunião para depois de amanhã', now: now);
      expect(r.title, 'Reunião');
      expect(r.dueDate, DateTime(2026, 10, 24));
      expect(r.category, TaskCategory.trabalho);
    });

    test('texto sem pistas fica sem metadados', () {
      final r = SmartParser.parse('comprar presente pro Pedro', now: now);
      expect(r.title, 'Comprar presente pro Pedro');
      expect(r.priority, isNull);
      expect(r.dueDate, isNull);
    });
  });
}
