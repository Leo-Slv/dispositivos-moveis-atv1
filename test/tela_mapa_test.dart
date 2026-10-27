import 'dart:async';

import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:atv1_localizacoes/features/localizacoes/presentation/screens/tela_mapa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'fakes/cache_mapa_falso.dart';
import 'fakes/repositorio_falso.dart';

Localizacao _loc(int id, double lat, double lon) => Localizacao(
  id: id,
  latitude: lat,
  longitude: lon,
  precisao: 5,
  instante: DateTime.utc(2026, 11, 2, 12, id),
);

void main() {
  late RepositorioFalso repositorio;
  late CacheMapaFalso cache;

  setUp(() {
    cache = CacheMapaFalso();
    repositorio = RepositorioFalso([
      _loc(3, -23.55, -46.63),
      _loc(2, -22.90, -43.20),
      _loc(1, -15.78, -47.93),
    ]);
  });

  Future<void> abrirTela(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TelaMapa(repositorio: repositorio, cache: cache),
      ),
    );
    await tester.pumpAndSettle();
  }

  MapController controlador(WidgetTester tester) =>
      tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;

  Finder atualizar() => find.byTooltip('Atualizar');
  Finder enquadrar() => find.byTooltip('Enquadrar todos os pontos');

  group('estados antes do mapa', () {
    testWidgets('mostra carregamento enquanto consulta', (tester) async {
      repositorio.bloqueioConsulta = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: TelaMapa(repositorio: repositorio, cache: cache),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);

      repositorio.bloqueioConsulta!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('mostra mensagem quando não há localizações', (tester) async {
      repositorio = RepositorioFalso();
      await abrirTela(tester);

      expect(
        find.text('Nenhuma localização para exibir no mapa.'),
        findsOneWidget,
      );
      expect(find.byType(FlutterMap), findsNothing);
      expect(enquadrar(), findsNothing);
    });

    testWidgets('mostra erro de consulta e permite tentar novamente', (
      tester,
    ) async {
      repositorio.erroConsulta = StateError('banco indisponível');
      await abrirTela(tester);

      expect(find.textContaining('Não foi possível carregar'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);

      repositorio.erroConsulta = null;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('mostra erro quando o cache do mapa não pode ser preparado', (
      tester,
    ) async {
      cache.erro = StateError('sem permissão de escrita');
      await abrirTela(tester);

      expect(find.textContaining('Não foi possível carregar'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    });
  });

  group('mapa', () {
    testWidgets('prepara o cache antes de consultar e pede as últimas 100', (
      tester,
    ) async {
      repositorio.aoConsultar = () => cache.eventos.add('consulta');
      await abrirTela(tester);

      expect(cache.eventos, ['cache', 'consulta']);
      expect(repositorio.limiteRecebido, 100);
      expect(find.byIcon(Icons.location_on), findsNWidgets(3));
    });

    testWidgets('destaca a localização mais recente em vermelho', (
      tester,
    ) async {
      await abrirTela(tester);

      final recente = tester.widget<Icon>(
        find.byKey(const ValueKey('marcador-recente')),
      );
      expect(recente.color, Colors.red);
    });

    testWidgets('enquadra os pontos ao carregar', (tester) async {
      await abrirTela(tester);

      final limites = controlador(tester).camera.visibleBounds;
      for (final l in repositorio.gravadas) {
        expect(limites.contains(LatLng(l.latitude, l.longitude)), isTrue);
      }
    });

    testWidgets('botão enquadra todos os pontos novamente', (tester) async {
      await abrirTela(tester);
      controlador(tester).move(const LatLng(0, 0), 3);
      await tester.pumpAndSettle();

      await tester.tap(enquadrar());
      await tester.pumpAndSettle();

      final limites = controlador(tester).camera.visibleBounds;
      for (final l in repositorio.gravadas) {
        expect(limites.contains(LatLng(l.latitude, l.longitude)), isTrue);
      }
    });

    testWidgets('botão atualizar reconsulta e mostra novos marcadores', (
      tester,
    ) async {
      await abrirTela(tester);
      repositorio.gravadas.insert(0, _loc(4, -20.0, -44.0));

      await tester.tap(atualizar());
      await tester.pumpAndSettle();

      expect(repositorio.consultas, 2);
      expect(cache.criacoes, 1);
      expect(find.byIcon(Icons.location_on), findsNWidgets(4));
    });

    testWidgets('atualizar reenquadra incluindo os novos pontos', (
      tester,
    ) async {
      await abrirTela(tester);
      repositorio.gravadas.insert(0, _loc(4, 2.0, -60.0));

      await tester.tap(atualizar());
      await tester.pumpAndSettle();

      final limites = controlador(tester).camera.visibleBounds;
      expect(limites.contains(const LatLng(2.0, -60.0)), isTrue);
    });

    testWidgets('falha ao atualizar mantém o mapa e avisa o usuário', (
      tester,
    ) async {
      await abrirTela(tester);
      repositorio.erroConsulta = StateError('falhou');

      await tester.tap(atualizar());
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.textContaining('Falha ao atualizar o mapa'), findsOneWidget);
    });
  });

  testWidgets('descartar a tela durante a consulta não causa erro', (
    tester,
  ) async {
    repositorio.bloqueioConsulta = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: TelaMapa(repositorio: repositorio, cache: cache),
      ),
    );

    await tester.pumpWidget(const SizedBox());
    repositorio.bloqueioConsulta!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
