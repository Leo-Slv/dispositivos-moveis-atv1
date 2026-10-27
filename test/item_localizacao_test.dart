import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:atv1_localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _dois(int n) => n.toString().padLeft(2, '0');

void main() {
  testWidgets(
    'exibe data/hora locais, coordenadas com 6 casas e precisão com 1',
    (tester) async {
      final localizacao = Localizacao(
        latitude: -23.55052,
        longitude: -46.633308,
        precisao: 7.46,
        instante: DateTime.utc(2026, 11, 2, 15, 30, 5),
      );
      final local = localizacao.instante.toLocal();
      final dataEsperada =
          '${_dois(local.day)}/${_dois(local.month)}/${local.year} '
          '${_dois(local.hour)}:${_dois(local.minute)}:${_dois(local.second)}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ItemLocalizacao(localizacao: localizacao)),
        ),
      );

      expect(find.text(dataEsperada), findsOneWidget);
      expect(find.textContaining('-23.550520'), findsOneWidget);
      expect(find.textContaining('-46.633308'), findsOneWidget);
      expect(find.textContaining('7.5 m'), findsOneWidget);
    },
  );

  testWidgets('completa com zeros coordenadas e precisão inteiras', (
    tester,
  ) async {
    final localizacao = Localizacao(
      latitude: 10,
      longitude: -20,
      precisao: 3,
      instante: DateTime.utc(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ItemLocalizacao(localizacao: localizacao)),
      ),
    );

    expect(find.textContaining('10.000000'), findsOneWidget);
    expect(find.textContaining('-20.000000'), findsOneWidget);
    expect(find.textContaining('3.0 m'), findsOneWidget);
  });
}
