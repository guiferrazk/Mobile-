import 'package:flutter/services.dart';

class DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Permite que o usuário apague os caracteres (backspace) normalmente
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    // Remove tudo que não for número
    final textoLimpo = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limita a 8 números (DDMMAAAA)
    if (textoLimpo.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < textoLimpo.length; i++) {
      buffer.write(textoLimpo[i]);
      // Adiciona a barra depois do dia (índice 1) e do mês (índice 3)
      if ((i == 1 || i == 3) && i != textoLimpo.length - 1) {
        buffer.write('/');
      }
    }

    final stringFinal = buffer.toString();
    return newValue.copyWith(
      text: stringFinal,
      selection: TextSelection.collapsed(offset: stringFinal.length),
    );
  }
}