import 'dart:async';

import 'package:atv1_localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:atv1_localizacoes/features/localizacoes/models/localizacao.dart';

class RepositorioFalso implements RepositorioLocalizacoes {
  RepositorioFalso([Iterable<Localizacao> iniciais = const []])
    : gravadas = [...iniciais];

  /// Registros na ordem em que a consulta os devolve.
  final List<Localizacao> gravadas;

  int consultas = 0;
  int exclusoes = 0;
  int? limiteRecebido;

  Object? erroConsulta;
  Object? erroExclusao;

  /// Quando definido, a consulta espera este completer.
  Completer<void>? bloqueioConsulta;

  @override
  Future<int> inserir(Localizacao localizacao) async {
    gravadas.add(localizacao);
    return gravadas.length;
  }

  @override
  Future<List<Localizacao>> consultarRecentes({
    int limite = RepositorioLocalizacoes.limitePadrao,
  }) async {
    consultas++;
    limiteRecebido = limite;
    await bloqueioConsulta?.future;
    final erro = erroConsulta;
    if (erro != null) throw erro;
    return List.of(gravadas);
  }

  @override
  Future<void> excluirTodas() async {
    exclusoes++;
    final erro = erroExclusao;
    if (erro != null) throw erro;
    gravadas.clear();
  }
}
