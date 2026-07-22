import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_theme.dart';
import '../../core/section_card.dart';
import '../../models/escola.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_data_service.dart';

class EscolasListScreen extends StatefulWidget {
  const EscolasListScreen({super.key});

  @override
  State<EscolasListScreen> createState() => _EscolasListScreenState();
}

class _EscolasListScreenState extends State<EscolasListScreen> {
  bool _carregando = true;
  List<Escola> _escolas = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final escolas = await context.read<ApiDataService>().listarEscolas();
      setState(() {
        _escolas = escolas;
        _erro = null;
      });
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AuthProvider>().usuario;
    final isSuporte = usuario?.isSuporte ?? false;

    return Scaffold(
      floatingActionButton: isSuporte
          ? null
          : FloatingActionButton(
              onPressed: () => _abrirFormulario(context),
              child: const Icon(Icons.add),
            ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Escolas Cadastradas',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Listagem e gerenciamento de instituições de ensino',
                                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(160, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _abrirFormulario(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Nova Escola'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _escolas.isEmpty
                            ? const Center(child: Text('Nenhuma escola cadastrada.'))
                            : RefreshIndicator(
                                onRefresh: _carregar,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                                      ),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                                        columns: [
                                          const DataColumn(label: Text('Nome da Escola', style: TextStyle(fontWeight: FontWeight.bold))),
                                          const DataColumn(label: Text('Endereço Completo', style: TextStyle(fontWeight: FontWeight.bold))),
                                          const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                          if (!isSuporte)
                                            const DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                        rows: _escolas.map((escola) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  children: [
                                                    const Icon(Icons.school, size: 20, color: AppTheme.primary),
                                                    const SizedBox(width: 10),
                                                    Text(escola.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text(escola.enderecoCompleto)),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: escola.ativa ? Colors.green.shade50 : Colors.red.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: escola.ativa ? Colors.green.shade300 : Colors.red.shade300),
                                                  ),
                                                  child: Text(
                                                    escola.ativa ? 'Ativa' : 'Inativa',
                                                    style: TextStyle(
                                                      color: escola.ativa ? Colors.green.shade700 : Colors.red.shade700,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (!isSuporte)
                                                DataCell(
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                                        tooltip: 'Editar',
                                                        onPressed: () => _abrirFormulario(context, escola: escola),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                        tooltip: 'Excluir',
                                                        onPressed: () => _confirmarExclusao(context, escola),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _abrirFormulario(BuildContext context, {Escola? escola}) async {
    final result = await Navigator.of(context).push<Escola?>(
      MaterialPageRoute(
        builder: (_) => EscolaFormScreen(escola: escola),
      ),
    );
    if (result != null) _carregar();
  }

  void _confirmarExclusao(BuildContext context, Escola escola) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir escola?'),
        content: Text('Deseja realmente excluir "${escola.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await context.read<ApiDataService>().removerEscola(escola.id);
                navigator.pop();
                _carregar();
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Erro ao excluir: $e')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class EscolaFormScreen extends StatefulWidget {
  final Escola? escola;

  const EscolaFormScreen({super.key, this.escola});

  @override
  State<EscolaFormScreen> createState() => _EscolaFormScreenState();
}

class _EscolaFormScreenState extends State<EscolaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _enderecoController;
  bool _ativa = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.escola?.nome ?? '');
    _enderecoController = TextEditingController(text: widget.escola?.enderecoCompleto ?? '');
    _ativa = widget.escola?.ativa ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final empresaId = widget.escola?.empresaId ?? auth.usuario?.empresaId;

    if (empresaId == null || empresaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário sem empresa vinculada.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final escola = Escola(
        id: widget.escola?.id ?? 'new-${const Uuid().v4()}',
        empresaId: empresaId,
        nome: _nomeController.text.trim(),
        enderecoCompleto: _enderecoController.text.trim(),
        ativa: _ativa,
      );

      final escolaSalva = await context.read<ApiDataService>().salvarEscola(escola);
      if (mounted) Navigator.of(context).pop(escolaSalva);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.escola != null && !widget.escola!.id.startsWith('new-');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Escola' : 'Nova Escola'),
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
                  SectionCard(
                    title: 'Dados da Escola',
                    icon: Icons.school_outlined,
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da escola',
                          prefixIcon: Icon(Icons.school),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _enderecoController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço completo',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o endereço.' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Status',
                    icon: Icons.toggle_on_outlined,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Escola ativa'),
                        subtitle: Text(
                          _ativa ? 'Visível na listagem e disponível para novos alunos.' : 'Inativa e oculta nas novas associações.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        value: _ativa,
                        onChanged: (value) => setState(() => _ativa = value),
                        activeThumbColor: AppTheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdicao ? 'Salvar alterações' : 'Cadastrar escola'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
