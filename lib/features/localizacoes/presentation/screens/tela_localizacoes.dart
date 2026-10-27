import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({
    super.key,
    required this.repositorio,
    this.coletando = false,
  });

  final RepositorioLocalizacoes repositorio;

  /// Indica se a coleta está ativa, para avisar ao limpar o histórico.
  final bool coletando;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  List<Localizacao>? _itens;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (_itens == null) setState(() => _erro = null);
    try {
      final itens = await widget.repositorio.consultarRecentes();
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _erro = null;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() => _erro = erro);
    }
  }

  Future<void> _limpar() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: Text(
          'Todos os registros serão apagados, inclusive os anteriores aos '
          '100 exibidos. Esta operação é permanente.'
          '${widget.coletando ? '\n\nA coleta está ativa: novos registros continuarão sendo salvos.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await widget.repositorio.excluirTodas();
      if (!mounted) return;
      await _carregar();
      if (!mounted) return;
      _mostrarMensagem('Histórico limpo com sucesso.');
    } catch (erro) {
      _mostrarMensagem('Falha ao limpar o histórico: $erro');
    }
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            icon: const Icon(Icons.delete_sweep),
            onPressed: _limpar,
          ),
        ],
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    final itens = _itens;

    if (itens == null && _erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar o histórico.'),
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

    return RefreshIndicator(
      onRefresh: _carregar,
      child: itens.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Nenhuma localização registrada.')),
              ],
            )
          : ListView.separated(
              itemCount: itens.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => ItemLocalizacao(localizacao: itens[i]),
            ),
    );
  }
}
