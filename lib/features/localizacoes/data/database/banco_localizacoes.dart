import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  /// [abridor] permite substituir a abertura do banco (usado nos testes).
  BancoLocalizacoes({Future<Database> Function()? abridor})
    : _abridor = abridor;

  static const nomeArquivo = 'localizacoes.db';
  static const nomeTabela = 'localizacoes';
  static const _versao = 1;

  final Future<Database> Function()? _abridor;
  Future<Database>? _conexao;

  /// Abre (ou cria) o banco no caminho informado, com o esquema da tabela.
  static Future<Database> abrirEm(String caminho) {
    return openDatabase(
      caminho,
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
    final abridor = _abridor;
    if (abridor != null) return abridor();
    final pasta = await getDatabasesPath();
    return abrirEm(p.join(pasta, nomeArquivo));
  }

  Future<void> fechar() async {
    final conexao = _conexao;
    _conexao = null;
    if (conexao != null) await (await conexao).close();
  }
}
