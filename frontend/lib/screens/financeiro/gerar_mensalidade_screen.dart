import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/section_card.dart';
import '../../models/aluno.dart';
import '../../services/api_data_service.dart';

class GerarMensalidadeScreen extends StatefulWidget {
  const GerarMensalidadeScreen({super.key});

  @override
  State<GerarMensalidadeScreen> createState() => _GerarMensalidadeScreenState();
}

class _GerarMensalidadeScreenState extends State<GerarMensalidadeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController(text: '1');

  List<Aluno> _alunos = [];
  String? _alunoIdSelecionado;
  bool _gerarTodos = false;
  bool _carregando = true;
  bool _gerando = false;
  String? _erro;
  int? _geradas;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  Future<void> _carregarAlunos() async {
    try {
      final alunos = await context.read<ApiDataService>().listarAlunos();
      setState(() {
        _alunos = alunos.where((a) => a.ativo).toList();
        _erro = null;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  Future<void> _gerar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_gerarTodos && _alunoIdSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um aluno.')),
      );
      return;
    }

    setState(() => _gerando = true);
    try {
      final quantidade = int.parse(_quantidadeController.text.trim());
      final geradas = await context.read<ApiDataService>().gerarMensalidades(
        alunoId: _alunoIdSelecionado,
        quantidade: quantidade,
        gerarTodos: _gerarTodos,
      );
      setState(() => _geradas = geradas);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$geradas mensalidade(s) gerada(s) com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar mensalidades: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar Mensalidade'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  if (_erro != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Erro ao carregar alunos: $_erro',
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  SectionCard(
                    title: 'Configuração da Geração',
                    icon: Icons.settings_outlined,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gerar para todos os alunos ativos'),
                        subtitle: Text(
                          _gerarTodos
                              ? 'Serão geradas mensalidades para todos os alunos ativos.'
                              : 'Será gerada mensalidade apenas para o aluno selecionado.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        value: _gerarTodos,
                        onChanged: (value) => setState(() => _gerarTodos = value),
                        activeThumbColor: AppTheme.secondary,
                      ),
                      if (!_gerarTodos) ...[
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _alunoIdSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Aluno',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: _alunos.map((Aluno aluno) {
                            return DropdownMenuItem<String>(
                              value: aluno.id,
                              child: Text(aluno.nome, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _alunoIdSelecionado = value),
                          validator: (value) {
                            if (!_gerarTodos && (value == null || value.isEmpty)) {
                              return 'Selecione um aluno.';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _quantidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade de mensalidades',
                          prefixIcon: Icon(Icons.repeat),
                          hintText: 'Ex: 3',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Informe a quantidade.';
                          final qtd = int.tryParse(value);
                          if (qtd == null || qtd < 1) return 'Quantidade inválida.';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Informações',
                    icon: Icons.info_outline,
                    children: [
                      Text(
                        'As mensalidades serão geradas a partir do mês seguinte, respeitando o dia de vencimento configurado no cadastro de cada aluno. Mensalidades já existentes para o mesmo mês/aluno serão ignoradas.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _gerando ? null : _gerar,
                    child: _gerando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Gerar mensalidades'),
                  ),
                  if (_geradas != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '$_geradas mensalidade(s) gerada(s).',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
