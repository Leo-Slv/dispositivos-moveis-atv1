import 'package:flutter/material.dart';

import 'features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'features/localizacoes/presentation/screens/tela_coleta.dart';
import 'features/localizacoes/services/servico_localizacao.dart';

class App extends StatelessWidget {
  const App({super.key, required this.servico, required this.repositorio});

  final ServicoLocalizacao servico;
  final RepositorioLocalizacoes repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localizações',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: TelaColeta(servico: servico, repositorio: repositorio),
    );
  }
}
