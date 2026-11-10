# Gerenciador de Tarefas Inteligente — Flutter

App de tarefas multiplataforma (Android, iOS e Web) feito em **Flutter / Dart**.

## Por que Flutter?

- **Um código, várias plataformas**: o mesmo projeto gera APK (Android), IPA (iOS) e Web.
- **Renderização própria**: o Flutter desenha cada pixel com sua engine (Impeller/Skia), sem depender dos componentes nativos. Por isso a interface fica idêntica em todas as plataformas.
- **Bom contraste com React Native**: os dois são multiplataforma, mas o RN usa JavaScript e componentes nativos, enquanto o Flutter compila Dart para código nativo (AOT) e desenha a própria UI.

## Funcionalidades

| Requisito do trabalho | 
| Criar, editar e excluir tarefas | `screens/task_form_screen.dart`, `widgets/quick_add_sheet.dart`, deslizar para excluir em `widgets/task_tile.dart` (com **Desfazer**) |
| Categorias (Trabalho, Estudo, Pessoal, Saúde, Outros) | `models/task.dart` → `TaskCategory` |
| Prioridades (Alta, Média, Baixa) | `models/task.dart` → `TaskPriority` |
| Marcar como concluída | Caixa de seleção no item, ou chave "Concluída" na edição |
| Buscar e filtrar | Busca por título/descrição (ignora acentos) + filtros por status, categoria e prioridade (`widgets/filter_bar.dart`) |
| Persistência local | `data/task_repository.dart` (JSON + `shared_preferences`) |

### O que tem de "inteligente"

1. **Adição rápida em linguagem natural** (`utils/smart_parser.dart`). Você escreve uma frase e o app extrai os dados:
   - `Entregar relatório amanhã #trabalho !alta` → categoria Trabalho, prioridade Alta, prazo amanhã
   - `Estudar para prova sexta` → categoria **Estudo deduzida** pelas palavras-chave, prazo na sexta
   - `Consulta no médico 05/11 urgente` → Saúde, Alta, 05/11
   - Entende: `hoje`, `amanhã`, `depois de amanhã`, dias da semana, `dd/mm` ou `dd/mm/aaaa`, `#categoria`, `!alta`/`!media`/`!baixa`, `urgente`/`importante`.
2. **Ordenação inteligente** (`utils/smart_score.dart`): combina prioridade e proximidade do prazo. Uma tarefa média que vence hoje passa na frente de uma alta sem prazo, e as atrasadas sobem ao topo.
3. **Sugestão "Comece por"** no painel: indica a tarefa pendente mais urgente.
4. **Categoria sugerida** no formulário enquanto você digita o título.
5. Painel com progresso, pendentes, tarefas para hoje e tarefas atrasadas.

## Estrutura do projeto

```
lib/
├── main.dart                    # Ponto de entrada, tema (claro/escuro), localização pt-BR
├── models/
│   └── task.dart                # Modelo Task + enums de categoria e prioridade
├── data/
│   └── task_repository.dart     # Persistência local (shared_preferences)
├── providers/
│   └── task_provider.dart       # Estado global (ChangeNotifier): CRUD, busca, filtros, ordenação
├── screens/
│   ├── home_screen.dart         # Lista principal
│   └── task_form_screen.dart    # Criar/editar
├── widgets/
│   ├── task_tile.dart           # Item da lista (concluir, editar, deslizar p/ excluir)
│   ├── quick_add_sheet.dart     # Adição rápida inteligente
│   ├── filter_bar.dart          # Chips de filtro
│   ├── stats_header.dart        # Painel de progresso + sugestão
│   └── empty_state.dart
└── utils/
    ├── smart_parser.dart        # Interpretação de linguagem natural
    ├── smart_score.dart         # Pontuação da ordenação inteligente
    └── date_format.dart         # Datas em pt-BR
test/                            # Testes de unidade e de widget
```

### Gerenciamento de estado

Usamos **Provider + ChangeNotifier**, a abordagem recomendada na documentação oficial para apps deste porte:

- `TaskProvider` guarda a lista e os filtros. Cada alteração chama `notifyListeners()`.
- As telas usam `context.watch<TaskProvider>()` (que reconstrói a tela) ou `context.read<TaskProvider>()` (que só executa uma ação).
- Toda alteração é salva imediatamente pelo `TaskRepository`.

No React Native, o equivalente seria `Context` + `useReducer`, ou uma biblioteca como Zustand ou Redux.

## Como rodar

**Pré-requisitos:** [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.27 ou superior, Android Studio (com emulador) ou um celular com depuração USB. Para gerar a versão de iOS é preciso um Mac com Xcode.

```bash
# 1. Gerar as pastas de plataforma (android/, ios/, web/)
#    O comando não sobrescreve os arquivos de lib/ nem de test/
flutter create . --project-name gerenciador_tarefas --org br.edu.unochapeco --platforms=android,ios,web

# 2. Instalar as dependências
flutter pub get

# 3. Verificar o ambiente
flutter doctor

# 4. Rodar (escolha o dispositivo)
flutter run              # emulador ou celular conectado
flutter run -d chrome    # no navegador
```

Com o app rodando, pressione `r` no terminal para **hot reload** ou `R` para hot restart.

### Testes

```bash
flutter analyze
flutter test
```

## Build e deploy

```bash
# Android
flutter build apk --release          # APK único → build/app/outputs/flutter-apk/app-release.apk
flutter build apk --split-per-abi    # APKs menores, um por arquitetura
flutter build appbundle              # .aab para publicar na Google Play

# iOS (somente em macOS)
flutter build ipa                    # depois envie pelo Xcode / Transporter para a App Store

# Web
flutter build web                    # → build/web
```

Para publicar na Play Store é preciso assinar o app com uma keystore, e o `flutter build appbundle` usa as configurações de `android/key.properties`.
Para a App Store, é necessária uma conta Apple Developer.

### Performance

- Em release, o Dart é compilado **AOT** para código de máquina ARM, então não existe ponte JavaScript.
- A engine Impeller desenha a 60/120 fps.
- O APK mínimo do Flutter tem por volta de 5 a 7 MB por ABI, porque inclui a engine. O `--split-per-abi` ajuda a reduzir.
- Na lista usamos `SliverList.builder`, que só constrói os itens visíveis na tela.
