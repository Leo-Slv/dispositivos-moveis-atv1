import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

class RepositorioLocalizacoes {
  RepositorioLocalizacoes(this._banco);

  static const limitePadrao = 100;

  final BancoLocalizacoes _banco;

  /// Insere a localização e devolve o identificador gerado.
  Future<int> inserir(Localizacao localizacao) async {
    final db = await _banco.database;
    return db.insert(BancoLocalizacoes.nomeTabela, localizacao.toMap());
  }

  /// Consulta as localizações mais recentes, da mais nova para a mais antiga.
  /// O limite vale apenas para a consulta; nenhum registro é removido.
  Future<List<Localizacao>> consultarRecentes({
    int limite = limitePadrao,
  }) async {
    final db = await _banco.database;
    final linhas = await db.query(
      BancoLocalizacoes.nomeTabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.fromMap).toList();
  }

  /// Remove todas as linhas, preservando a tabela e o arquivo do banco.
  Future<void> excluirTodas() async {
    final db = await _banco.database;
    await db.delete(BancoLocalizacoes.nomeTabela);
  }
}
