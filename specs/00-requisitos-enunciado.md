# Spec 00 - Requisitos do enunciado (matriz de rastreabilidade)

Fonte: `Docs/Atividade 1 - Coleta e visualização de localizações.pdf`.
Cada requisito do PDF tem um ID (`Rnn`), a evidência que o comprova e o estado.
Só se marca `[x]` com evidência (teste automatizado ou verificação no APK);
o que exige aparelho fica em `[ ]` e em `checklist-manual.md`.

Legenda de evidência: **teste** = arquivo em `test/`; **APK** = conferido dentro do
APK de release; **manual** = precisa de aparelho; **usuário** = ação de quem entrega.

## A. Entrega

- [x] R01 Nomes dos integrantes no repositório (README; `arquitetura_test`).
- [ ] R02 Link do repositório enviado ao professor pelo Teams até 02/11/2026 (usuário).
- [x] R03 Estrutura mínima de pastas e arquivos do enunciado (`arquitetura_test`).
- [x] R04 Arquivos adicionais só com responsabilidade clara; sem camadas vazias (revisão: nenhum `.gitkeep`, nenhuma pasta vazia).
- [x] R05 `main.dart` não concentra a implementação (`arquitetura_test`).

## B. Responsabilidade de cada arquivo

- [x] R06 `main.dart` inicializa o Flutter e executa o widget raiz; `app.dart` configura o `MaterialApp` e a tela inicial.
- [x] R07 `localizacao.dart`: registro tipado (id, latitude, longitude, precisão, instante) com conversão de/para mapa (`localizacao_test`).
- [x] R08 `banco_localizacoes.dart`: abre o banco, define versão, cria tabela, reutiliza a conexão e permite nova tentativa (`repositorio_localizacoes_test`).
- [x] R09 `repositorio_localizacoes.dart`: inserir, consultar e excluir todos; consulta devolve `Localizacao` (`repositorio_localizacoes_test`).
- [x] R10 `servico_localizacao.dart`: verifica GPS e permissões, fornece o stream e abre as configurações do app (`servico_localizacao_test`, `tela_coleta_test`).
- [x] R11 `cache_mapa.dart`: prepara o armazenamento das imagens do mapa em pasta privada antes de carregá-las (`cache_mapa_test`).
- [x] R12 `tela_coleta.dart`: controles, assinatura do stream e gravação pelo repositório (`tela_coleta_test`).
- [x] R13 `tela_localizacoes.dart`: histórico, atualização e confirmação de exclusão (`tela_localizacoes_test`).
- [x] R14 `tela_mapa.dart`: carrega registros e trata espera, erro e vazio antes do mapa (`tela_mapa_test`).
- [x] R15 `item_localizacao.dart`: dados de uma localização, reutilizado na lista e nos detalhes do mapa (`item_localizacao_test`, `mapa_localizacoes_test`).
- [x] R16 `mapa_localizacoes.dart`: camada de ruas, marcadores e interações (`mapa_localizacoes_test`).

## C. Tela inicial - coleta (enunciado, item 1)

- [x] R17 Botões Iniciar coleta, Parar coleta, Consultar histórico, Ver mapa e Configurações de permissão (`tela_coleta_test`).
- [x] R18 Verifica se o serviço de localização está habilitado (`tela_coleta_test`: GPS desligado).
- [x] R19 Verifica e solicita a permissão de localização quando necessário (`tela_coleta_test`).
- [x] R20 Orienta o usuário se a permissão for negada ou precisar ser habilitada nas configurações (`tela_coleta_test`).
- [x] R21 Stream de posições com alta precisão e intervalo solicitado de 20 s (`servico_localizacao_test`). Desvio documentado: se o GPS não entrega nada em 30 s, aceita Wi-Fi/rede (spec 01).
- [x] R22 Salva cada posição recebida no SQLite (`tela_coleta_test`).
- [x] R23 Evita assinaturas duplicadas e gravações sobrepostas (`tela_coleta_test`).
- [x] R24 Android: serviço em primeiro plano com notificação (permissões e ícone no APK: `manifesto_test`, `icone_test`, conferência do APK).
- [ ] R24b A notificação fica visível enquanto a coleta está ativa (manual).
- [x] R25 Coleta continua ao navegar para outras telas (`tela_coleta_test`).
- [ ] R25b Coleta continua ao minimizar o app (manual).
- [x] R26 Parar coleta cancela a assinatura do stream (`tela_coleta_test`).
- [x] R27 Iniciar e Parar habilitados conforme o estado da coleta (`tela_coleta_test`).
- [x] R28 Reinício automático após encerrar o processo não é obrigatório (não implementado, de propósito).

## D. Histórico (item 2)

- [x] R29 Últimas 100 localizações, da mais recente para a mais antiga (`repositorio_localizacoes_test`, `tela_localizacoes_test`).
- [x] R30 Data e hora locais, latitude, longitude e precisão em metros (`item_localizacao_test`).
- [x] R31 Latitude/longitude com 6 casas e precisão com 1 casa (`item_localizacao_test`).
- [x] R32 Atualizar sem interromper a coleta (`tela_localizacoes_test`, `tela_coleta_test`).
- [x] R33 Botão que limpa todo o histórico, inclusive além dos 100 (`persistencia_arquivo_test`, `tela_localizacoes_test`).
- [x] R34 Confirmação com Cancelar e Limpar histórico, informando que é permanente (`tela_localizacoes_test`).
- [x] R35 Se a coleta está ativa, informa que novos registros continuarão sendo salvos (`tela_localizacoes_test`).
- [x] R36 Após excluir, atualiza a lista e mostra mensagem de sucesso (`tela_localizacoes_test`).
- [x] R37 Em caso de falha, mostra mensagem de erro (`tela_localizacoes_test`).

## E. Mapa (item 3)

- [x] R38 Últimas 100 posições salvas (`tela_mapa_test`).
- [x] R39 Camada de fundo com ruas e referências geográficas (`mapa_localizacoes_test`).
- [x] R40 Localizações representadas por marcadores (`mapa_localizacoes_test`).
- [x] R41 Localização mais recente em vermelho (`mapa_localizacoes_test`).
- [x] R42 Enquadra os pontos ao carregar (`mapa_localizacoes_test`, `tela_mapa_test`).
- [x] R43 Botão para enquadrar todos os pontos novamente (`tela_mapa_test`).
- [x] R44 Botão para atualizar os registros (`tela_mapa_test`).
- [ ] R45 Atribuição do provedor sempre visível, sem precisar tocar (hoje fica escondida atrás de um ícone).
- [ ] R45b Mapa e cache funcionando no aparelho, com internet (manual).

## F. Persistência local (item 4)

- [x] R46 Banco `localizacoes.db`, tabela `localizacoes` (`repositorio_localizacoes_test`).
- [x] R47 Colunas e tipos: id INTEGER PK AUTOINCREMENT; latitude, longitude, precisao REAL; instante TEXT, todas obrigatórias (`repositorio_localizacoes_test`).
- [x] R48 Instante gravado em UTC, ISO 8601, e exibido em horário local (`localizacao_test`, `item_localizacao_test`).
- [x] R49 Dados permanecem após fechar e reabrir o banco (`persistencia_arquivo_test`).
- [x] R49b Ao reabrir o app, a tela inicial mostra o total e a última posição já salvos no banco (`tela_coleta_test`: grupo "dados salvos").
- [ ] R49c Dados permanecem após fechar e reabrir o app no aparelho (manual).
- [x] R50 Limite de 100 só na consulta, sem excluir registros antigos (`persistencia_arquivo_test`).
- [x] R51 Limpeza remove todas as linhas, preservando a tabela e o arquivo do banco (`persistencia_arquivo_test`).

## G. Ícone (item 5)

- [x] R52 Ícone próprio, relacionado à proposta (pino de mapa; `scripts/gerar_icone.js`).
- [x] R53 Substitui o ícone padrão do Flutter no Android (`icone_test`).
- [x] R54 Imagem original em `assets/icons/localizacoes.png` (`icone_test`).
- [ ] R55 O ícone aparece corretamente na tela inicial e na lista de apps (manual).

## H. Organização e restrições (item 6)

- [x] R56 Apresentação, serviços, modelo e persistência separados (`arquitetura_test`).
- [x] R57 Sem SQL em telas ou widgets (`arquitetura_test`).
- [x] R58 Apresentação usa `Localizacao`, não mapas brutos (`arquitetura_test`, revisão).
- [x] R59 Sem `Timer.periodic` nem `workmanager` (`arquitetura_test`).
- [x] R60 Sem banco remoto nem backend (`arquitetura_test`).
- [x] R61 Erros de permissão, localização e banco tratados (`tela_coleta_test`, `tela_localizacoes_test`, `tela_mapa_test`).
- [x] R62 Assinaturas e controladores liberados no `dispose` (`tela_coleta_test`, `tela_mapa_test`).
- [x] R63 `mounted` verificado após operações assíncronas (`tela_localizacoes_test`, `tela_mapa_test`, lint `use_build_context_synchronously`).
- [x] R64 Somente dependências usadas (`arquitetura_test`).
- [x] R65 Código formatado e `flutter analyze` sem problemas (`docker compose run --rm qa`, hook e CI).
- [x] R66 Respeita as regras do provedor do mapa: agente identificado e cache (`mapa_localizacoes_test`, `cache_mapa_test`). A atribuição visível é o R45.
- [x] R67 Nenhum banco com coordenadas pessoais no repositório (`arquitetura_test`).

## I. Plataforma

- [x] R68 Plataforma escolhida: Android (README).
- [ ] R69 iOS: adaptar permissões, segundo plano e ícone, já que o enunciado cita Android/iOS (hoje o iOS não tem as chaves de localização no `Info.plist` e mantém o ícone padrão do Flutter).
