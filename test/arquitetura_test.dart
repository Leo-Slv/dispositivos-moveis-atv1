import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _arquivosDart(String pasta) => Directory(pasta)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  final lib = _arquivosDart('lib');

  test('não usa Timer.periodic nem workmanager no lugar do stream', () {
    for (final arquivo in lib) {
      final conteudo = arquivo.readAsStringSync();
      expect(conteudo, isNot(contains('Timer.periodic')), reason: arquivo.path);
      expect(conteudo, isNot(contains('workmanager')), reason: arquivo.path);
    }
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('workmanager')),
    );
  });

  test('telas e widgets não acessam SQLite nem executam SQL', () {
    final apresentacao = lib.where((f) => f.path.contains('presentation'));
    expect(apresentacao, isNotEmpty);

    final proibidos = RegExp(
      r"package:sqflite|sqflite_common|rawQuery|rawInsert|\.execute\(|\.query\(",
    );
    for (final arquivo in apresentacao) {
      expect(
        arquivo.readAsStringSync(),
        isNot(contains(proibidos)),
        reason: arquivo.path,
      );
    }
  });

  test('apresentação não depende de bancos remotos ou backend', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final pacote in ['firebase', 'cloud_firestore', 'supabase', 'dio:']) {
      expect(pubspec, isNot(contains(pacote)));
    }
  });

  test('main.dart não concentra a implementação', () {
    final linhas = File('lib/main.dart').readAsLinesSync();
    expect(linhas.length, lessThan(40));
  });

  test('estrutura mínima de arquivos do enunciado existe', () {
    const base = 'lib/features/localizacoes';
    final arquivos = [
      'lib/main.dart',
      'lib/app.dart',
      '$base/models/localizacao.dart',
      '$base/data/database/banco_localizacoes.dart',
      '$base/data/repositories/repositorio_localizacoes.dart',
      '$base/services/servico_localizacao.dart',
      '$base/services/cache_mapa.dart',
      '$base/presentation/screens/tela_coleta.dart',
      '$base/presentation/screens/tela_localizacoes.dart',
      '$base/presentation/screens/tela_mapa.dart',
      '$base/presentation/widgets/item_localizacao.dart',
      '$base/presentation/widgets/mapa_localizacoes.dart',
      'assets/icons/localizacoes.png',
    ];
    for (final arquivo in arquivos) {
      expect(File(arquivo).existsSync(), isTrue, reason: arquivo);
    }
  });

  test('mantém apenas dependências usadas', () {
    final secoes = _dependenciasDoPubspec();
    final codigoLib = lib.map((f) => f.readAsStringSync()).join('\n');
    final codigoTeste = _arquivosDart(
      'test',
    ).map((f) => f.readAsStringSync()).join('\n');

    for (final pacote in secoes['dependencies']!) {
      if (pacote == 'flutter') continue;
      expect(
        codigoLib,
        contains('package:$pacote/'),
        reason: 'dependência $pacote',
      );
    }
    for (final pacote in secoes['dev_dependencies']!) {
      if (pacote == 'flutter_test') continue;
      if (pacote == 'flutter_lints') {
        expect(
          File('analysis_options.yaml').readAsStringSync(),
          contains('package:flutter_lints/'),
        );
        continue;
      }
      expect(codigoTeste, contains('package:$pacote/'), reason: 'dev $pacote');
    }
  });

  test('não há bancos com coordenadas pessoais no repositório', () {
    final extensoes = RegExp(r'\.(db|sqlite|sqlite3)(-journal)?$');
    for (final pasta in ['lib', 'test', 'assets', 'android/app/src']) {
      final encontrados = Directory(pasta)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => extensoes.hasMatch(f.path));
      expect(encontrados, isEmpty, reason: pasta);
    }
    final gitignore = File('.gitignore').readAsStringSync();
    expect(gitignore, contains('*.db'));
  });

  test('README informa os integrantes', () {
    expect(File('README.md').readAsStringSync(), contains('## Integrantes'));
  });
}

/// Nomes dos pacotes de `dependencies` e `dev_dependencies` do pubspec.
Map<String, List<String>> _dependenciasDoPubspec() {
  final secoes = <String, List<String>>{
    'dependencies': [],
    'dev_dependencies': [],
  };
  List<String>? atual;
  for (final linha in File('pubspec.yaml').readAsLinesSync()) {
    if (RegExp(r'^\S').hasMatch(linha)) {
      atual = secoes[linha.replaceAll(':', '').trim()];
    } else if (atual != null) {
      final nome = RegExp(r'^  ([a-z_0-9]+):').firstMatch(linha)?.group(1);
      if (nome != null) atual.add(nome);
    }
  }
  return secoes;
}
