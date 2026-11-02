import 'dart:async';

import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:atv1_localizacoes/features/localizacoes/presentation/screens/tela_coleta.dart';
import 'package:atv1_localizacoes/features/localizacoes/services/servico_localizacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'fakes/cache_mapa_falso.dart';
import 'fakes/repositorio_falso.dart';

class ServicoFalso implements ServicoLocalizacao {
  SituacaoColeta situacao = SituacaoColeta.pronta;
  int aberturasConfigApp = 0;
  int aberturasConfigLocalizacao = 0;

  /// Um controlador por chamada de posicoes(), na ordem em que foram pedidos.
  final controladores = <StreamController<Position>>[];

  /// Modo de precisão pedido em cada chamada de posicoes().
  final modos = <ModoPrecisao>[];

  /// Controlador da assinatura mais recente.
  StreamController<Position> get controlador => controladores.last;

  int get streamsAbertos => controladores.length;

  int get assinaturasAtivas => controladores.where((c) => c.hasListener).length;

  @override
  Future<SituacaoColeta> verificar() async => situacao;

  @override
  Future<void> solicitarPermissaoNotificacao() async {}

  @override
  Stream<Position> posicoes({ModoPrecisao modo = ModoPrecisao.alta}) {
    modos.add(modo);
    final controlador = StreamController<Position>(sync: true);
    controladores.add(controlador);
    return controlador.stream;
  }

  @override
  LocationSettings configuracao(ModoPrecisao modo) =>
      throw UnimplementedError();

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

  // Sem await: close() só completa quando há ouvinte, e alguns testes não têm.
  void fechar() {
    for (final controlador in controladores) {
      unawaited(controlador.close());
    }
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
        home: TelaColeta(
          servico: servico,
          repositorio: repositorio,
          cacheMapa: CacheMapaFalso(),
        ),
      ),
    );
  }

  Finder botao(String texto) => find.ancestor(
    of: find.text(texto),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );

  /// Avança o relógio fake e deixa rodar as continuações assíncronas. O await
  /// de cancel() retoma na zona real, que o pump sozinho não processa.
  Future<void> avancar(WidgetTester tester, int segundos) async {
    await tester.pump(Duration(seconds: segundos));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  bool habilitado(WidgetTester tester, String texto) =>
      tester.widget<ButtonStyleButton>(botao(texto)).onPressed != null;

  setUp(() {
    servico = ServicoFalso();
    repositorio = RepositorioFalso();
  });

  tearDown(() => servico.fechar());

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

  group('diagnóstico da coleta', () {
    const aguardando = 'Aguardando a primeira posição...';
    const semPosicao = 'Nenhuma posição recebida ainda';

    testWidgets('sem coleta ativa não mostra aviso nem posição', (
      tester,
    ) async {
      await abrirTela(tester);

      expect(find.text(aguardando), findsNothing);
      expect(find.textContaining(semPosicao), findsNothing);
      expect(find.textContaining('Última posição'), findsNothing);
    });

    testWidgets('enquanto nenhuma posição chega, informa que aguarda', (
      tester,
    ) async {
      await abrirTela(tester);

      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();

      expect(find.text(aguardando), findsOneWidget);
      expect(find.textContaining(semPosicao), findsNothing);
    });

    testWidgets(
      'sem posição nem em precisão reduzida, orienta a verificar a localização',
      (tester) async {
        await abrirTela(tester);
        await tester.tap(botao('Iniciar coleta'));
        await tester.pumpAndSettle();

        // 30 s para a troca de modo e mais 45 s sem nenhuma posição.
        await avancar(tester, 31);
        await avancar(tester, 44);
        expect(find.textContaining(semPosicao), findsNothing);

        await avancar(tester, 2);
        expect(find.textContaining(semPosicao), findsOneWidget);
        expect(find.text(aguardando), findsNothing);
      },
    );

    testWidgets('ao receber posição, mostra a última e remove os avisos', (
      tester,
    ) async {
      await abrirTela(tester);
      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();
      await avancar(tester, 31);
      await avancar(tester, 46);
      expect(find.textContaining(semPosicao), findsOneWidget);

      servico.controlador.add(_posicao(-23.1234567));
      await tester.pumpAndSettle();

      expect(find.text('Última posição recebida'), findsOneWidget);
      expect(find.textContaining('-23.123457'), findsOneWidget);
      expect(find.textContaining('7.5 m'), findsOneWidget);
      expect(find.text(aguardando), findsNothing);
      expect(find.textContaining(semPosicao), findsNothing);
    });

    testWidgets('a última posição é atualizada a cada nova leitura', (
      tester,
    ) async {
      await abrirTela(tester);
      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();

      servico.controlador.add(_posicao(-23.1));
      await tester.pumpAndSettle();
      servico.controlador.add(_posicao(-23.2));
      await tester.pumpAndSettle();

      expect(find.textContaining('-23.200000'), findsOneWidget);
      expect(find.textContaining('-23.100000'), findsNothing);
    });

    testWidgets('parar cancela o aviso de falta de posições', (tester) async {
      await abrirTela(tester);
      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();

      await tester.tap(botao('Parar coleta'));
      await tester.pumpAndSettle();
      await avancar(tester, 60);

      expect(find.textContaining(semPosicao), findsNothing);
      expect(find.text(aguardando), findsNothing);
    });
  });

  group('dados salvos (persistência)', () {
    Localizacao salva(int minuto, double lat) => Localizacao(
      id: minuto,
      latitude: lat,
      longitude: -46.6,
      precisao: 4,
      instante: DateTime.utc(2026, 11, 2, 9, minuto),
    );

    // Mais recente primeiro, como a consulta do repositório devolve.
    void comTresSalvos() => repositorio = RepositorioFalso([
      salva(3, -23.3),
      salva(2, -23.2),
      salva(1, -23.1),
    ]);

    Future<void> abrirEEsperar(WidgetTester tester) async {
      await abrirTela(tester);
      await tester.pumpAndSettle();
    }

    testWidgets('ao abrir, mostra o total e a última posição já salvos', (
      tester,
    ) async {
      comTresSalvos();

      await abrirEEsperar(tester);

      expect(find.text('Registros salvos: 3'), findsOneWidget);
      expect(find.text('Gravados nesta sessão: 0'), findsOneWidget);
      expect(find.text('Última posição salva'), findsOneWidget);
      expect(find.textContaining('-23.300000'), findsOneWidget);
    });

    testWidgets('sem registros salvos, mostra zero e nenhuma posição', (
      tester,
    ) async {
      await abrirEEsperar(tester);

      expect(find.text('Registros salvos: 0'), findsOneWidget);
      expect(find.text('Última posição salva'), findsNothing);
    });

    testWidgets('reabrir a tela mostra o que foi coletado antes', (
      tester,
    ) async {
      await abrirEEsperar(tester);
      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();
      servico.controlador.add(_posicao(-23.45));
      await tester.pumpAndSettle();

      // Fecha o app (descarta a tela) e abre de novo sobre o mesmo banco.
      await tester.pumpWidget(const SizedBox());
      await abrirEEsperar(tester);

      expect(find.text('Registros salvos: 1'), findsOneWidget);
      expect(find.text('Gravados nesta sessão: 0'), findsOneWidget);
      expect(find.text('Última posição salva'), findsOneWidget);
      expect(find.textContaining('-23.450000'), findsOneWidget);
    });

    testWidgets('cada posição gravada atualiza o total salvo', (tester) async {
      comTresSalvos();
      await abrirEEsperar(tester);
      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();

      servico.controlador.add(_posicao(-23.9));
      await tester.pumpAndSettle();

      expect(find.text('Registros salvos: 4'), findsOneWidget);
      expect(find.text('Gravados nesta sessão: 1'), findsOneWidget);
    });

    testWidgets('durante a coleta não mostra a posição salva antiga', (
      tester,
    ) async {
      comTresSalvos();
      await abrirEEsperar(tester);

      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();

      expect(find.text('Última posição salva'), findsNothing);
      expect(find.text('Aguardando a primeira posição...'), findsOneWidget);
      expect(find.text('Registros salvos: 3'), findsOneWidget);
    });

    testWidgets('ao voltar do histórico limpo, o total volta a zero', (
      tester,
    ) async {
      comTresSalvos();
      await abrirEEsperar(tester);

      await tester.tap(botao('Consultar histórico'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Limpar histórico'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Limpar histórico'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Registros salvos: 0'), findsOneWidget);
      expect(find.text('Última posição salva'), findsNothing);
    });

    testWidgets('falha ao ler os dados salvos mostra mensagem de erro', (
      tester,
    ) async {
      repositorio.erroConsulta = StateError('banco indisponível');

      await abrirEEsperar(tester);

      expect(
        find.textContaining('Não foi possível ler os dados salvos'),
        findsOneWidget,
      );
    });
  });

  group('fallback para Wi-Fi/rede', () {
    const aviso = 'Sem sinal de GPS. Usando a localização por Wi-Fi/rede';

    Future<void> iniciar(WidgetTester tester) async {
      await abrirTela(tester);
      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();
    }

    testWidgets('começa sempre em alta precisão', (tester) async {
      await iniciar(tester);

      expect(servico.modos, [ModoPrecisao.alta]);
      expect(find.textContaining(aviso), findsNothing);
    });

    testWidgets('antes de 30 s sem posição, continua em alta precisão', (
      tester,
    ) async {
      await iniciar(tester);

      await avancar(tester, 29);

      expect(servico.modos, [ModoPrecisao.alta]);
      expect(find.textContaining(aviso), findsNothing);
    });

    testWidgets('sem posição em 30 s, passa a aceitar Wi-Fi/rede e informa', (
      tester,
    ) async {
      await iniciar(tester);

      await avancar(tester, 31);

      expect(servico.modos, [ModoPrecisao.alta, ModoPrecisao.reduzida]);
      expect(find.textContaining(aviso), findsOneWidget);
      expect(habilitado(tester, 'Parar coleta'), isTrue);
      expect(habilitado(tester, 'Iniciar coleta'), isFalse);
    });

    testWidgets('após a troca há uma única assinatura ativa', (tester) async {
      await iniciar(tester);

      await avancar(tester, 31);

      expect(servico.streamsAbertos, 2);
      expect(servico.assinaturasAtivas, 1);
      expect(servico.controladores.first.hasListener, isFalse);
      expect(servico.controladores.last.hasListener, isTrue);
    });

    testWidgets('posições recebidas após a troca são gravadas', (tester) async {
      await iniciar(tester);
      await avancar(tester, 31);

      servico.controlador.add(_posicao(-23.7));
      await tester.pumpAndSettle();

      expect(repositorio.gravadas.map((l) => l.latitude), [-23.7]);
      expect(find.text('Última posição recebida'), findsOneWidget);
    });

    testWidgets('posição do GPS antes de 30 s impede a troca', (tester) async {
      await iniciar(tester);

      await avancar(tester, 10);
      servico.controlador.add(_posicao(-23.5));
      await avancar(tester, 60);

      expect(servico.modos, [ModoPrecisao.alta]);
      expect(servico.assinaturasAtivas, 1);
      expect(find.textContaining(aviso), findsNothing);
    });

    testWidgets('parar durante a coleta reduzida cancela tudo', (tester) async {
      await iniciar(tester);
      await avancar(tester, 31);

      await tester.tap(botao('Parar coleta'));
      await tester.pumpAndSettle();

      expect(servico.assinaturasAtivas, 0);
      expect(find.textContaining(aviso), findsNothing);
    });

    testWidgets('ao iniciar de novo volta a pedir alta precisão', (
      tester,
    ) async {
      await iniciar(tester);
      await avancar(tester, 31);
      await tester.tap(botao('Parar coleta'));
      await tester.pumpAndSettle();

      await tester.tap(botao('Iniciar coleta'));
      await tester.pumpAndSettle();

      expect(servico.modos, [
        ModoPrecisao.alta,
        ModoPrecisao.reduzida,
        ModoPrecisao.alta,
      ]);
      expect(servico.assinaturasAtivas, 1);
      expect(find.textContaining(aviso), findsNothing);
    });

    testWidgets('parar antes dos 30 s não dispara a troca depois', (
      tester,
    ) async {
      await iniciar(tester);
      await tester.tap(botao('Parar coleta'));
      await tester.pumpAndSettle();

      await avancar(tester, 120);

      expect(servico.modos, [ModoPrecisao.alta]);
    });
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

  testWidgets('Ver mapa abre a tela do mapa', (tester) async {
    await abrirTela(tester);

    await tester.tap(botao('Ver mapa'));
    await tester.pumpAndSettle();

    expect(find.text('Mapa'), findsOneWidget);
  });

  testWidgets('coleta segue ativa ao abrir o mapa e voltar', (tester) async {
    await abrirTela(tester);
    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();

    await tester.tap(botao('Ver mapa'));
    await tester.pumpAndSettle();
    expect(servico.controlador.hasListener, isTrue);
    servico.controlador.add(_posicao(-23.4));
    await tester.pumpAndSettle();
    expect(repositorio.gravadas.map((l) => l.latitude), [-23.4]);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(servico.controlador.hasListener, isTrue);
    expect(habilitado(tester, 'Parar coleta'), isTrue);
  });

  testWidgets('descartar a tela cancela a assinatura', (tester) async {
    await abrirTela(tester);
    await tester.tap(botao('Iniciar coleta'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());

    expect(servico.controlador.hasListener, isFalse);
  });
}
