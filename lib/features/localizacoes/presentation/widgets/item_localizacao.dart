import 'package:flutter/material.dart';

import '../../models/localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({super.key, required this.localizacao});

  final Localizacao localizacao;

  static String _dois(int valor) => valor.toString().padLeft(2, '0');

  static String formatarDataHora(DateTime instanteLocal) {
    final d = instanteLocal;
    return '${_dois(d.day)}/${_dois(d.month)}/${d.year} '
        '${_dois(d.hour)}:${_dois(d.minute)}:${_dois(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.place_outlined),
      title: Text(formatarDataHora(localizacao.instanteLocal)),
      subtitle: Text(
        'Lat: ${localizacao.latitude.toStringAsFixed(6)}\n'
        'Lon: ${localizacao.longitude.toStringAsFixed(6)}\n'
        'Precisão: ${localizacao.precisao.toStringAsFixed(1)} m',
      ),
      isThreeLine: true,
    );
  }
}
