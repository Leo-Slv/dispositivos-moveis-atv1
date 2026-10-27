# CLAUDE.md

Aplicativo Flutter (Android/iOS) de coleta e visualização de localizações.
Atividade 1 de Programação para Dispositivos Móveis I. Enunciado em `Docs/`,
especificações em `specs/`.

## Ambiente

Flutter NÃO está instalado no host. Tudo roda no Docker (Docker Desktop aberto):

```bash
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter dart format lib test
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
docker compose run --rm qa            # format (checagem) + analyze + test
docker compose run --rm flutter flutter build apk --debug
```

No Git Bash do Windows, prefixe com `MSYS_NO_PATHCONV=1` e use `-T` fora de terminal interativo.
O app não executa no container (GPS, serviço em primeiro plano); validar em aparelho Android.

## Workflow

Por spec, sempre nesta ordem:

1. Ler a spec em `specs/NN-*.md` e o enunciado em `Docs/` quando houver dúvida.
2. Escrever/ajustar os testes que provam os critérios de aceite.
3. Implementar em passos pequenos.
4. Rodar `docker compose run --rm qa` (o hook de pré-commit também roda).
5. Commitar cada passo lógico separadamente.
6. Marcar na spec apenas os critérios comprovados por teste; os que dependem de aparelho vão em `specs/checklist-manual.md`.
7. Após cada commit, informar: o que foi implementado e quais critérios de aceite foram atendidos (e quais ficaram pendentes).

Ordem das specs: 04 persistência (feita), 01 coleta, 02 histórico, 03 mapa, 05 ícone, 06 organização.

## Commits

- Mensagens em português, formato Conventional Commits: `feat(escopo): ...`, `fix`, `test`, `docs`, `chore`, `refactor`, `ci`.
- Um passo lógico por commit; nada de commit gigante.
- NUNCA adicionar `Co-Authored-By` nem atribuição ao Claude nos commits.
- Não usar `--no-verify`. Se o hook falhar, corrigir a causa.
- Não commitar sem os testes passando.

## Arquitetura

```
lib/
  main.dart, app.dart
  features/localizacoes/
    models/        Localizacao (tipado, toMap/fromMap)
    data/database/ BancoLocalizacoes (conexão única, reabertura após falha)
    data/repositories/ RepositorioLocalizacoes (inserir, consultarRecentes, excluirTodas)
    services/      ServicoLocalizacao (GPS, permissões, stream), CacheMapa
    presentation/screens/  telas
    presentation/widgets/  widgets reutilizáveis
```

Regras:

- Telas/widgets NUNCA executam SQL nem importam sqflite; usam o repositório e objetos `Localizacao`.
- Sem mapas brutos do SQLite fora de `models/` e `data/`.
- Coleta somente via stream de posições. Proibido `Timer.periodic` e `workmanager`.
- Sem backend/banco remoto. Sem `*.db` versionado.
- Dependências entram pelo repositório/serviço via construtor (permite fakes nos testes).
- Não criar camadas/arquivos sem responsabilidade clara; não concentrar lógica no `main.dart`.
- Instantes: UTC ISO 8601 no banco; converter para local só na apresentação.
- Limite de 100 registros só na consulta; nunca apagar automaticamente.

## Padrões de código

- Nomes de domínio em português (`Localizacao`, `RepositorioLocalizacoes`, `tela_coleta.dart`), arquivos em `snake_case`.
- Textos de UI em português.
- Após `await` em `State`, checar `mounted` antes de `setState`/`context`.
- Cancelar `StreamSubscription` e liberar controllers no `dispose`.
- Tratar e informar ao usuário erros de permissão, localização e banco (SnackBar/diálogo).
- Futures sem await: usar `unawaited(...)` explicitamente.
- Código formatado com `dart format`; `flutter analyze` sem nenhum aviso (lints em `analysis_options.yaml`).
- `ignore` de lint só pontual, com motivo claro.
- Manter apenas dependências usadas.

## Testes

- Unitários/widget em `test/`, nomes descritivos em português.
- Banco: `sqflite_common_ffi` em memória (`BancoLocalizacoes(abridor: ...)`).
- Telas: fakes de `ServicoLocalizacao` e `RepositorioLocalizacoes`.
- `test/arquitetura_test.dart` guarda as restrições do enunciado; não enfraquecer.
- Todo critério de aceite automatizável precisa de teste; o restante vai para o checklist manual.

## Qualidade e CI

- Local: `docker compose run --rm qa` e hook `.githooks/pre-commit` (ativar com `git config core.hooksPath .githooks`).
- Remoto: `.github/workflows/ci.yml` roda `scripts/qa.sh`.

## Entrega

Link do repositório ao professor pelo Teams até 02/11/2026, com os nomes dos integrantes no README. Avaliação em 10/11/2026.
