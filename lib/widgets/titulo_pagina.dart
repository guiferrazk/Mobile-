import 'package:flutter/material.dart';

/// Título da barra superior com um ícone antes do texto.
class TituloPagina extends StatelessWidget {
  final IconData icone;
  final String texto;

  const TituloPagina({super.key, required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    // Dentro da AppBar o ícone não herda a cor do texto sozinho,
    // então pegamos a cor do estilo de texto atual.
    final cor = DefaultTextStyle.of(context).style.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 22, color: cor),
        const SizedBox(width: 10),
        Flexible(
          child: Text(texto, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
