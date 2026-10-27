import 'package:flutter/material.dart';

import 'app.dart';
import 'features/localizacoes/data/database/banco_localizacoes.dart';
import 'features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'features/localizacoes/services/servico_localizacao.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    App(
      servico: ServicoLocalizacao(),
      repositorio: RepositorioLocalizacoes(BancoLocalizacoes()),
    ),
  );
}
