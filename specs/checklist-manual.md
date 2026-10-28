# Checklist manual (aparelho Android)

Critérios que testes automatizados não cobrem. Marque após validar num aparelho
real, anotando data e modelo.

## Spec 01 - Coleta

- [ ] Coleta segue ativa com o app minimizado.
- [ ] Notificação visível enquanto a coleta está ativa (Android 13+: permissão de notificações concedida).
- [ ] Posições são gravadas aproximadamente a cada 20 s.
- [ ] Dentro de um prédio, sem GPS: após ~30 s aparece o aviso de Wi-Fi/rede e chegam posições (precisão menor).
- [ ] Ao ar livre, as posições chegam em alta precisão, sem o aviso de Wi-Fi/rede.
- [ ] Coleta continua ao navegar para histórico e mapa.
- [ ] Diálogo de GPS desligado/permissão negada aparece no aparelho e leva às configurações certas.

## Spec 02 - Histórico

- [ ] Atualizar a lista durante a coleta não a interrompe.

## Spec 03 - Mapa

- [ ] Camada de ruas carrega e a atribuição do provedor aparece.
- [ ] Marcador mais recente aparece em vermelho.
- [ ] Enquadramento inicial e botão de enquadrar funcionam.
- [ ] Cache das imagens fica em pasta privada do app.

## Spec 04 - Persistência

- [ ] Dados permanecem após fechar e reabrir o app.

## Spec 05 - Ícone

- [ ] Ícone próprio aparece na tela inicial e na lista de aplicativos.

## Spec 06 - Entrega

- [x] Criar o repositório remoto (GitHub) e enviar o código (https://github.com/Leo-Slv/dispositivos-moveis-atv1).
- [x] Confirmar que o CI (GitHub Actions) passa (run 40525152463, 27/10/2026).
- [ ] Enviar o link do repositório ao professor pelo Teams até 02/11/2026.
