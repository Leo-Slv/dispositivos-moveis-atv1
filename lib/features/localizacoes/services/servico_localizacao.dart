import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

enum SituacaoColeta {
  pronta,
  servicoDesligado,
  permissaoNegada,
  permissaoNegadaPermanente,
}

class ServicoLocalizacao {
  static const intervalo = Duration(seconds: 20);

  /// Ícone da notificação do serviço em primeiro plano (res/drawable). Sem um
  /// ícone válido o Android recusa o serviço e a coleta não inicia.
  static const iconeNotificacao = AndroidResource(
    name: 'ic_notificacao',
    defType: 'drawable',
  );

  /// Verifica o GPS e a permissão, solicitando-a quando necessário.
  Future<SituacaoColeta> verificar() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return SituacaoColeta.servicoDesligado;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    switch (permissao) {
      case LocationPermission.denied:
        return SituacaoColeta.permissaoNegada;
      case LocationPermission.deniedForever:
        return SituacaoColeta.permissaoNegadaPermanente;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        return SituacaoColeta.pronta;
    }
  }

  /// Solicita a permissão de notificações (Android 13+), necessária para que
  /// a notificação do serviço em primeiro plano fique visível.
  Future<void> solicitarPermissaoNotificacao() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await ph.Permission.notification.request();
  }

  /// Stream de posições com alta precisão e intervalo solicitado de 20 s.
  /// No Android, mantém um serviço em primeiro plano com notificação.
  Stream<Position> posicoes() {
    final LocationSettings configuracao;
    if (defaultTargetPlatform == TargetPlatform.android) {
      configuracao = AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: intervalo,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Coleta de localização ativa',
          notificationText: 'Registrando sua posição a cada 20 segundos.',
          notificationIcon: iconeNotificacao,
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else {
      configuracao = const LocationSettings(accuracy: LocationAccuracy.high);
    }
    return Geolocator.getPositionStream(locationSettings: configuracao);
  }

  Future<bool> abrirConfiguracoesApp() => Geolocator.openAppSettings();

  Future<bool> abrirConfiguracoesLocalizacao() =>
      Geolocator.openLocationSettings();
}
