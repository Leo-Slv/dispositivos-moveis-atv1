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
}
