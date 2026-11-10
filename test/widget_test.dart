import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerenciador_tarefas/data/task_repository.dart';
import 'package:gerenciador_tarefas/main.dart';
import 'package:gerenciador_tarefas/providers/task_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('estado vazio e adição rápida', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = TaskProvider(TaskRepository());
    await tester.runAsync(provider.load);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: provider, child: const TaskApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minhas Tarefas'), findsOneWidget);
    expect(find.text('Nenhuma tarefa ainda'), findsOneWidget);

    // Abre a adição rápida
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      'Estudar para prova sexta #estudo !alta',
    );
    await tester.pump();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Estudar para prova'), findsWidgets);
    expect(find.text('Nenhuma tarefa ainda'), findsNothing);
    expect(provider.allTasks.single.priority.label, 'Alta');
  });
}
