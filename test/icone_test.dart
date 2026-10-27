import 'dart:io';
import 'dart:typed_data';

import 'package:atv1_localizacoes/features/localizacoes/services/servico_localizacao.dart';
import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';
const _manifest = 'android/app/src/main/AndroidManifest.xml';

/// Largura, altura e tipo de cor lidos do cabeçalho IHDR de um PNG.
({int largura, int altura, int tipoCor}) _cabecalhoPng(String caminho) {
  final bytes = File(caminho).readAsBytesSync();
  final assinatura = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  expect(bytes.sublist(0, 8), assinatura, reason: '$caminho não é PNG');
  final dados = ByteData.sublistView(bytes);
  return (
    largura: dados.getUint32(16),
    altura: dados.getUint32(20),
    tipoCor: bytes[25],
  );
}

void main() {
  test('mantém a imagem original em assets/icons', () {
    final png = _cabecalhoPng('assets/icons/localizacoes.png');
    expect(png.largura, png.altura);
    expect(png.largura, greaterThanOrEqualTo(512));
  });

  test('há um ícone legado por densidade, com o tamanho esperado', () {
    const tamanhos = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    tamanhos.forEach((densidade, tamanho) {
      final png = _cabecalhoPng('$_res/mipmap-$densidade/ic_localizacoes.png');
      expect(png.largura, tamanho, reason: densidade);
      expect(png.altura, tamanho, reason: densidade);
    });
  });

  test('imagem do ícone adaptativo é PNG com canal alfa', () {
    final png = _cabecalhoPng('$_res/drawable-nodpi/icone_localizacoes.png');
    expect(png.largura, png.altura);
    expect(png.tipoCor, 6, reason: 'RGBA');
  });

  test('ícone adaptativo usa a imagem e a cor de fundo do projeto', () {
    final xml = File(
      '$_res/mipmap-anydpi-v26/ic_localizacoes.xml',
    ).readAsStringSync();
    expect(xml, contains('<adaptive-icon'));
    expect(xml, contains('@drawable/icone_localizacoes'));
    expect(xml, contains('@color/icone_localizacoes_fundo'));

    final cores = File(
      '$_res/values/icone_localizacoes.xml',
    ).readAsStringSync();
    expect(cores, contains('name="icone_localizacoes_fundo"'));
  });

  test('AndroidManifest referencia o ícone do aplicativo', () {
    final manifest = File(_manifest).readAsStringSync();
    expect(manifest, contains('android:icon="@mipmap/ic_localizacoes"'));
  });

  test('notificação da coleta usa um ícone que existe nos recursos', () {
    const icone = ServicoLocalizacao.iconeNotificacao;

    expect(icone.defType, 'drawable');
    expect(File('$_res/drawable/${icone.name}.xml').existsSync(), isTrue);
  });

  test('nenhum ícone padrão do Flutter permanece', () {
    expect(File(_manifest).readAsStringSync(), isNot(contains('ic_launcher')));

    final restantes = Directory(_res)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('ic_launcher'));
    expect(restantes, isEmpty);
  });
}
