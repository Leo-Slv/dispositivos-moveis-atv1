import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

/// Mapa de ruas (OpenStreetMap) com um marcador por localização.
/// [localizacoes] deve estar da mais recente para a mais antiga.
class MapaLocalizacoes extends StatelessWidget {
  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    required this.controlador,
    required this.tileProvider,
  });

  static const urlTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const pacote = 'br.edu.atv1_localizacoes';
  static const atribuicao = 'OpenStreetMap contributors';
  static const zoomPontoUnico = 16.0;
  static const _margem = EdgeInsets.all(56);

  final List<Localizacao> localizacoes;
  final MapController controlador;
  final TileProvider tileProvider;

  static LatLng _ponto(Localizacao l) => LatLng(l.latitude, l.longitude);

  /// Enquadra todos os pontos no mapa (ou centraliza, se houver só um).
  static void enquadrar(MapController controlador, List<Localizacao> itens) {
    if (itens.isEmpty) return;
    if (itens.length == 1) {
      controlador.move(_ponto(itens.first), zoomPontoUnico);
      return;
    }
    controlador.fitCamera(
      CameraFit.coordinates(
        coordinates: itens.map(_ponto).toList(),
        padding: _margem,
      ),
    );
  }

  void _mostrarDetalhes(BuildContext context, Localizacao localizacao) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) =>
          SafeArea(child: ItemLocalizacao(localizacao: localizacao)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Do mais antigo ao mais recente, para o destaque ficar por cima.
    final marcadores = <Marker>[
      for (var i = localizacoes.length - 1; i >= 0; i--)
        Marker(
          point: _ponto(localizacoes[i]),
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _mostrarDetalhes(context, localizacoes[i]),
            child: Icon(
              Icons.location_on,
              key: i == 0
                  ? const ValueKey('marcador-recente')
                  : ValueKey('marcador-$i'),
              size: 40,
              color: i == 0 ? Colors.red : Colors.blue,
            ),
          ),
        ),
    ];

    return FlutterMap(
      mapController: controlador,
      options: MapOptions(
        initialCenter: _ponto(localizacoes.first),
        initialZoom: zoomPontoUnico,
        initialCameraFit: localizacoes.length > 1
            ? CameraFit.coordinates(
                coordinates: localizacoes.map(_ponto).toList(),
                padding: _margem,
              )
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: urlTiles,
          userAgentPackageName: pacote,
          tileProvider: tileProvider,
        ),
        MarkerLayer(markers: marcadores),
        // Sempre visível (exigência de uso dos tiles do OpenStreetMap):
        // mostra '© OpenStreetMap contributors' sem precisar tocar em nada.
        const SimpleAttributionWidget(source: Text(atribuicao)),
      ],
    );
  }
}
