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

## Fallback sem sinal de GPS

- A coleta sempre começa em alta precisão (GPS), como pede o enunciado.
- Se nenhuma posição chegar em 30 s (comum em ambientes fechados), a assinatura é trocada por uma de precisão reduzida, que aceita Wi-Fi/rede móvel, e o usuário é informado. Nunca há duas assinaturas ativas.
- Se nem assim chegar posição em mais 45 s, o app orienta a verificar a localização e a permissão de localização precisa.
- A tela mostra a última posição recebida. Parar e iniciar de novo volta a pedir alta precisão.
- Limite conhecido: o fallback depende do Google Play Services; em aparelhos sem ele o plugin usa o GPS do Android e o fallback pode não ajudar.

## Parar coleta

- Cancelar a assinatura do stream e liberar recursos.

## Critérios de aceite

- [x] GPS desligado e permissão negada geram orientação ao usuário.
- [x] Duplo toque em Iniciar não cria duas assinaturas.
- [ ] Coleta segue ativa com o app minimizado (notificação visível no Android).
- [x] Parar cancela a assinatura.
- [x] Sem `Timer.periodic` nem `workmanager`.
- [x] "Configurações de permissão" abre as configurações do app.
- [x] Sem posição do GPS em 30 s, passa para precisão reduzida (Wi-Fi/rede) e informa o usuário.
- [x] Após a troca há uma única assinatura ativa, e as posições continuam sendo gravadas.
- [x] Parar cancela a troca; iniciar de novo volta a pedir alta precisão.
- [x] Mostra a última posição recebida e avisa quando nenhuma chega.
- [ ] O fallback entrega posições em ambiente fechado (ver checklist manual).
