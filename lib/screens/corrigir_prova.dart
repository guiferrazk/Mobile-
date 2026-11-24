import 'package:flutter/material.dart';
import 'package:mobile/widgets/titulo_pagina.dart';
import 'package:mobile/theme/app_theme.dart';

import '../models/aluno_model.dart';
import '../models/prova_model.dart';
import '../services/localizador_prova.dart';
import 'leitor_qrcode_screen.dart';
import 'resultado_prova_screen.dart';
import 'selecionar_aluno_screen.dart';


/// Fluxo de correção de provas.
///
/// Primeiro o professor lê o QR Code do gabarito, que identifica a prova
/// no Firestore. Depois lê o QR Code da folha de resposta de cada aluno;
/// o app confere se a folha é da mesma prova e localiza o aluno. Se a
/// folha não puder ser lida, o aluno também pode ser escolhido na lista.
class CorrigirProvaScreen extends StatefulWidget {
  const CorrigirProvaScreen({super.key});

  @override
  State<CorrigirProvaScreen> createState() => _CorrigirProvaScreenState();
}

class _CorrigirProvaScreenState extends State<CorrigirProvaScreen> {
  final _localizador = LocalizadorProva.firestore();

  Prova? _prova;
  bool _buscando = false;

  Future<void> _lerQrCodeGabarito() async {
    final conteudo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const LeitorQrCodeScreen(
          titulo: 'Ler Gabarito',
          instrucao: 'Aponte a câmera para o QR Code do gabarito.',
        ),
      ),
    );

    if (conteudo == null || !mounted) return;

    setState(() => _buscando = true);

    try {
      final prova = await _localizador.localizarGabarito(conteudo);
      if (!mounted) return;
      setState(() => _prova = prova);
    } on LeituraQrCodeException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (e) {
      _mostrarMensagem('Não foi possível buscar a prova: $e');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _lerFolhaAluno() async {
    final prova = _prova;
    if (prova == null) return;

    final conteudo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const LeitorQrCodeScreen(
          titulo: 'Ler Folha do Aluno',
          instrucao: 'Aponte a câmera para o QR Code da folha de resposta.',
        ),
      ),
    );

    if (conteudo == null || !mounted) return;

    setState(() => _buscando = true);

    try {
      final aluno = await _localizador.localizarAlunoDaFolha(
        conteudo,
        prova: prova,
      );
      if (!mounted) return;
      _abrirProvaDoAluno(aluno, prova);
    } on LeituraQrCodeException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (e) {
      _mostrarMensagem('Não foi possível buscar o aluno: $e');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  /// Alternativa para quando o QR Code da folha está danificado ou ilegível.
  Future<void> _escolherAlunoNaLista() async {
    final prova = _prova;
    if (prova == null) return;

    final aluno = await Navigator.push<Aluno>(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarAlunoScreen()),
    );

    if (aluno == null || !mounted) return;
    _abrirProvaDoAluno(aluno, prova);
  }

  void _abrirProvaDoAluno(Aluno aluno, Prova prova) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProvaAlunoLidaScreen(aluno: aluno, prova: prova),
      ),
    );
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prova = _prova;

    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(icone: Icons.document_scanner_outlined, texto: 'Corrigir Prova'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            // Limita a largura do conteúdo em telas grandes (web/desktop)
            // e deixa tudo centralizado, evitando botões esticados
            // de ponta a ponta da tela.
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: AppCores.textoSuave,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Para corrigir a prova, leia primeiro o QR Code do '
                      'gabarito e, em seguida, a prova do aluno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                if (prova != null) ...[
                  _GabaritoLido(prova: prova),
                  const SizedBox(height: 24),
                ],
                if (_buscando)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ElevatedButton.icon(
                  onPressed: _buscando ? null : _lerQrCodeGabarito,
                  icon: const Icon(Icons.qr_code),
                  label: Text(
                    prova == null
                        ? 'Ler QR Code do gabarito'
                        : 'Ler outro gabarito',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: prova == null || _buscando ? null : _lerFolhaAluno,
                  icon: const Icon(Icons.assignment),
                  label: const Text('Ler prova do aluno'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                if (prova != null)
                  TextButton(
                    onPressed: _buscando ? null : _escolherAlunoNaLista,
                    child: const Text('Folha ilegível? Escolher o aluno na lista'),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'A leitura da prova do aluno é liberada depois que o '
                      'gabarito é lido.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppCores.textoSuave),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resumo da prova identificada pelo QR Code do gabarito.
class _GabaritoLido extends StatelessWidget {
  final Prova prova;

  const _GabaritoLido({required this.prova});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: AppCores.sucesso, size: 36),
        title: Text(prova.titulo),
        subtitle: Text(
          'Gabarito lido · ${prova.questaoIds.length} questão(ões)',
        ),
      ),
    );
  }
}

/// Tela exibida depois que a folha do aluno foi identificada.
class ProvaAlunoLidaScreen extends StatelessWidget {
  final Aluno aluno;
  final Prova prova;

  const ProvaAlunoLidaScreen({
    super.key,
    required this.aluno,
    required this.prova,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prova do Aluno Lida'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppCores.sucesso, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Prova identificada com sucesso!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Text('Prova: ${prova.titulo}'),
                const SizedBox(height: 8),
                Text('Aluno: ${aluno.nome}'),
                const SizedBox(height: 8),
                Text('Matrícula: ${aluno.matricula}'),

                // --- BOTÃO ADICIONADO AQUI ---
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navega para a tela de resultado que você criou
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultadoProvaScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('Ver Resultado da Correção'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
