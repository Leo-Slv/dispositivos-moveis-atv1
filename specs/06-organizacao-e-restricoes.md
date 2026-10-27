# Spec 06 - Organização e restrições transversais

## Estrutura mínima

```
lib/
  main.dart            # inicializa e executa o widget raiz
  app.dart             # MaterialApp e tela inicial
  features/localizacoes/
    models/localizacao.dart
    data/database/banco_localizacoes.dart
    data/repositories/repositorio_localizacoes.dart
    services/servico_localizacao.dart
    services/cache_mapa.dart
    presentation/screens/{tela_coleta,tela_localizacoes,tela_mapa}.dart
    presentation/widgets/{item_localizacao,mapa_localizacoes}.dart
```

Arquivos adicionais só com responsabilidade clara; sem camadas vazias; nada concentrado no `main.dart`.

## Restrições

- Sem SQL em telas/widgets; apresentação usa `Localizacao`.
- Proibido `Timer.periodic` e `workmanager` no lugar do stream.
- Proibido banco remoto/backend.
- Tratar erros de permissão, localização e banco.
- Cancelar assinaturas e liberar controladores no `dispose`.
- Checar `mounted` após operações assíncronas.
- Somente dependências usadas; código formatado (`dart format`) e `flutter analyze` sem problemas.
- Respeitar atribuição e regras do provedor do mapa.
- Não versionar bancos com coordenadas pessoais.

## Entrega

- Link do repositório enviado ao professor pelo Teams até 02/11/2026.
- Nomes dos integrantes no README.
- Avaliação em 10/11/2026 (prova individual escrita, sem consulta).
