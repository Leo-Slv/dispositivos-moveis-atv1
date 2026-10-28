import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../../services/servico_localizacao.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({
    super.key,
    required this.servico,
    required this.repositorio,
    required this.cacheMapa,
  });

  final ServicoLocalizacao servico;
  final RepositorioLocalizacoes repositorio;
  final CacheMapa cacheMapa;

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  /// Tempo sem nenhuma posição após o qual o usuário é avisado.
  static const tempoAlertaSemPosicao = Duration(seconds: 45);

  StreamSubscription<Position>? _assinatura;
  Timer? _alertaSemPosicao;
  bool _iniciando = false;
  bool _semPosicao = false;
  int _gravadas = 0;
  Localizacao? _ultima;

  // Serializa as gravações para que nunca se sobreponham.
  Future<void> _fila = Future<void>.value();

  bool get _coletando => _assinatura != null;

  @override
  void dispose() {
    _alertaSemPosicao?.cancel();
    _assinatura?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    if (_coletando || _iniciando) return;
    setState(() => _iniciando = true);

    try {
      final situacao = await widget.servico.verificar();
      if (!mounted) return;

      if (situacao != SituacaoColeta.pronta) {
        await _orientar(situacao);
        return;
      }

      await widget.servico.solicitarPermissaoNotificacao();
      if (!mounted) return;

      _ultima = null;
      _semPosicao = false;
      _assinatura = widget.servico.posicoes().listen(
        _aoReceber,
        onError: _aoFalhar,
      );
      _alertaSemPosicao?.cancel();
      _alertaSemPosicao = Timer(tempoAlertaSemPosicao, _aoExpirarAlerta);
    } catch (erro) {
      _mostrarMensagem('Não foi possível iniciar a coleta: $erro');
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  Future<void> _parar() async {
    final assinatura = _assinatura;
    if (assinatura == null) return;
    _alertaSemPosicao?.cancel();
    setState(() {
      _assinatura = null;
      _semPosicao = false;
    });
    await assinatura.cancel();
  }

  void _aoExpirarAlerta() {
    if (mounted && _coletando && _ultima == null) {
      setState(() => _semPosicao = true);
    }
  }

  Future<void> _abrirHistorico() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaLocalizacoes(
          repositorio: widget.repositorio,
          coletando: _coletando,
        ),
      ),
    );
  }

  Future<void> _abrirMapa() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TelaMapa(repositorio: widget.repositorio, cache: widget.cacheMapa),
      ),
    );
  }

  void _aoReceber(Position posicao) {
    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp.toUtc(),
    );

    _alertaSemPosicao?.cancel();
    if (mounted) {
      setState(() {
        _ultima = localizacao;
        _semPosicao = false;
      });
    }

    _fila = _fila.then((_) async {
      try {
        await widget.repositorio.inserir(localizacao);
        if (mounted) setState(() => _gravadas++);
      } catch (erro) {
        _mostrarMensagem('Falha ao gravar a localização: $erro');
      }
    });
  }

  void _aoFalhar(Object erro) {
    _parar();
    _mostrarMensagem('Erro na coleta de localização: $erro');
  }

  Future<void> _orientar(SituacaoColeta situacao) {
    switch (situacao) {
      case SituacaoColeta.servicoDesligado:
        return _mostrarOrientacao(
          titulo: 'Localização desligada',
          mensagem: 'Ative o GPS do aparelho para coletar posições.',
          acao: 'Abrir configurações',
          aoConfirmar: widget.servico.abrirConfiguracoesLocalizacao,
        );
      case SituacaoColeta.permissaoNegadaPermanente:
        return _mostrarOrientacao(
          titulo: 'Permissão bloqueada',
          mensagem:
              'A permissão de localização foi negada permanentemente. '
              'Habilite-a nas configurações do aplicativo.',
          acao: 'Abrir configurações',
          aoConfirmar: widget.servico.abrirConfiguracoesApp,
        );
      case SituacaoColeta.permissaoNegada:
      case SituacaoColeta.pronta:
        return _mostrarOrientacao(
          titulo: 'Permissão necessária',
          mensagem:
              'Sem a permissão de localização não é possível coletar posições.',
          acao: 'Abrir configurações',
          aoConfirmar: widget.servico.abrirConfiguracoesApp,
        );
    }
  }

  Future<void> _mostrarOrientacao({
    required String titulo,
    required String mensagem,
    required String acao,
    required Future<bool> Function() aoConfirmar,
  }) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: Text(acao),
          ),
        ],
      ),
    );
    if (confirmou == true) await aoConfirmar();
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Mostra a última posição recebida, ou o que se espera enquanto não chega.
  Widget _painelUltimaPosicao(BuildContext context) {
    final ultima = _ultima;
    if (ultima != null) {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('Última posição recebida'),
            ),
            ItemLocalizacao(localizacao: ultima),
          ],
        ),
      );
    }

    if (!_coletando) return const SizedBox.shrink();

    if (_semPosicao) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Nenhuma posição recebida ainda. Verifique se o GPS está ligado '
            'em alta precisão e vá para um local aberto, com visão do céu.',
          ),
        ),
      );
    }

    return const Text(
      'Aguardando a primeira posição...',
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final coletando = _coletando;

    return Scaffold(
      appBar: AppBar(title: const Text('Coleta de localização')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              coletando ? 'Coleta ativa' : 'Coleta parada',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Posições gravadas nesta sessão: $_gravadas',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _painelUltimaPosicao(context),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: coletando || _iniciando ? null : _iniciar,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar coleta'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: coletando ? _parar : null,
              icon: const Icon(Icons.stop),
              label: const Text('Parar coleta'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _abrirHistorico,
              icon: const Icon(Icons.history),
              label: const Text('Consultar histórico'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _abrirMapa,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver mapa'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.servico.abrirConfiguracoesApp,
              icon: const Icon(Icons.settings),
              label: const Text('Configurações de permissão'),
            ),
          ],
        ),
      ),
    );
  }
}
