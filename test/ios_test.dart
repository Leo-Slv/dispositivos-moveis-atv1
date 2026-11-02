import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:atv1_localizacoes/features/localizacoes/services/servico_localizacao.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

const _plist = 'ios/Runner/Info.plist';
const _icones = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

/// Decodifica um PNG RGB sem filtros (como o gerado por `scripts/gerar_icone.js`)
/// e devolve largura, tipo de cor e o pixel (0, 0).
({int largura, int tipoCor, List<int> primeiroPixel}) _lerPng(File arquivo) {
  final bytes = arquivo.readAsBytesSync();
  final dados = ByteData.sublistView(bytes);
  final largura = dados.getUint32(16);
  final tipoCor = bytes[25];

  final idat = BytesBuilder();
  var posicao = 8;
  while (posicao < bytes.length) {
    final tamanho = dados.getUint32(posicao);
    final tipo = ascii.decode(bytes.sublist(posicao + 4, posicao + 8));
    if (tipo == 'IDAT') {
      idat.add(bytes.sublist(posicao + 8, posicao + 8 + tamanho));
    }
    posicao += 12 + tamanho;
  }
  final linhas = zlib.decode(idat.toBytes());
  // Primeiro byte da linha é o filtro; depois vêm os canais do pixel (0, 0).
  final canais = tipoCor == 2 ? 3 : 4;
  return (
    largura: largura,
    tipoCor: tipoCor,
    primeiroPixel: linhas.sublist(1, 1 + canais),
  );
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('permissões e segundo plano (Info.plist)', () {
    late String plist;

    setUp(() => plist = File(_plist).readAsStringSync());

    test('descreve o uso da localização, exigido para pedir a permissão', () {
      expect(plist, contains('<key>NSLocationWhenInUseUsageDescription</key>'));
      expect(
        plist,
        contains('<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>'),
      );
    });

    test('permite coletar a localização em segundo plano', () {
      expect(plist, contains('<key>UIBackgroundModes</key>'));
      expect(plist, contains('<string>location</string>'));
    });

    test('o nome do app é legível', () {
      expect(plist, contains('<string>Localizações</string>'));
      expect(plist, isNot(contains('Atv1 Localizacoes')));
    });
  });

  test('o serviço pede segundo plano e não pausa a coleta no iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    for (final modo in ModoPrecisao.values) {
      final config = ServicoLocalizacao().configuracao(modo);

      expect(config, isA<AppleSettings>(), reason: '$modo');
      final apple = config as AppleSettings;
      expect(apple.allowBackgroundLocationUpdates, isTrue, reason: '$modo');
      expect(apple.pauseLocationUpdatesAutomatically, isFalse, reason: '$modo');
    }
  });

  group('ícone do iOS', () {
    late List<Map<String, dynamic>> imagens;

    setUp(() {
      final contents =
          jsonDecode(File('$_icones/Contents.json').readAsStringSync())
              as Map<String, dynamic>;
      imagens = (contents['images'] as List).cast<Map<String, dynamic>>();
    });

    test('todas as imagens existem com o tamanho certo e sem canal alfa', () {
      expect(imagens, isNotEmpty);
      for (final imagem in imagens) {
        final arquivo = File('$_icones/${imagem['filename']}');
        expect(arquivo.existsSync(), isTrue, reason: '${imagem['filename']}');

        final lado =
            (double.parse((imagem['size'] as String).split('x').first) *
                    int.parse((imagem['scale'] as String).replaceAll('x', '')))
                .round();
        final png = _lerPng(arquivo);

        expect(png.largura, lado, reason: '${imagem['filename']}');
        expect(png.tipoCor, 2, reason: 'RGB, sem alfa: ${imagem['filename']}');
      }
    });

    test('é o ícone do projeto (verde-azulado), não o padrão do Flutter', () {
      final grande = imagens.firstWhere(
        (i) => i['idiom'] == 'ios-marketing',
      )['filename'];
      final pixel = _lerPng(File('$_icones/$grande')).primeiroPixel;

      // Início do gradiente do ícone: #00897B.
      expect(pixel[0], inInclusiveRange(0, 3));
      expect(pixel[1], inInclusiveRange(134, 140));
      expect(pixel[2], inInclusiveRange(120, 126));
    });
  });
}
