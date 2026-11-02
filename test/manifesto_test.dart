import 'dart:io';

import 'package:atv1_localizacoes/features/localizacoes/services/servico_localizacao.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

const _manifest = 'android/app/src/main/AndroidManifest.xml';

String _permissao(String nome) =>
    '<uses-permission android:name="android.permission.$nome"';

void main() {
  late String manifesto;

  setUp(() => manifesto = File(_manifest).readAsStringSync());
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
    'declara as permissões de localização e de serviço em primeiro plano',
    () {
      for (final permissao in [
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'FOREGROUND_SERVICE',
        'FOREGROUND_SERVICE_LOCATION',
        'POST_NOTIFICATIONS',
        'INTERNET',
      ]) {
        expect(manifesto, contains(_permissao(permissao)), reason: permissao);
      }
    },
  );

  // Sem estas permissões o plugin lança SecurityException ao iniciar o serviço
  // e a coleta fica muda, sem nenhum erro visível no app.
  test(
    'declara as permissões exigidas pelas opções do serviço em 1º plano',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      for (final modo in ModoPrecisao.values) {
        final config =
            (ServicoLocalizacao().configuracao(modo) as AndroidSettings)
                .foregroundNotificationConfig!;

        if (config.enableWakeLock) {
          expect(manifesto, contains(_permissao('WAKE_LOCK')), reason: '$modo');
        }
        if (config.enableWifiLock) {
          expect(
            manifesto,
            contains(_permissao('ACCESS_WIFI_STATE')),
            reason: '$modo',
          );
          expect(
            manifesto,
            contains(_permissao('CHANGE_WIFI_STATE')),
            reason: '$modo',
          );
        }
      }
    },
  );

  test('o nome do aplicativo é legível, não o nome técnico do pacote', () {
    expect(manifesto, contains('android:label="Localizações"'));
    expect(manifesto, isNot(contains('android:label="atv1_localizacoes"')));
  });
}
