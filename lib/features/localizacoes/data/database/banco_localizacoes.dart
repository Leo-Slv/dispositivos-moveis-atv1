import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  BancoLocalizacoes();

  static const nomeArquivo = 'localizacoes.db';
  static const nomeTabela = 'localizacoes';
  static const _versao = 1;

  Future<Database>? _conexao;

  /// Reutiliza a conexão aberta. Se a abertura falhar, descarta o resultado
  /// para que a próxima chamada tente abrir o banco novamente.
  Future<Database> get database async {
    final conexao = _conexao ??= _abrir();
    try {
      return await conexao;
    } catch (_) {
      if (identical(_conexao, conexao)) _conexao = null;
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    return openDatabase(
      p.join(pasta, nomeArquivo),
      version: _versao,
      onCreate: (db, versao) => db.execute('''
        CREATE TABLE $nomeTabela (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          precisao REAL NOT NULL,
          instante TEXT NOT NULL
        )
      '''),
    );
  }

  Future<void> fechar() async {
    final conexao = _conexao;
    _conexao = null;
    if (conexao != null) await (await conexao).close();
  }
}
