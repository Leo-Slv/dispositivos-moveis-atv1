# Spec 04 - Persistência local

Arquivos: `localizacao.dart`, `banco_localizacoes.dart`, `repositorio_localizacoes.dart`.

## Banco

Arquivo `localizacoes.db`, tabela `localizacoes`:

| Coluna    | Tipo    | Requisito                         |
|-----------|---------|-----------------------------------|
| id        | INTEGER | Chave primária com autoincremento |
| latitude  | REAL    | Obrigatória                       |
| longitude | REAL    | Obrigatória                       |
| precisao  | REAL    | Obrigatória; metros               |
| instante  | TEXT    | Obrigatória; UTC, ISO 8601        |

## Responsabilidades

- `Localizacao`: registro tipado (id, latitude, longitude, precisão, instante) com conversão de/para mapa.
- `BancoLocalizacoes`: abrir o banco, definir versão, criar tabela, reutilizar a conexão e permitir nova tentativa se a abertura falhar.
- `RepositorioLocalizacoes`: inserir, consultar (retorna `Localizacao`) e excluir todos.

## Regras

- Dados persistem após fechar/reabrir o app; a apresentação converte instantes para horário local.
- O limite de 100 registros vale só para a consulta; nada é excluído automaticamente.
- Limpeza remove todas as linhas, preservando tabela e arquivo do banco.
- Nenhum SQL em telas/widgets; sem mapas brutos na apresentação.
- Nenhum banco com coordenadas pessoais no repositório (`*.db` no `.gitignore`).
- Sem bancos remotos ou backend.
- Tratar erros de acesso ao banco.

## Critérios de aceite

- [ ] Esquema idêntico ao especificado.
- [ ] Instante gravado em UTC ISO 8601 e exibido em hora local.
- [ ] Limpar mantém a estrutura da tabela.
- [ ] Reabertura da conexão após falha.
