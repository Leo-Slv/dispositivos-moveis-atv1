import 'package:atv1_localizacoes/features/localizacoes/data/database/banco_localizacoes.dart';
import 'package:atv1_localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Localizacao _em(int minutos) => Localizacao(
  latitude: -23.5,
  longitude: -46.6,
  precisao: 5.5,
  instante: DateTime.utc(2026, 11, 2, 12).add(Duration(minutes: minutos)),
);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late BancoLocalizacoes banco;
  late RepositorioLocalizacoes repositorio;

  setUp(() {
    banco = BancoLocalizacoes(
      abridor: () => BancoLocalizacoes.abrirEm(inMemoryDatabasePath),
    );
    repositorio = RepositorioLocalizacoes(banco);
  });

  tearDown(() => banco.fechar());

  group('esquema', () {
    test('tabela localizacoes tem as colunas e tipos especificados', () async {
      final db = await banco.database;
      final colunas = await db.rawQuery(
        'PRAGMA table_info(${BancoLocalizacoes.nomeTabela})',
      );
      final porNome = {for (final c in colunas) c['name']: c};

      expect(porNome.keys, [
        'id',
        'latitude',
        'longitude',
        'precisao',
        'instante',
      ]);
      expect(porNome['id']!['type'], 'INTEGER');
      expect(porNome['id']!['pk'], 1);
      for (final nome in ['latitude', 'longitude', 'precisao']) {
        expect(porNome[nome]!['type'], 'REAL');
        expect(porNome[nome]!['notnull'], 1);
      }
      expect(porNome['instante']!['type'], 'TEXT');
      expect(porNome['instante']!['notnull'], 1);

      final ddl = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE name = 'localizacoes'",
      );
      expect(ddl.single['sql'], contains('AUTOINCREMENT'));
    });

    test('nome do arquivo do banco é localizacoes.db', () {
      expect(BancoLocalizacoes.nomeArquivo, 'localizacoes.db');
    });
  });

  group('conexão', () {
    test('reabre o banco na chamada seguinte após falha na abertura', () async {
      var tentativas = 0;
      final instavel = BancoLocalizacoes(
        abridor: () {
          tentativas++;
          if (tentativas == 1) throw StateError('falha simulada');
          return BancoLocalizacoes.abrirEm(inMemoryDatabasePath);
        },
      );
      addTearDown(instavel.fechar);

      await expectLater(instavel.database, throwsStateError);
      final db = await instavel.database;

      expect(db.isOpen, isTrue);
      expect(tentativas, 2);
    });

    test('reutiliza a mesma conexão', () async {
      var aberturas = 0;
      final unico = BancoLocalizacoes(
        abridor: () {
          aberturas++;
          return BancoLocalizacoes.abrirEm(inMemoryDatabasePath);
        },
      );
      addTearDown(unico.fechar);

      final a = await unico.database;
      final b = await unico.database;

      expect(identical(a, b), isTrue);
      expect(aberturas, 1);
    });
  });

  group('repositório', () {
    test('inserir devolve id e consulta devolve objetos Localizacao', () async {
      final id = await repositorio.inserir(_em(0));
      final lista = await repositorio.consultarRecentes();

      expect(lista, hasLength(1));
      expect(lista.single, isA<Localizacao>());
      expect(lista.single.id, id);
      expect(lista.single.instante, _em(0).instante);
      expect(lista.single.instante.isUtc, isTrue);
    });

    test('consulta ordena da mais recente para a mais antiga', () async {
      await repositorio.inserir(_em(1));
      await repositorio.inserir(_em(3));
      await repositorio.inserir(_em(2));

      final lista = await repositorio.consultarRecentes();

      expect(lista.map((l) => l.instante), [
        _em(3).instante,
        _em(2).instante,
        _em(1).instante,
      ]);
    });

    test('limite de 100 vale só na consulta, sem apagar registros', () async {
      for (var i = 0; i < 120; i++) {
        await repositorio.inserir(_em(i));
      }

      final lista = await repositorio.consultarRecentes();
      final db = await banco.database;
      final total = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM localizacoes'),
      );

      expect(lista, hasLength(100));
      expect(lista.first.instante, _em(119).instante);
      expect(lista.last.instante, _em(20).instante);
      expect(total, 120);
    });

    test('excluirTodas remove as linhas e preserva a tabela', () async {
      for (var i = 0; i < 120; i++) {
        await repositorio.inserir(_em(i));
      }

      await repositorio.excluirTodas();

      expect(await repositorio.consultarRecentes(), isEmpty);
      final db = await banco.database;
      final tabela = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'localizacoes'",
      );
      expect(tabela, hasLength(1));
      await repositorio.inserir(_em(0));
      expect(await repositorio.consultarRecentes(), hasLength(1));
    });
  });
}
