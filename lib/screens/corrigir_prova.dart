
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobile/services/correcao_folha.dart';
import 'package:mobile/services/leitor_marcacoes.dart';
import 'package:mobile/widgets/titulo_pagina.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/utils/mensagens_erro.dart';

import '../models/aluno_model.dart';
import '../models/prova_model.dart';
import '../models/variacao_prova_model.dart';

import '../models/resultado_model.dart';
import '../services/localizador_prova.dart';
import '../services/questao_service.dart';
import '../services/resultado_service.dart';
import 'resultado_prova_screen.dart';
import '../services/prova_service.dart';
import '../services/variacao_prova_service.dart';

import 'leitor_qrcode_screen.dart';
import 'selecionar_aluno_screen.dart';

class CorrigirProvaScreen extends StatefulWidget {
  const CorrigirProvaScreen({super.key});

  @override
  State<CorrigirProvaScreen> createState() =>
      _CorrigirProvaScreenState();
}

class _CorrigirProvaScreenState
    extends State<CorrigirProvaScreen> {
  final _localizador = LocalizadorProva.firestore();
  final _provaService = ProvaService();

  late final Stream<List<Prova>> _provasStream;

  Prova? _prova;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _provasStream = _provaService.listar();
  }

  /// NOVO: seleciona uma prova sem precisar de QR Code.
  Future<void> _selecionarProvaNaLista() async {
    final provaSelecionada = await showDialog<Prova>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Selecionar prova'),
        content: SizedBox(
          width: 480,
          height: 360,
          child: StreamBuilder<List<Prova>>(
            stream: _provasStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar provas: '
                    '${MensagensErro.de(snapshot.error)}',
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final provas = snapshot.data!;

              if (provas.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma prova cadastrada.',
                  ),
                );
              }

              return ListView.separated(
                itemCount: provas.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final prova = provas[index];

                  return ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                    ),
                    title: Text(prova.titulo),
                    subtitle: Text(
                      '${prova.questaoIds.length} questão(ões)',
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop(prova);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (!mounted || provaSelecionada == null) return;

    setState(() {
      _prova = provaSelecionada;
    });
  }

  /// Identifica o gabarito pelo QR Code ou código digitado.
  Future<void> _lerQrCodeGabarito() async {
    final conteudo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const LeitorQrCodeScreen(
          titulo: 'Ler Gabarito',
          instrucao:
              'Aponte a câmera para o QR Code do gabarito.',
          rotuloCodigo: 'Código da prova',
        ),
      ),
    );

    if (conteudo == null || !mounted) return;

    setState(() => _buscando = true);

    try {
      final prova =
          await _localizador.localizarGabarito(conteudo);

      if (!mounted) return;

      setState(() => _prova = prova);
    } on LeituraQrCodeException catch (erro) {
      _mostrarMensagem(erro.mensagem);
    } catch (erro) {
      _mostrarMensagem(
        'Não foi possível buscar a prova. '
        '${MensagensErro.de(erro)}',
      );
    } finally {
      if (mounted) {
        setState(() => _buscando = false);
      }
    }
  }

  /// Identifica o aluno por QR Code ou matrícula.
  Future<void> _lerFolhaAluno() async {
    final prova = _prova;

    if (prova == null) return;

    final conteudo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const LeitorQrCodeScreen(
          titulo: 'Ler Folha do Aluno',
          instrucao:
              'Aponte a câmera para o QR Code da folha.',
          rotuloCodigo: 'Matrícula do aluno',
        ),
      ),
    );

    if (conteudo == null || !mounted) return;

    setState(() => _buscando = true);

    try {
      final aluno =
          await _localizador.localizarAlunoDaFolha(
        conteudo,
        prova: prova,
      );

      if (!mounted) return;

      _abrirProvaDoAluno(aluno, prova);
    } on LeituraQrCodeException catch (erro) {
      _mostrarMensagem(erro.mensagem);
    } catch (erro) {
      _mostrarMensagem(
        'Não foi possível buscar o aluno. '
        '${MensagensErro.de(erro)}',
      );
    } finally {
      if (mounted) {
        setState(() => _buscando = false);
      }
    }
  }

  /// Seleciona um aluno sem precisar do QR Code.
  Future<void> _escolherAlunoNaLista() async {
    final prova = _prova;

    if (prova == null) return;

    final aluno = await Navigator.push<Aluno>(
      context,
      MaterialPageRoute(
        builder: (_) => SelecionarAlunoScreen(provaId: prova.id),
      ),
    );

    if (aluno == null || !mounted) return;

    _abrirProvaDoAluno(aluno, prova);
  }

  void _abrirProvaDoAluno(Aluno aluno, Prova prova) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProvaAlunoLidaScreen(
          aluno: aluno,
          prova: prova,
        ),
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
        title: const TituloPagina(
          icone: Icons.document_scanner_outlined,
          texto: 'Corrigir Prova',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: AppCores.textoSuave,
                ),

                const SizedBox(height: 32),

                const Text(
                  'Identifique a prova pelo QR Code ou '
                  'selecione uma prova cadastrada. '
                  'Depois, identifique o aluno.',
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
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed:
                      _buscando ? null : _lerQrCodeGabarito,
                  icon: const Icon(Icons.qr_code),
                  label: Text(
                    prova == null
                        ? 'Ler QR Code do gabarito'
                        : 'Ler outro gabarito',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 12),

                // NOVO botão para selecionar a prova.
                OutlinedButton.icon(
                  onPressed: _buscando
                      ? null
                      : _selecionarProvaNaLista,
                  icon: const Icon(Icons.list_alt),
                  label: const Text(
                    'Selecionar prova na lista',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: prova == null || _buscando
                      ? null
                      : _lerFolhaAluno,
                  icon: const Icon(Icons.assignment),
                  label: const Text('Ler prova do aluno'),
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, 50),
                  ),
                ),

                if (prova != null)
                  TextButton(
                    onPressed: _buscando
                        ? null
                        : _escolherAlunoNaLista,
                    child: const Text(
                      'Folha ilegível? Escolher o aluno na lista',
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Selecione a prova para liberar '
                      'a identificação do aluno.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppCores.textoSuave,
                      ),
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

class _GabaritoLido extends StatelessWidget {
  final Prova prova;

  const _GabaritoLido({required this.prova});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.check_circle,
          color: AppCores.sucesso,
          size: 36,
        ),
        title: Text(prova.titulo),
        subtitle: Text(
          'Prova identificada - '
          '${prova.questaoIds.length} questão(ões)',
        ),
      ),
    );
  }
}

/// Recupera a variação individual salva para o aluno.
class ProvaAlunoLidaScreen extends StatefulWidget {
  final Aluno aluno;
  final Prova prova;

  const ProvaAlunoLidaScreen({
    super.key,
    required this.aluno,
    required this.prova,
  });

  @override
  State<ProvaAlunoLidaScreen> createState() =>
      _ProvaAlunoLidaScreenState();
}

class _ProvaAlunoLidaScreenState
    extends State<ProvaAlunoLidaScreen> {
  final _variacaoService = VariacaoProvaService();

  late final Future<VariacaoProva?> _variacaoFuture;

  final Map<int, int> _respostasMarcadas = {};

  int? _acertos;

  /// Resultado montado ao conferir, já com as respostas na ordem original
  /// das questões. É exatamente o que vai para o Firestore.
  Resultado? _resultadoConferido;

  final _questaoService = QuestaoService();
  final _resultadoService = ResultadoService();
  bool _salvando = false;

  bool _lendoFolha = false;
  MarcacoesLidas? _leitura;

  bool _precisaConferir(int questao) {
    final leitura = _leitura;
    if (leitura == null) return false;
    return leitura.emBranco.contains(questao) ||
        leitura.marcacaoDupla.contains(questao);
  }

  /// Fotografa (ou escolhe a foto da) folha de respostas e preenche a
  /// conferência com as alternativas reconhecidas. O professor confere
  /// antes de salvar.
  Future<void> _lerFolha(VariacaoProva variacao, ImageSource origem) async {
    if (_lendoFolha) return;

    final XFile? foto;
    try {
      foto = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
    } catch (_) {
      _avisar(
        'Não foi possível abrir a câmera. Confira se o app tem '
        'permissão para usá-la.',
      );
      return;
    }
    if (foto == null || !mounted) return;

    setState(() => _lendoFolha = true);

    try {
      final bytes = await foto.readAsBytes();
      final alternativas = [
        for (final questao in variacao.questoes) questao.alternativas.length,
      ];
      // A leitura percorre a foto inteira; em segundo plano a tela não trava.
      final lidas = await compute(_lerMarcacoes, (bytes, alternativas));
      if (!mounted) return;

      setState(() {
        _leitura = lidas;
        _acertos = null;
        _resultadoConferido = null;
        _respostasMarcadas
          ..clear()
          ..addAll({
            for (var i = 0; i < lidas.respostas.length; i++)
              if (lidas.respostas[i] != null) i: lidas.respostas[i]!,
          });
      });
    } on LeituraFolhaException catch (e) {
      _avisar(e.mensagem);
    } catch (_) {
      _avisar('Não foi possível ler a folha. Tente outra foto.');
    } finally {
      if (mounted) setState(() => _lendoFolha = false);
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  void initState() {
    super.initState();

    _variacaoFuture = _variacaoService.buscar(
      widget.prova.id,
      widget.aluno.id,
    );
  }

  /// Confere as respostas marcadas (lidas da folha ou escolhidas à mão).
  /// Questões sem resposta podem ficar em branco e contam como erro.
  Future<void> _conferirRespostas(VariacaoProva variacao) async {
    final emBranco = CorrecaoFolha.emBranco(variacao, _respostasMarcadas);

    if (emBranco.isNotEmpty) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Questões em branco'),
          content: Text(
            emBranco.length == 1
                ? 'A questão ${emBranco.first + 1} está sem resposta e '
                    'vai contar como erro. Deseja continuar?'
                : 'As questões ${emBranco.map((i) => i + 1).join(', ')} '
                    'estão sem resposta e vão contar como erro. '
                    'Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar e revisar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (continuar != true || !mounted) return;
    }

    try {
      final resultado = CorrecaoFolha.corrigir(
        prova: widget.prova,
        aluno: widget.aluno,
        variacao: variacao,
        marcadas: _respostasMarcadas,
      );

      setState(() {
        _resultadoConferido = resultado;
        _acertos = resultado.acertos;
      });
    } on CorrecaoFolhaException catch (e) {
      _avisar(e.mensagem);
    }
  }

  /// Grava o resultado conferido (substituindo o anterior do aluno nesta
  /// prova) e abre a tela de resultado com os dados reais.
  Future<void> _registrarResultado() async {
    final resultado = _resultadoConferido;
    if (_salvando || resultado == null) return;
    setState(() => _salvando = true);

    try {
      await _resultadoService.salvar(resultado);

      // As questões são carregadas só para a tela de resultado mostrar os
      // enunciados; a nota salva é a conferida acima.
      final todas = await _questaoService.listar().first;
      final porId = {for (final q in todas) q.id: q};
      final questoes = [
        for (final id in widget.prova.questaoIds)
          if (porId[id] != null) porId[id]!,
      ];
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadoProvaScreen(
            resultado: resultado,
            questoes: questoes,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar o resultado. ${MensagensErro.de(e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _mostrarVariacao(VariacaoProva variacao) {
    if (variacao.provaId != widget.prova.id ||
        variacao.alunoId != widget.aluno.id) {
      return const Text(
        'A variação recuperada não corresponde '
        'à prova ou ao aluno identificado.',
      );
    }

    if (variacao.questoes.isEmpty ||
        variacao.questoes.length !=
            widget.prova.questaoIds.length) {
      return const Text(
        'Os dados da variação estão incompletos. '
        'Verifique o registro no Firestore.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  color: AppCores.sucesso,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Variação individual recuperada '
                    'do Firestore!',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _LeituraDaFolha(
          lendo: _lendoFolha,
          leitura: _leitura,
          aoFotografar: () => _lerFolha(variacao, ImageSource.camera),
          aoEscolherFoto: () => _lerFolha(variacao, ImageSource.gallery),
        ),

        const SizedBox(height: 16),

        const Text(
          'Conferência manual de respostas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Marque as respostas do aluno conforme '
          'a ordem que aparece na sua prova.',
        ),

        const SizedBox(height: 16),

        for (var i = 0; i < variacao.questoes.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            // Questões que a leitura não conseguiu decidir ficam em destaque.
            shape: _precisaConferir(i)
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppCores.alerta, width: 2),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${i + 1}. '
                    '${variacao.questoes[i].enunciado}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  for (var j = 0;
                      j <
                          variacao
                              .questoes[i].alternativas.length;
                      j++)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 6),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            // Tocar de novo na marcada deixa a questão
                            // em branco.
                            if (_respostasMarcadas[i] == j) {
                              _respostasMarcadas.remove(i);
                            } else {
                              _respostasMarcadas[i] = j;
                            }
                            _acertos = null;
                            _resultadoConferido = null;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _respostasMarcadas[i] == j
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                '${String.fromCharCode(65 + j)}) '
                                '${variacao.questoes[i].alternativas[j].texto}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: () =>
              _conferirRespostas(variacao),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Conferir respostas'),
        ),

        if (_acertos != null) ...[
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Resultado da conferência manual',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '$_acertos de '
                    '${variacao.questoes.length} acertos',
                    style: const TextStyle(fontSize: 20),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Nota: ${(_acertos! / variacao.questoes.length * 10).toStringAsFixed(1)}',
                  ),

                  if (_resultadoConferido != null &&
                      _resultadoConferido!.respostas.values
                          .any((resposta) => resposta == null)) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Em branco: ${_resultadoConferido!.respostas.values.where((resposta) => resposta == null).length}',
                      style: const TextStyle(color: AppCores.textoSuave),
                    ),
                  ],

                  const SizedBox(height: 8),

                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _registrarResultado,
                    icon: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _salvando ? 'Salvando...' : 'Registrar resultado',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prova do Aluno Lida'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.check_circle,
                color: AppCores.sucesso,
                size: 60,
              ),

              const SizedBox(height: 16),

              Text(
                'Prova identificada com sucesso!',
                style:
                    Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 24),

              Text('Prova: ${widget.prova.titulo}'),

              const SizedBox(height: 8),

              Text('Aluno: ${widget.aluno.nome}'),

              const SizedBox(height: 8),

              Text(
                'Matrícula: ${widget.aluno.matricula}',
              ),

              const SizedBox(height: 20),

              FutureBuilder<VariacaoProva?>(
                future: _variacaoFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Erro ao recuperar a variação: '
                      '${MensagensErro.de(snapshot.error)}',
                    );
                  }

                  if (snapshot.connectionState !=
                      ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final variacao = snapshot.data;

                  if (variacao == null) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nenhuma variação individual foi '
                          'encontrada para este aluno.\n\n'
                          'Gere a variação em Consultar provas '
                          'antes de realizar a correção.',
                        ),
                      ),
                    );
                  }

                  return _mostrarVariacao(variacao);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Roda fora da tela (em outro isolate no celular) para a leitura da foto
/// não travar a interface.
MarcacoesLidas _lerMarcacoes((Uint8List, List<int>) dados) {
  return LeitorMarcacoes.ler(dados.$1, alternativasPorQuestao: dados.$2);
}

/// Card com os botões para ler a folha pela câmera e o resumo da leitura.
class _LeituraDaFolha extends StatelessWidget {
  final bool lendo;
  final MarcacoesLidas? leitura;
  final VoidCallback aoFotografar;
  final VoidCallback aoEscolherFoto;

  const _LeituraDaFolha({
    required this.lendo,
    required this.leitura,
    required this.aoFotografar,
    required this.aoEscolherFoto,
  });

  String _questoes(List<int> indices) =>
      indices.map((i) => '${i + 1}').join(', ');

  @override
  Widget build(BuildContext context) {
    final lida = leitura;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ler marcações da folha',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fotografe a folha de respostas inteira, de frente e com boa '
              'luz, com os quatro quadrados pretos dos cantos aparecendo.',
            ),
            const SizedBox(height: 16),
            if (lendo)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Lendo a folha...'),
                  ],
                ),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: aoFotografar,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Fotografar folha'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: aoEscolherFoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Escolher foto da folha'),
              ),
            ],
            if (lida != null && !lendo) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppCores.sucesso),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${lida.lidas} de ${lida.respostas.length} questões '
                      'reconhecidas.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (lida.emBranco.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Em branco: ${_questoes(lida.emBranco)}.'),
              ],
              if (lida.marcacaoDupla.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Mais de uma alternativa marcada: '
                  '${_questoes(lida.marcacaoDupla)}.',
                ),
              ],
              const SizedBox(height: 6),
              Text(
                lida.emBranco.isEmpty && lida.marcacaoDupla.isEmpty
                    ? 'Confira as respostas abaixo antes de salvar.'
                    : 'As questões em destaque abaixo precisam ser conferidas '
                          'na folha antes de salvar.',
                style: const TextStyle(color: AppCores.textoSuave),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
