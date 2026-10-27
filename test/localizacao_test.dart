import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toMap grava o instante em UTC no formato ISO 8601', () {
    final localizacao = Localizacao(
      latitude: -23.5505,
      longitude: -46.6333,
      precisao: 12.5,
      instante: DateTime.utc(2026, 11, 2, 15, 30),
    );

    final mapa = localizacao.toMap();

    expect(mapa.containsKey('id'), isFalse);
    expect(mapa['instante'], '2026-11-02T15:30:00.000Z');
  });

  test('fromMap reconstrói o objeto a partir do mapa', () {
    final localizacao = Localizacao.fromMap({
      'id': 3,
      'latitude': -23.5505,
      'longitude': -46.6333,
      'precisao': 12,
      'instante': '2026-11-02T15:30:00.000Z',
    });

    expect(localizacao.id, 3);
    expect(localizacao.precisao, 12.0);
    expect(localizacao.instante.isUtc, isTrue);
    expect(localizacao.instante, DateTime.utc(2026, 11, 2, 15, 30));
  });
}
