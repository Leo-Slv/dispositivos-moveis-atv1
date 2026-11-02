import 'dart:io';

import 'package:atv1_localizacoes/features/localizacoes/data/database/banco_localizacoes.dart';
import 'package:atv1_localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Localizacao _em(int minutos) => Localizacao(
  latitude: -23.5505 + minutos / 1000,
  longitude: -46.6333,
  precisao: 8.25,
  instante: DateTime.utc(2026, 11, 2, 12).add(Duration(minutes: minutos)),
);

/// Simula "fechar e reabrir o app": uma conexão nova, sem estado em memória,
/// sobre o mesmo arquivo em disco.
(BancoLocalizacoes, RepositorioLocalizacoes) _abrirApp(String caminho) {
  final banco = BancoLocalizacoes(
    abridor: () => BancoLocalizacoes.abrirEm(caminho),
  );
  return (banco, RepositorioLocalizacoes(banco));
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory pasta;
  late String caminho;

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('persistencia_test');
    caminho = '${pasta.path}${Platform.pathSeparator}localizacoes.db';
  });

  tearDown(() => pasta.deleteSync(recursive: true));

  test('os dados permanecem após fechar e reabrir o banco', () async {
    final (bancoPrimeira, primeira) = _abrirApp(caminho);
    await primeira.inserir(_em(1));
    await primeira.inserir(_em(2));
    await primeira.inserir(_em(3));
    await bancoPrimeira.fechar();

    final (bancoReaberta, reaberta) = _abrirApp(caminho);
    final lista = await reaberta.consultarRecentes();
    await bancoReaberta.fechar();

    expect(lista, hasLength(3));
    expect(lista.map((l) => l.instante), [
      _em(3).instante,
      _em(2).instante,
      _em(1).instante,
    ]);
    expect(lista.first.latitude, _em(3).latitude);
    expect(lista.first.precisao, 8.25);
  });

  test('registros gravados depois de reabrir somam aos anteriores', () async {
    final (bancoPrimeira, primeira) = _abrirApp(caminho);
    await primeira.inserir(_em(1));
    await bancoPrimeira.fechar();

    final (bancoSegunda, segunda) = _abrirApp(caminho);
    await segunda.inserir(_em(2));
    await bancoSegunda.fechar();

    final (bancoTerceira, terceira) = _abrirApp(caminho);
    final lista = await terceira.consultarRecentes();
    await bancoTerceira.fechar();

    expect(lista, hasLength(2));
  });

  test('o limite de 100 não apaga nada ao reabrir', () async {
    final (bancoPrimeira, primeira) = _abrirApp(caminho);
    for (var i = 0; i < 130; i++) {
      await primeira.inserir(_em(i));
    }
    await bancoPrimeira.fechar();

    final (bancoReaberta, reaberta) = _abrirApp(caminho);
    final exibidas = await reaberta.consultarRecentes();
    final total = await reaberta.contar();
    await bancoReaberta.fechar();

    expect(exibidas, hasLength(100));
    expect(total, 130);
  });

  test(
    'limpar preserva o arquivo do banco e a tabela, mesmo ao reabrir',
    () async {
      final (bancoPrimeira, primeira) = _abrirApp(caminho);
      await primeira.inserir(_em(1));
      await primeira.excluirTodas();
      await bancoPrimeira.fechar();

      expect(File(caminho).existsSync(), isTrue);

      final (bancoReaberta, reaberta) = _abrirApp(caminho);
      expect(await reaberta.consultarRecentes(), isEmpty);
      await reaberta.inserir(_em(2));
      expect(await reaberta.consultarRecentes(), hasLength(1));
      await bancoReaberta.fechar();
    },
  );
}
