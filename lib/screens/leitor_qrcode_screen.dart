import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

/// Abre a câmera para ler um QR Code e devolve o texto lido com
/// `Navigator.pop`. Se a câmera não estiver disponível ou o professor
/// preferir, o código também pode ser digitado.
class LeitorQrCodeScreen extends StatefulWidget {
  final String titulo;
  final String instrucao;

  const LeitorQrCodeScreen({
    super.key,
    required this.titulo,
    required this.instrucao,
  });

  @override
  State<LeitorQrCodeScreen> createState() => _LeitorQrCodeScreenState();
}

class _LeitorQrCodeScreenState extends State<LeitorQrCodeScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // Evita devolver o resultado duas vezes quando a câmera detecta o mesmo
  // código em quadros seguidos.
  bool _concluido = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aoDetectar(BarcodeCapture captura) {
    if (_concluido) return;

    for (final codigo in captura.barcodes) {
      final texto = codigo.rawValue?.trim() ?? '';
      if (texto.isNotEmpty) {
        _concluir(texto);
        return;
      }
    }
  }

  void _concluir(String texto) {
    if (_concluido || !mounted) return;
    _concluido = true;
    Navigator.pop(context, texto);
  }

  Future<void> _digitarCodigo() async {
    final campo = TextEditingController();

    final texto = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Digitar código'),
        content: TextField(
          controller: campo,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Código impresso abaixo do QR Code',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (valor) => Navigator.pop(context, valor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, campo.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    campo.dispose();

    if (texto != null && texto.trim().isNotEmpty) {
      _concluir(texto.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TituloPagina(icone: Icons.qr_code_scanner, texto: widget.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Lanterna',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined),
            tooltip: 'Trocar câmera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _aoDetectar,
            errorBuilder: (context, erro) => _ErroCamera(
              erro: erro,
              aoDigitar: _digitarCodigo,
            ),
          ),
          const _Moldura(),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Column(
              children: [
                Text(
                  widget.instrucao,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _digitarCodigo,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Digitar código'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quadrado no centro da tela indicando onde posicionar o QR Code.
class _Moldura extends StatelessWidget {
  const _Moldura();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ErroCamera extends StatelessWidget {
  final MobileScannerException erro;
  final VoidCallback aoDigitar;

  const _ErroCamera({required this.erro, required this.aoDigitar});

  String get _mensagem {
    return switch (erro.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'O app não tem permissão para usar a câmera. '
            'Libere o acesso nas configurações do aparelho.',
      MobileScannerErrorCode.unsupported =>
        'Não foi encontrada uma câmera disponível neste aparelho.',
      _ => 'Não foi possível abrir a câmera.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: Colors.white70, size: 56),
              const SizedBox(height: 16),
              Text(
                _mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você ainda pode digitar o código impresso na folha.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: aoDigitar,
                icon: const Icon(Icons.keyboard),
                label: const Text('Digitar código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
