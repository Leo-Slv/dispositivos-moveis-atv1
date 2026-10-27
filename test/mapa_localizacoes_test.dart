import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:atv1_localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';
import 'package:atv1_localizacoes/features/localizacoes/presentation/widgets/mapa_localizacoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'fakes/cache_mapa_falso.dart';

Localizacao _loc(int id, double lat, double lon) => Localizacao(
  id: id,
  latitude: lat,
  longitude: lon,
  precisao: 5,
  instante: DateTime.utc(2026, 11, 2, 12, id),
);

void main() {
  late MapController controlador;

  setUp(() => controlador = MapController());
  tearDown(() => controlador.dispose());

  Future<void> abrir(WidgetTester tester, List<Localizacao> itens) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaLocalizacoes(
            localizacoes: itens,
            controlador: controlador,
            tileProvider: TileProviderFalso(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Mais recente primeiro; pontos espalhados no Brasil.
  final tres = [
    _loc(3, -23.55, -46.63),
    _loc(2, -22.90, -43.20),
    _loc(1, -15.78, -47.93),
  ];

  testWidgets('usa a camada de ruas do OpenStreetMap com agente identificado', (
    tester,
  ) async {
    await abrir(tester, tres);

    final camada = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(camada.urlTemplate, contains('tile.openstreetmap.org'));
    expect(
      camada.tileProvider.headers['User-Agent'],
      contains(MapaLocalizacoes.pacote),
    );
  });

  testWidgets('exibe a atribuição do provedor do mapa', (tester) async {
    await abrir(tester, tres);

    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
  });

  testWidgets('cria um marcador por localização', (tester) async {
    await abrir(tester, tres);

    expect(find.byIcon(Icons.location_on), findsNWidgets(3));
  });

  testWidgets('destaca apenas o mais recente em vermelho', (tester) async {
    await abrir(tester, tres);

    final recente = tester.widget<Icon>(
      find.byKey(const ValueKey('marcador-recente')),
    );
    expect(recente.color, Colors.red);

    final outros = tester
        .widgetList<Icon>(find.byIcon(Icons.location_on))
        .where((i) => i.key != const ValueKey('marcador-recente'));
    expect(outros, hasLength(2));
    expect(outros.every((i) => i.color != Colors.red), isTrue);
  });

  testWidgets('enquadra todos os pontos ao carregar', (tester) async {
    await abrir(tester, tres);

    final limites = controlador.camera.visibleBounds;
    for (final l in tres) {
      expect(limites.contains(LatLng(l.latitude, l.longitude)), isTrue);
    }
    expect(controlador.camera.zoom, lessThan(MapaLocalizacoes.zoomPontoUnico));
  });

  testWidgets('enquadrar() volta a mostrar todos os pontos', (tester) async {
    await abrir(tester, tres);
    controlador.move(const LatLng(0, 0), 3);
    await tester.pumpAndSettle();

    MapaLocalizacoes.enquadrar(controlador, tres);
    await tester.pumpAndSettle();

    final limites = controlador.camera.visibleBounds;
    for (final l in tres) {
      expect(limites.contains(LatLng(l.latitude, l.longitude)), isTrue);
    }
  });

  testWidgets('com um único ponto, centraliza nele', (tester) async {
    final unico = [_loc(1, -23.55, -46.63)];
    await abrir(tester, unico);

    controlador.move(const LatLng(0, 0), 3);
    await tester.pumpAndSettle();
    MapaLocalizacoes.enquadrar(controlador, unico);
    await tester.pumpAndSettle();

    expect(controlador.camera.center.latitude, closeTo(-23.55, 1e-6));
    expect(controlador.camera.zoom, MapaLocalizacoes.zoomPontoUnico);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });

  testWidgets('tocar no marcador mostra os detalhes da localização', (
    tester,
  ) async {
    await abrir(tester, tres);

    await tester.tap(find.byKey(const ValueKey('marcador-recente')));
    await tester.pumpAndSettle();

    final item = tester.widget<ItemLocalizacao>(find.byType(ItemLocalizacao));
    expect(item.localizacao.id, 3);
  });
}
