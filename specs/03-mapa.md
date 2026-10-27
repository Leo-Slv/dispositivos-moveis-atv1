# Spec 03 - Mapa interativo

Arquivos: `tela_mapa.dart`, `mapa_localizacoes.dart`, `cache_mapa.dart`, `item_localizacao.dart`.

## Requisitos

- Apresentar as últimas 100 posições salvas.
- Camada de fundo com ruas e referências geográficas.
- Marcadores para as localizações; a mais recente em vermelho.
- Enquadrar todos os pontos ao carregar os dados.
- Botão para enquadrar todos os pontos novamente.
- Botão para atualizar os registros.
- Tratar estados de espera, erro e histórico vazio antes de exibir o mapa.
- Detalhes de uma localização podem reutilizar `item_localizacao.dart`.

## Provedor do mapa

- Respeitar atribuição e regras de uso do provedor (incluindo política de cache).
- `cache_mapa.dart` prepara o armazenamento local das imagens do mapa em pasta privada do app antes do carregamento.

## Critérios de aceite

- [x] Estados loading, erro e vazio exibidos corretamente.
- [x] Marcador mais recente em vermelho; demais em outra cor.
- [x] Enquadramento automático e via botão.
- [x] Atribuição do provedor visível.
- [x] Cache em diretório privado do app (pasta preparada; gravação dos tiles confirmada só em aparelho, ver checklist manual).
