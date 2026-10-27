import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/mapa_localizacoes.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key, required this.repositorio, required this.cache});

  final RepositorioLocalizacoes repositorio;
  final CacheMapa cache;

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final _controlador = MapController();

  List<Localizacao>? _itens;
  TileProvider? _tileProvider;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final primeiraCarga = _itens == null;
    if (primeiraCarga) setState(() => _erro = null);

    try {
      // O armazenamento do mapa é preparado antes de qualquer tile carregar.
      final provedor = _tileProvider ?? await widget.cache.criarProvedor();
      final itens = await widget.repositorio.consultarRecentes();
      if (!mounted) return;

      final tinhaPontos = _itens?.isNotEmpty ?? false;
      setState(() {
        _tileProvider = provedor;
        _itens = itens;
        _erro = null;
      });

      if (tinhaPontos && itens.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) MapaLocalizacoes.enquadrar(_controlador, itens);
        });
      }
    } catch (erro) {
      if (!mounted) return;
      if (primeiraCarga) {
        setState(() => _erro = erro);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Falha ao atualizar o mapa: $erro')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = _itens;
    final mapaVisivel = itens != null && itens.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
        ],
      ),
      floatingActionButton: mapaVisivel
          ? FloatingActionButton(
              tooltip: 'Enquadrar todos os pontos',
              onPressed: () => MapaLocalizacoes.enquadrar(_controlador, itens),
              child: const Icon(Icons.zoom_out_map),
            )
          : null,
      body: _corpo(itens),
    );
  }

  Widget _corpo(List<Localizacao>? itens) {
    if (itens == null && _erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar o mapa.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (itens == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (itens.isEmpty) {
      return const Center(
        child: Text('Nenhuma localização para exibir no mapa.'),
      );
    }

    return MapaLocalizacoes(
      localizacoes: itens,
      controlador: _controlador,
      tileProvider: _tileProvider!,
    );
  }
}
