# Atividade 1 - Coleta e visualização de localizações

Programação para Dispositivos Móveis I - Prof. Arley

Aplicativo Flutter (Android) que coleta a localização do aparelho continuamente
por meio de um stream de posições, grava em SQLite e exibe o histórico em lista
e em um mapa interativo.

## Integrantes

- Leonardo da Silva Irineu

## Entrega

- Prazo: 02/11/2026 (link do repositório enviado pelo Teams)
- Avaliação: 10/11/2026

## Funcionalidades

- **Coleta:** iniciar e parar; stream de alta precisão com intervalo solicitado de
  20 s; serviço em primeiro plano com notificação no Android; verificação de GPS e
  permissões, com orientação ao usuário.
- **Sem sinal de GPS:** se nenhuma posição chegar em 30 s (por exemplo, em
  ambiente fechado), a coleta passa a aceitar Wi-Fi/rede móvel, com precisão
  menor, e informa o usuário. Depende do Google Play Services.
- **Histórico:** últimas 100 localizações (data e hora locais, latitude e longitude
  com 6 casas, precisão em metros), atualização e limpeza com confirmação.
- **Mapa:** ruas do OpenStreetMap com cache em pasta privada do app, marcadores,
  posição mais recente em vermelho, enquadramento dos pontos e atualização.
- **Persistência:** banco `localizacoes.db` (SQLite), instantes em UTC.

## Estrutura

```
lib/
  main.dart, app.dart
  features/localizacoes/
    models/        Localizacao
    data/          BancoLocalizacoes (SQLite) e RepositorioLocalizacoes
    services/      ServicoLocalizacao (GPS, permissões, stream) e CacheMapa
    presentation/  telas (coleta, histórico, mapa) e widgets
```

## Ambiente (Docker)

O Flutter não precisa estar instalado: tudo roda em container (Docker Desktop aberto).

```bash
docker compose build
docker compose run --rm qa                                   # format, analyze e testes
docker compose run --rm flutter flutter test
```

APK para instalar no celular (fica em `dist/`; o `build/` fica em um volume Docker):

```bash
docker compose run --rm flutter sh -c "flutter build apk --release && mkdir -p dist && cp build/app/outputs/flutter-apk/app-release.apk dist/"
```

Copie `dist/app-release.apk` para o aparelho (ou use `adb install`), permita a
instalação de fontes desconhecidas, abra o app e aceite as permissões de
localização e de notificações. O mapa precisa de internet. O app não executa no
container; a coleta precisa ser validada em um aparelho Android.

## Qualidade

O mesmo comando `docker compose run --rm qa` roda no CI (GitHub Actions) e no hook
de pré-commit (`git config core.hooksPath .githooks`). Critérios que exigem
aparelho estão em [specs/checklist-manual.md](specs/checklist-manual.md).

## Documentação

- Enunciado: [Docs/](Docs/)
- Especificações por funcionalidade: [specs/](specs/)
