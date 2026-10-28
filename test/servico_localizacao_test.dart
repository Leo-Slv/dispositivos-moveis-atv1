import 'package:atv1_localizacoes/features/localizacoes/services/servico_localizacao.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  final servico = ServicoLocalizacao();

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('no Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    AndroidSettings configuracao(ModoPrecisao modo) =>
        servico.configuracao(modo) as AndroidSettings;

    test('alta precisão: GPS, intervalo de 20 s e sem filtro de distância', () {
      final config = configuracao(ModoPrecisao.alta);

      expect(config.accuracy, LocationAccuracy.high);
      expect(config.intervalDuration, const Duration(seconds: 20));
      expect(config.distanceFilter, 0);
    });

    test('precisão reduzida: aceita Wi-Fi/rede, mesmo intervalo de 20 s', () {
      final config = configuracao(ModoPrecisao.reduzida);

      expect(config.accuracy, LocationAccuracy.medium);
      expect(config.intervalDuration, const Duration(seconds: 20));
      expect(config.distanceFilter, 0);
    });

    test(
      'ambos os modos mantêm o serviço em primeiro plano com notificação',
      () {
        for (final modo in ModoPrecisao.values) {
          final notificacao = configuracao(modo).foregroundNotificationConfig;

          expect(notificacao, isNotNull, reason: '$modo');
          expect(notificacao!.setOngoing, isTrue, reason: '$modo');
          expect(
            notificacao.notificationIcon.name,
            ServicoLocalizacao.iconeNotificacao.name,
            reason: '$modo',
          );
        }
      },
    );

    test('a notificação informa quando a coleta usa Wi-Fi/rede', () {
      final alta = configuracao(ModoPrecisao.alta);
      final reduzida = configuracao(ModoPrecisao.reduzida);

      expect(
        reduzida.foregroundNotificationConfig!.notificationText,
        isNot(alta.foregroundNotificationConfig!.notificationText),
      );
      expect(
        reduzida.foregroundNotificationConfig!.notificationText,
        contains('Wi-Fi'),
      );
    });
  });

  test(
    'fora do Android usa a precisão do modo, sem serviço em primeiro plano',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(
        servico.configuracao(ModoPrecisao.alta).accuracy,
        LocationAccuracy.high,
      );
      expect(
        servico.configuracao(ModoPrecisao.reduzida).accuracy,
        LocationAccuracy.medium,
      );
    },
  );
}
