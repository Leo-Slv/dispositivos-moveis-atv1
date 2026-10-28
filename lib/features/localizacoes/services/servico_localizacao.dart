import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

enum SituacaoColeta {
  pronta,
  servicoDesligado,
  permissaoNegada,
  permissaoNegadaPermanente,
}

/// Fonte de localização solicitada. A reduzida serve de alternativa quando o
/// GPS não entrega posições (por exemplo, em ambientes fechados).
enum ModoPrecisao { alta, reduzida }

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

  /// Stream de posições com intervalo solicitado de 20 s. Por padrão usa alta
  /// precisão (GPS); [ModoPrecisao.reduzida] aceita Wi-Fi/rede móvel.
  /// No Android, mantém um serviço em primeiro plano com notificação.
  Stream<Position> posicoes({ModoPrecisao modo = ModoPrecisao.alta}) {
    return Geolocator.getPositionStream(locationSettings: configuracao(modo));
  }

  /// Configuração do stream de posições para o [modo] informado.
  LocationSettings configuracao(ModoPrecisao modo) {
    final precisao = switch (modo) {
      ModoPrecisao.alta => LocationAccuracy.high,
      ModoPrecisao.reduzida => LocationAccuracy.medium,
    };

    if (defaultTargetPlatform != TargetPlatform.android) {
      return LocationSettings(accuracy: precisao);
    }

    return AndroidSettings(
      accuracy: precisao,
      intervalDuration: intervalo,
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: 'Coleta de localização ativa',
        notificationText: switch (modo) {
          ModoPrecisao.alta => 'Registrando sua posição a cada 20 segundos.',
          ModoPrecisao.reduzida =>
            'Registrando por Wi-Fi/rede (sem sinal de GPS).',
        },
        notificationIcon: iconeNotificacao,
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
  }

  Future<bool> abrirConfiguracoesApp() => Geolocator.openAppSettings();

  Future<bool> abrirConfiguracoesLocalizacao() =>
      Geolocator.openLocationSettings();
}
