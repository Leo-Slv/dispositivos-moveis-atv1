import 'dart:convert';
import 'dart:io';

import 'package:atv1_localizacoes/features/localizacoes/services/cache_mapa.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// PNG 1x1 transparente, para os testes não acessarem a rede.
final _pngTransparente = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class TileProviderFalso extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_pngTransparente);
}

class CacheMapaFalso implements CacheMapa {
  /// Registra a ordem das chamadas, para checar que o cache é preparado antes.
  final eventos = <String>[];
  int criacoes = 0;
  Object? erro;

  @override
  Future<TileProvider> criarProvedor() async {
    eventos.add('cache');
    criacoes++;
    final falha = erro;
    if (falha != null) throw falha;
    return TileProviderFalso();
  }

  @override
  Future<Directory> preparar() => throw UnimplementedError();

  @override
  Future<Directory> Function()? get localizarRaiz => null;
}
