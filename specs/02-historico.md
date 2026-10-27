# Spec 02 - Histórico

Arquivos: `tela_localizacoes.dart`, `item_localizacao.dart`, `repositorio_localizacoes.dart`.

## Listagem

- Exibir as últimas 100 localizações, da mais recente para a mais antiga.
- Cada item mostra: data/hora locais, latitude, longitude e precisão estimada (m).
- Formato: latitude/longitude com 6 casas decimais; precisão com 1 casa decimal.
- Permitir atualizar os registros sem interromper a coleta.

## Limpar histórico

- Botão para limpar TODO o histórico (inclusive registros além dos 100 exibidos).
- Confirmação com as opções Cancelar e Limpar histórico, informando que a operação é permanente.
- Se a coleta estiver ativa, avisar que novos registros continuarão sendo salvos.
- Após limpar: atualizar a lista e mostrar mensagem de sucesso; em falha, mensagem de erro.

## Critérios de aceite

- [ ] Ordem decrescente por instante, limite de 100 aplicado na consulta.
- [ ] Formatação numérica conforme especificado.
- [ ] Atualizar não interfere na coleta em andamento.
- [ ] Diálogo de confirmação com aviso de permanência e aviso de coleta ativa.
- [ ] Verificar `mounted` antes de atualizar a UI após operações assíncronas.
- [ ] Sem SQL na tela; a UI usa objetos `Localizacao`.
