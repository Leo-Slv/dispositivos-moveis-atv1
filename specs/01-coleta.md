# Spec 01 - Coleta de localização

Arquivos: `servico_localizacao.dart`, `tela_coleta.dart`, `repositorio_localizacoes.dart`.

## Tela inicial

- Botões: Iniciar coleta, Parar coleta, Consultar histórico, Ver mapa, Configurações de permissão.
- Iniciar e Parar são habilitados conforme o estado da coleta (nunca ambos ativos).

## Iniciar coleta

1. Verificar se o serviço de localização (GPS) está habilitado.
2. Verificar e solicitar a permissão de localização quando necessário.
3. Orientar o usuário se a permissão for negada ou exigir habilitação nas configurações.
4. Assinar um stream de posições com alta precisão e intervalo solicitado de 20 s.
5. Salvar cada posição recebida no SQLite via repositório.
6. Evitar assinaturas duplicadas e gravações sobrepostas.

## Segundo plano

- Android: serviço em primeiro plano com notificação visível enquanto a coleta estiver ativa.
- A coleta continua ao navegar entre telas e ao minimizar o app.
- O intervalo pode variar conforme o SO e a disponibilidade de localização.
- Reinício automático após encerrar o processo/reiniciar o aparelho NÃO é obrigatório.

## Parar coleta

- Cancelar a assinatura do stream e liberar recursos.

## Critérios de aceite

- [x] GPS desligado e permissão negada geram orientação ao usuário.
- [x] Duplo toque em Iniciar não cria duas assinaturas.
- [ ] Coleta segue ativa com o app minimizado (notificação visível no Android).
- [x] Parar cancela a assinatura.
- [x] Sem `Timer.periodic` nem `workmanager`.
- [x] "Configurações de permissão" abre as configurações do app.
