import 'dart:io';

import 'package:atv1_localizacoes/features/localizacoes/services/cache_mapa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory raiz;

  setUp(() => raiz = Directory.systemTemp.createTempSync('cache_mapa_test'));
  tearDown(() => raiz.deleteSync(recursive: true));

  test('cria a pasta de cache dentro da pasta privada informada', () async {
    final cache = CacheMapa(localizarRaiz: () async => raiz);

    final pasta = await cache.preparar();

    expect(pasta.existsSync(), isTrue);
    expect(pasta.parent.path, raiz.path);
    expect(pasta.path.endsWith(CacheMapa.subpasta), isTrue);
  });

  test('reutiliza a pasta nas chamadas seguintes', () async {
    var buscas = 0;
    final cache = CacheMapa(
      localizarRaiz: () async {
        buscas++;
        return raiz;
      },
    );

    final a = await cache.preparar();
    final b = await cache.preparar();

    expect(a.path, b.path);
    expect(buscas, 1);
  });

  test('tenta de novo na chamada seguinte se a preparação falhar', () async {
    var tentativas = 0;
    final cache = CacheMapa(
      localizarRaiz: () async {
        tentativas++;
        if (tentativas == 1) throw const FileSystemException('sem acesso');
        return raiz;
      },
    );

    await expectLater(cache.preparar(), throwsA(isA<FileSystemException>()));
    final pasta = await cache.preparar();

    expect(pasta.existsSync(), isTrue);
    expect(tentativas, 2);
  });

  test('o tamanho máximo do cache é limitado', () {
    expect(CacheMapa.tamanhoMaximoBytes, greaterThan(0));
  });
}
