import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

/// Abre a câmera para ler um QR Code e devolve o texto lido com
/// `Navigator.pop`. Se a câmera não estiver disponível ou o professor
/// preferir, o código também pode ser digitado.
class LeitorQrCodeScreen extends StatefulWidget {
  final String titulo;
  final String instrucao;

  /// O que o professor deve digitar quando não usar a câmera, por exemplo
  /// "Código da prova" ou "Matrícula do aluno".
  final String rotuloCodigo;

  const LeitorQrCodeScreen({
    super.key,
    required this.titulo,
    required this.instrucao,
    this.rotuloCodigo = 'Código impresso abaixo do QR Code',
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
          decoration: InputDecoration(
            labelText: widget.rotuloCodigo,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (valor) => Future.microtask(() => Navigator.pop(context, valor)),
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
    // O estado da câmera decide o que aparece: com câmera, a moldura de
    // leitura; sem câmera, só o aviso. Assim as duas coisas nunca se
    // sobrepõem.
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: _controller,
      builder: (context, estado, _) {
        final semCamera = estado.error != null;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: TituloPagina(icone: Icons.qr_code_scanner, texto: widget.titulo),
            actions: [
              if (!semCamera) ...[
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
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _aoDetectar,
                      errorBuilder: (context, erro) => _AvisoSemCamera(erro: erro),
                    ),
                    if (!semCamera) const _Moldura(),
                  ],
                ),
              ),
              _PainelInferior(
                instrucao: semCamera
                    ? 'Sem câmera? Toque em "Digitar código" e informe: '
                        '${widget.rotuloCodigo.toLowerCase()}.'
                    : widget.instrucao,
                destacarBotao: semCamera,
                aoDigitar: _digitarCodigo,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Quadrado indicando onde posicionar o QR Code. O tamanho acompanha a
/// tela, para caber bem tanto no celular quanto no computador.
class _Moldura extends StatelessWidget {
  const _Moldura();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, restricoes) {
          final lado = math.min(
            260.0,
            math.min(restricoes.maxWidth, restricoes.maxHeight) * 0.7,
          );

          return Center(
            child: Container(
              width: lado,
              height: lado,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Faixa fixa na parte de baixo, separada da área da câmera, com a
/// instrução e a opção de digitar o código.
class _PainelInferior extends StatelessWidget {
  final String instrucao;
  final bool destacarBotao;
  final VoidCallback aoDigitar;

  const _PainelInferior({
    required this.instrucao,
    required this.destacarBotao,
    required this.aoDigitar,
  });

  @override
  Widget build(BuildContext context) {
    final botao = destacarBotao
        ? ElevatedButton.icon(
            onPressed: aoDigitar,
            icon: const Icon(Icons.keyboard),
            label: const Text('Digitar código'),
          )
        : OutlinedButton.icon(
            onPressed: aoDigitar,
            icon: const Icon(Icons.keyboard),
            label: const Text('Digitar código'),
          );

    return Container(
      width: double.infinity,
      color: AppCores.superficie,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    instrucao,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppCores.texto,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  botao,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso mostrado no lugar da imagem da câmera quando ela não pode ser usada.
class _AvisoSemCamera extends StatelessWidget {
  final MobileScannerException erro;

  const _AvisoSemCamera({required this.erro});

  ({String titulo, String detalhe}) get _texto {
    return switch (erro.errorCode) {
      MobileScannerErrorCode.permissionDenied => (
          titulo: 'Sem permissão para usar a câmera',
          detalhe: 'Libere o acesso à câmera nas configurações do aparelho '
              'ou do navegador.',
        ),
      MobileScannerErrorCode.unsupported => (
          titulo: 'Câmera não encontrada',
          detalhe: 'Este aparelho não tem uma câmera disponível.',
        ),
      _ => (
          titulo: 'Não foi possível abrir a câmera',
          detalhe: 'Feche outros apps que estejam usando a câmera e tente de novo.',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final texto = _texto;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white70,
                  size: 56,
                ),
                const SizedBox(height: 20),
                Text(
                  texto.titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  texto.detalhe,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
