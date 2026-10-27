# Checklist manual (aparelho Android)

Critérios que testes automatizados não cobrem. Marque após validar num aparelho
real, anotando data e modelo.

## Spec 01 - Coleta

- [ ] Coleta segue ativa com o app minimizado.
- [ ] Notificação visível enquanto a coleta está ativa (Android 13+: permissão de notificações concedida).
- [ ] Posições são gravadas aproximadamente a cada 20 s.
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
