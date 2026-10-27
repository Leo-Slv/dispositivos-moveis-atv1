# Atividade 1 - Coleta e visualização de localizações

Programação para Dispositivos Móveis I - Prof. Arley

Aplicativo Flutter que coleta a localização do aparelho continuamente (stream),
grava em SQLite e exibe o histórico em lista e em mapa interativo.

## Integrantes

- Leonardo da Silva Irineu

## Entrega

- Prazo: 02/11/2026 (link do repositório enviado pelo Teams)
- Avaliação: 10/11/2026

## Ambiente (Docker)

O Flutter roda em container; não é necessário instalá-lo no host.

```bash
docker compose build
docker compose run --rm flutter flutter create --org br.edu --project-name atv1_localizacoes .
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter dart format .
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
docker compose run --rm flutter flutter build apk --debug
```

O APK gerado fica em `build/app/outputs/flutter-apk/app-debug.apk`; instale-o
no aparelho (cabo USB + `adb install` no host, ou copiando o arquivo).

## Qualidade

```bash
docker compose run --rm qa
```

Roda verificação de formatação, `flutter analyze` e testes. O mesmo comando
roda no CI (GitHub Actions) e no hook de pré-commit
(`git config core.hooksPath .githooks`). Critérios que exigem aparelho estão
em [specs/checklist-manual.md](specs/checklist-manual.md).

## Documentação

- Enunciado: [Docs/](Docs/)
- Especificações por funcionalidade: [specs/](specs/)
