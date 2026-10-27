import 'dart:async';

import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:atv1_localizacoes/features/localizacoes/presentation/screens/tela_localizacoes.dart';
import 'package:atv1_localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_falso.dart';

Localizacao _loc(int minuto, {double lat = -23.5}) => Localizacao(
  id: minuto,
  latitude: lat,
  longitude: -46.6,
  precisao: 5,
  instante: DateTime.utc(2026, 11, 2, 12, minuto),
);

void main() {
  late RepositorioFalso repositorio;

  Future<void> abrirTela(WidgetTester tester, {bool coletando = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TelaLocalizacoes(repositorio: repositorio, coletando: coletando),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder botaoLimpar() => find.byTooltip('Limpar histórico');
  Finder botaoAtualizar() => find.byTooltip('Atualizar');
  Finder confirmar() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text('Limpar histórico'),
  );

  setUp(() => repositorio = RepositorioFalso([_loc(3), _loc(2), _loc(1)]));

  group('listagem', () {
    testWidgets('consulta as últimas 100 e mostra na ordem recebida', (
      tester,
    ) async {
      await abrirTela(tester);

      expect(repositorio.limiteRecebido, 100);
      final itens = tester
          .widgetList<ItemLocalizacao>(find.byType(ItemLocalizacao))
          .map((i) => i.localizacao.id);
      expect(itens, [3, 2, 1]);
    });

    testWidgets('mostra indicador de carregamento enquanto consulta', (
      tester,
    ) async {
      repositorio.bloqueioConsulta = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(home: TelaLocalizacoes(repositorio: repositorio)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repositorio.bloqueioConsulta!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ItemLocalizacao), findsNWidgets(3));
    });

    testWidgets('mostra mensagem quando o histórico está vazio', (
      tester,
    ) async {
      repositorio = RepositorioFalso();
      await abrirTela(tester);

      expect(find.text('Nenhuma localização registrada.'), findsOneWidget);
    });

    testWidgets('mostra erro e permite tentar novamente', (tester) async {
      repositorio.erroConsulta = StateError('banco indisponível');
      await abrirTela(tester);

      expect(find.textContaining('Não foi possível carregar'), findsOneWidget);

      repositorio.erroConsulta = null;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ItemLocalizacao), findsNWidgets(3));
    });
  });

  group('atualizar', () {
    testWidgets('botão atualizar reconsulta e mostra novos registros', (
      tester,
    ) async {
      await abrirTela(tester);
      repositorio.gravadas.insert(0, _loc(4));

      await tester.tap(botaoAtualizar());
      await tester.pumpAndSettle();

      expect(repositorio.consultas, 2);
      expect(find.byType(ItemLocalizacao), findsNWidgets(4));
    });

    testWidgets('puxar para atualizar reconsulta', (tester) async {
      await abrirTela(tester);

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(repositorio.consultas, 2);
    });

    testWidgets('atualizar não apaga nada', (tester) async {
      await abrirTela(tester);
      await tester.tap(botaoAtualizar());
      await tester.pumpAndSettle();

      expect(repositorio.exclusoes, 0);
    });
  });

  group('limpar histórico', () {
    testWidgets('pede confirmação permanente com Cancelar e Limpar histórico', (
      tester,
    ) async {
      await abrirTela(tester);

      await tester.tap(botaoLimpar());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('permanente'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(confirmar(), findsOneWidget);
      expect(repositorio.exclusoes, 0);
    });

    testWidgets(
      'avisa que novos registros continuam sendo salvos se coletando',
      (tester) async {
        await abrirTela(tester, coletando: true);

        await tester.tap(botaoLimpar());
        await tester.pumpAndSettle();

        expect(
          find.textContaining('novos registros continuarão sendo salvos'),
          findsOneWidget,
        );
      },
    );

    testWidgets('não mostra o aviso de coleta quando parada', (tester) async {
      await abrirTela(tester);

      await tester.tap(botaoLimpar());
      await tester.pumpAndSettle();

      expect(find.textContaining('continuarão sendo salvos'), findsNothing);
    });

    testWidgets('Cancelar não exclui nada', (tester) async {
      await abrirTela(tester);
      await tester.tap(botaoLimpar());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repositorio.exclusoes, 0);
      expect(find.byType(ItemLocalizacao), findsNWidgets(3));
    });

    testWidgets('confirmar exclui, atualiza a lista e mostra sucesso', (
      tester,
    ) async {
      await abrirTela(tester);
      await tester.tap(botaoLimpar());
      await tester.pumpAndSettle();

      await tester.tap(confirmar());
      await tester.pumpAndSettle();

      expect(repositorio.exclusoes, 1);
      expect(find.byType(ItemLocalizacao), findsNothing);
      expect(find.text('Nenhuma localização registrada.'), findsOneWidget);
      expect(find.text('Histórico limpo com sucesso.'), findsOneWidget);
    });

    testWidgets('falha na exclusão mostra mensagem de erro e mantém a lista', (
      tester,
    ) async {
      repositorio.erroExclusao = StateError('disco cheio');
      await abrirTela(tester);
      await tester.tap(botaoLimpar());
      await tester.pumpAndSettle();

      await tester.tap(confirmar());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Falha ao limpar o histórico'),
        findsOneWidget,
      );
      expect(find.text('Histórico limpo com sucesso.'), findsNothing);
      expect(find.byType(ItemLocalizacao), findsNWidgets(3));
    });
  });

  testWidgets('descartar a tela durante a consulta não causa erro', (
    tester,
  ) async {
    repositorio.bloqueioConsulta = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: TelaLocalizacoes(repositorio: repositorio)),
    );

    await tester.pumpWidget(const SizedBox());
    repositorio.bloqueioConsulta!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
