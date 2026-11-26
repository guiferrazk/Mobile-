import 'package:flutter/material.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/models/status_prova.dart';
import 'package:mobile/screens/estatisticas_prova_screen.dart';
import 'package:mobile/services/exportacao_resultados_service.dart';
import 'package:mobile/services/prova_service.dart';
import 'package:mobile/services/resultado_service.dart';
import 'package:mobile/services/variacao_prova_service.dart';
import 'package:mobile/widgets/titulo_pagina.dart';
import 'package:mobile/theme/app_theme.dart';

/// Prova com os ids dos alunos que receberam a prova (variação gerada).
typedef ProvaComAlunos = ({Prova prova, Set<String> alunos});

/// Lista as provas já corrigidas, lendo os resultados do Firestore
/// (coleção `resultados`). A lista atualiza sozinha quando um resultado
/// novo é salvo.
class RelatorioProvasScreen extends StatefulWidget {
  const RelatorioProvasScreen({
    super.key,
    this.listarResultados,
    this.carregarProvas,
  });

  final Stream<List<Resultado>> Function()? listarResultados;

  /// Provas do professor com os alunos que receberam cada uma. Usado no
  /// status de correção; nos testes, pode ser trocado por dados fixos.
  final Future<List<ProvaComAlunos>> Function()? carregarProvas;

  @override
  State<RelatorioProvasScreen> createState() => _RelatorioProvasScreenState();
}

class _RelatorioProvasScreenState extends State<RelatorioProvasScreen> {
  late final Stream<List<Resultado>> Function() _listarResultados =
      widget.listarResultados ?? ResultadoService().listarTodos;
  final ExportacaoResultadosService _exportacaoService =
      ExportacaoResultadosService();

  late Stream<List<Resultado>> _resultadosStream;
  bool _exportando = false;

  late final Future<List<ProvaComAlunos>> Function() _carregarProvas =
      widget.carregarProvas ?? _provasDoFirestore;
  late Future<List<ProvaComAlunos>> _provasFuture;

  @override
  void initState() {
    super.initState();
    _resultadosStream = _listarResultados();
    _provasFuture = _carregarProvasSemFalhar();
  }

  // Cria o stream de novo. Usado no botão "Tentar novamente".
  void _recarregar() {
    setState(() {
      _resultadosStream = _listarResultados();
      _provasFuture = _carregarProvasSemFalhar();
    });
  }

  /// O status é um complemento: se as provas não carregarem, ele só não
  /// aparece, sem deixar um erro sem tratamento (a lista de resultados pode
  /// nem estar na tela para mostrar o status).
  Future<List<ProvaComAlunos>> _carregarProvasSemFalhar() async {
    try {
      return await _carregarProvas();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<ProvaComAlunos>> _provasDoFirestore() async {
    final provas = await ProvaService().listar().first;
    final variacoes = VariacaoProvaService();

    return Future.wait(
      provas.map(
        (prova) async => (
          prova: prova,
          alunos: await variacoes.alunosComVariacao(prova.id),
        ),
      ),
    );
  }

  void _abrirEstatisticas(String provaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstatisticasProvaScreen(provaId: provaId),
      ),
    );
  }

  Future<void> _exportarExcel(List<Resultado> resultados) async {
    if (_exportando) return;

    setState(() => _exportando = true);
    try {
      final arquivo = await _exportacaoService.salvarPlanilha(resultados);
      if (!mounted || arquivo == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planilha salva com sucesso.')),
      );
    } on ExportacaoResultadosException catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erro.mensagem)));
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Color _corDaNota(double nota) {
    if (nota >= 7) {
      return AppCores.sucesso;
    } else if (nota >= 5) {
      return AppCores.alerta;
    } else {
      return AppCores.erro;
    }
  }

  // Formata a data como dd/MM/aaaa. Logo depois de salvar, o Firestore
  // ainda não devolveu a data do servidor, então ela pode vir nula.
  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Sem data';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.insights,
          texto: 'Provas Corrigidas',
        ),
      ),
      body: StreamBuilder<List<Resultado>>(
        stream: _resultadosStream,
        builder: (context, snapshot) {
          // Estado de erro.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppCores.erro,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível carregar as provas corrigidas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Verifique a conexão e tente novamente.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _recarregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Estado de carregamento.
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final resultados = snapshot.data!;

          // Estado vazio.
          if (resultados.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: AppCores.textoSuave,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma prova corrigida ainda.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'As provas aparecem aqui depois de corrigidas.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Lista de resultados.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _exportando
                            ? null
                            : () => _exportarExcel(resultados),
                        icon: _exportando
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _exportando ? 'Exportando…' : 'Exportar Excel',
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      // O primeiro item é o status de cada prova.
                      itemCount: resultados.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _SecaoStatus(
                            provas: _provasFuture,
                            resultados: resultados,
                            aoAbrir: _abrirEstatisticas,
                          );
                        }

                        final resultado = resultados[index - 1];
                        final Color corDaNota = _corDaNota(resultado.nota);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EstatisticasProvaScreen(
                                    provaId: resultado.provaId,
                                  ),
                                ),
                              );
                            },
                            trailing: const Icon(Icons.bar_chart),
                            leading: CircleAvatar(
                              backgroundColor: corDaNota.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                resultado.nota.toStringAsFixed(1),
                                style: TextStyle(
                                  color: corDaNota,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              resultado.alunoNome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Matrícula: ${resultado.alunoMatricula}'),
                                Text(
                                  'Acertos: ${resultado.acertos}/${resultado.totalQuestoes}',
                                ),
                                Text(
                                  'Data: ${_formatarData(resultado.corrigidoEm)}',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Andamento da correção de cada prova: quantos alunos já foram corrigidos
/// entre os que receberam a prova, a média e a situação.
class _SecaoStatus extends StatelessWidget {
  final Future<List<ProvaComAlunos>> provas;
  final List<Resultado> resultados;
  final void Function(String provaId) aoAbrir;

  const _SecaoStatus({
    required this.provas,
    required this.resultados,
    required this.aoAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProvaComAlunos>>(
      future: provas,
      builder: (context, snapshot) {
        // O status é um complemento da lista: se não carregar, a lista de
        // resultados continua aparecendo normalmente.
        final dados = snapshot.data;
        if (dados == null) return const SizedBox.shrink();

        final status = StatusProva.calcular(
          provas: [for (final item in dados) item.prova],
          alunosComProva: {
            for (final item in dados) item.prova.id: item.alunos,
          },
          resultados: resultados,
        );
        if (status.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TituloSecao('Status das provas'),
            for (final item in status)
              _CardStatus(status: item, aoTocar: () => aoAbrir(item.provaId)),
            const SizedBox(height: 12),
            const _TituloSecao('Resultados por aluno'),
          ],
        );
      },
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final String texto;

  const _TituloSecao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: AppCores.textoSuave,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _CardStatus extends StatelessWidget {
  final StatusProva status;
  final VoidCallback aoTocar;

  const _CardStatus({required this.status, required this.aoTocar});

  ({String texto, Color cor, IconData icone}) get _situacao {
    return switch (status.situacao) {
      SituacaoCorrecao.concluida => (
          texto: 'Correção concluída',
          cor: AppCores.sucesso,
          icone: Icons.check_circle,
        ),
      SituacaoCorrecao.emAndamento => (
          texto: 'Em andamento',
          cor: AppCores.alerta,
          icone: Icons.timelapse,
        ),
      SituacaoCorrecao.naoIniciada => (
          texto: 'Não iniciada',
          cor: AppCores.textoSuave,
          icone: Icons.radio_button_unchecked,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final situacao = _situacao;
    final media = status.media;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(situacao.icone, size: 18, color: situacao.cor),
                  const SizedBox(width: 6),
                  Text(
                    situacao.texto,
                    style: TextStyle(
                      color: situacao.cor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: status.progresso,
                  minHeight: 8,
                  color: situacao.cor,
                  backgroundColor: AppCores.borda,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${status.corrigidos} de ${status.total} '
                '${status.total == 1 ? 'aluno corrigido' : 'alunos corrigidos'}'
                '${media == null ? '' : ' · Média ${media.toStringAsFixed(1)}'}',
                style: const TextStyle(color: AppCores.textoSuave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
