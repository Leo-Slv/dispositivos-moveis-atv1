import 'dart:async';

import 'package:atv1_localizacoes/features/localizacoes/presentation/screens/tela_coleta.dart';
import 'package:atv1_localizacoes/features/localizacoes/services/servico_localizacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'fakes/repositorio_falso.dart';

class ServicoFalso implements ServicoLocalizacao {
  SituacaoColeta situacao = SituacaoColeta.pronta;
  int streamsAbertos = 0;
  int aberturasConfigApp = 0;
  int aberturasConfigLocalizacao = 0;
  // ignore: close_sinks
  final controlador = StreamController<Position>(sync: true);

  @override
  Future<SituacaoColeta> verificar() async => situacao;

  @override
  Future<void> solicitarPermissaoNotificacao() async {}

  @override
  Stream<Position> posicoes() {
    streamsAbertos++;
    return controlador.stream;
  }

  @override
  Future<bool> abrirConfiguracoesApp() async {
    aberturasConfigApp++;
    return true;
  }

  @override
  Future<bool> abrirConfiguracoesLocalizacao() async {
    aberturasConfigLocalizacao++;
    return true;
  }
}

Position _posicao(double lat) => Position(
  latitude: lat,
  longitude: -46.6,
  timestamp: DateTime.utc(2026, 11, 2, 12),
  accuracy: 7.5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late ServicoFalso servico;
  late RepositorioFalso repositorio;

  Future<void> abrirTela(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TelaColeta(servico: servico, repositorio: repositorio),
      ),
    );
  }

  Finder botao(String texto) => find.ancestor(
    of: find.text(texto),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );

  bool habilitado(WidgetTester tester, String texto) =>
      tester.widget<ButtonStyleButton>(botao(texto)).onPressed != null;

  setUp(() {
    servico = ServicoFalso();
    repositorio = RepositorioFalso();
  });

  // Sem await: close() só completa quando há ouvinte, e alguns testes não têm.
  tearDown(() => unawaited(servico.controlador.close()));

  testWidgets('estado inicial: Iniciar habilitado e Parar desabilitado', (
    tester,
  ) async {
    await abrirTela(tester);

    expect(habilitado(tester, 'Iniciar coleta'), isTrue);
    expect(habilitado(tester, 'Parar coleta'), isFalse);
  });

  testWidgets('ao iniciar, alterna os botões e abre uma única assinatura', (
    tester,
  ) async {
    await abrirTela(tester);

    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();

    expect(servico.streamsAbertos, 1);
    expect(servico.controlador.hasListener, isTrue);
    expect(habilitado(tester, 'Iniciar coleta'), isFalse);
    expect(habilitado(tester, 'Parar coleta'), isTrue);
  });

  testWidgets('toques repetidos em Iniciar não criam assinaturas duplicadas', (
    tester,
  ) async {
    await abrirTela(tester);

    await tester.tap(botao('Iniciar coleta'));
    await tester.tap(botao('Iniciar coleta'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(botao('Iniciar coleta'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(servico.streamsAbertos, 1);
  });

  testWidgets('Parar cancela a assinatura do stream', (tester) async {
    await abrirTela(tester);
    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();

    await tester.tap(botao('Parar coleta'));
    await tester.pumpAndSettle();

    expect(servico.controlador.hasListener, isFalse);
    expect(habilitado(tester, 'Iniciar coleta'), isTrue);
    expect(habilitado(tester, 'Parar coleta'), isFalse);
  });

  testWidgets('cada posição recebida é gravada pelo repositório', (
    tester,
  ) async {
    await abrirTela(tester);
    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();

    servico.controlador.add(_posicao(-23.1));
    servico.controlador.add(_posicao(-23.2));
    await tester.pumpAndSettle();

    expect(repositorio.gravadas.map((l) => l.latitude), [-23.1, -23.2]);
    expect(repositorio.gravadas.first.precisao, 7.5);
    expect(repositorio.gravadas.first.instante.isUtc, isTrue);
  });

  testWidgets('GPS desligado orienta o usuário e não inicia a coleta', (
    tester,
  ) async {
    servico.situacao = SituacaoColeta.servicoDesligado;
    await abrirTela(tester);

    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();

    expect(find.text('Localização desligada'), findsOneWidget);
    expect(servico.streamsAbertos, 0);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    expect(servico.aberturasConfigLocalizacao, 1);
  });

  testWidgets('permissão negada orienta o usuário e não inicia a coleta', (
    tester,
  ) async {
    servico.situacao = SituacaoColeta.permissaoNegada;
    await abrirTela(tester);

    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();

    expect(find.text('Permissão necessária'), findsOneWidget);
    expect(servico.streamsAbertos, 0);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(habilitado(tester, 'Iniciar coleta'), isTrue);
  });

  testWidgets('permissão negada permanentemente leva às configurações do app', (
    tester,
  ) async {
    servico.situacao = SituacaoColeta.permissaoNegadaPermanente;
    await abrirTela(tester);

    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();
    expect(find.text('Permissão bloqueada'), findsOneWidget);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    expect(servico.aberturasConfigApp, 1);
  });

  testWidgets('botão de configurações de permissão abre as configurações', (
    tester,
  ) async {
    await abrirTela(tester);

    await tester.tap(botao('Configurações de permissão'));
    await tester.pump();

    expect(servico.aberturasConfigApp, 1);
  });

  testWidgets('Consultar histórico abre a tela de histórico', (tester) async {
    await abrirTela(tester);

    await tester.tap(botao('Consultar histórico'));
    await tester.pumpAndSettle();

    expect(find.text('Histórico'), findsOneWidget);
  });

  testWidgets(
    'coleta segue ativa e gravando ao navegar e atualizar o histórico',
    (tester) async {
      await abrirTela(tester);
      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();

      await tester.tap(botao('Consultar histórico'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Atualizar'));
      await tester.pumpAndSettle();

      expect(servico.controlador.hasListener, isTrue);
      servico.controlador.add(_posicao(-23.3));
      await tester.pumpAndSettle();
      expect(repositorio.gravadas.map((l) => l.latitude), [-23.3]);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(servico.controlador.hasListener, isTrue);
      expect(habilitado(tester, 'Parar coleta'), isTrue);
    },
  );

  testWidgets('descartar a tela cancela a assinatura', (tester) async {
    await abrirTela(tester);
    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());

    expect(servico.controlador.hasListener, isFalse);
  });
}
