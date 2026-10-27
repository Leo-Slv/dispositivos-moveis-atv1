import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

/// Prepara o armazenamento local das imagens (tiles) do mapa em uma pasta
/// privada do aplicativo, antes de o mapa carregá-las.
class CacheMapa {
  /// [localizarRaiz] permite trocar a pasta raiz (usado nos testes).
  CacheMapa({this.localizarRaiz});

  static const subpasta = 'mapa_tiles';
  static const tamanhoMaximoBytes = 100 * 1024 * 1024;

  final Future<Directory> Function()? localizarRaiz;

  Future<Directory>? _pasta;

  /// Cria (se necessário) a pasta de cache e a reutiliza nas chamadas seguintes.
  /// Se a criação falhar, a próxima chamada tenta novamente.
  Future<Directory> preparar() async {
    final pasta = _pasta ??= _criar();
    try {
      return await pasta;
    } catch (_) {
      if (identical(_pasta, pasta)) _pasta = null;
      rethrow;
    }
  }

  Future<Directory> _criar() async {
    final raiz = await (localizarRaiz ?? getApplicationSupportDirectory)();
    return Directory(
      '${raiz.path}${Platform.pathSeparator}$subpasta',
    ).create(recursive: true);
  }

  /// Provedor de tiles que grava e lê o cache na pasta privada preparada.
  Future<TileProvider> criarProvedor() async {
    final pasta = await preparar();
    return NetworkTileProvider(
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
        cacheDirectory: pasta.path,
        maxCacheSize: tamanhoMaximoBytes,
      ),
    );
  }
}
