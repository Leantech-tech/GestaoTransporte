import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_theme.dart';
import '../../core/input_formatters.dart';
import '../../core/scrollable_data_table.dart';
import '../../models/colaborador.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_data_service.dart';

class ColaboradoresListScreen extends StatefulWidget {
  const ColaboradoresListScreen({super.key});

  @override
  State<ColaboradoresListScreen> createState() => _ColaboradoresListScreenState();
}

class _ColaboradoresListScreenState extends State<ColaboradoresListScreen> {
  bool _carregando = true;
  List<Colaborador> _colaboradores = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final colaboradores = await context.read<ApiDataService>().listarColaboradores();
      setState(() {
        _colaboradores = colaboradores;
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
    return Scaffold(
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
                                'Colaboradores',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Cadastro de motoristas, professores e monitores',
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
                            label: const Text('Novo colaborador'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _colaboradores.isEmpty
                            ? const Center(child: Text('Nenhum colaborador cadastrado.'))
                            : ScrollableDataTable(
                                columnCount: 6,
                                onRefresh: _carregar,
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                                    columns: const [
                                      DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Telefone', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('CPF', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _colaboradores.map((colaborador) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                const Icon(Icons.person, size: 20, color: AppTheme.primary),
                                                const SizedBox(width: 10),
                                                Text(colaborador.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(colaborador.tipo)),
                                          DataCell(Text(AppInputFormatters.formatTelefone(colaborador.telefone))),
                                          DataCell(Text(AppInputFormatters.formatCpf(colaborador.cpf))),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: colaborador.ativa ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: colaborador.ativa ? Colors.green.shade300 : Colors.red.shade300),
                                              ),
                                              child: Text(
                                                colaborador.ativa ? 'Ativo' : 'Inativo',
                                                style: TextStyle(
                                                  color: colaborador.ativa ? Colors.green.shade700 : Colors.red.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                                  tooltip: 'Editar',
                                                  onPressed: () => _abrirFormulario(context, colaborador: colaborador),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                  tooltip: 'Excluir',
                                                  onPressed: () => _confirmarExclusao(context, colaborador),
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
                    ],
                  ),
                ),
    );
  }

  void _abrirFormulario(BuildContext context, {Colaborador? colaborador}) async {
    final result = await Navigator.of(context).push<Colaborador?>(
      MaterialPageRoute(builder: (_) => ColaboradorFormScreen(colaborador: colaborador)),
    );
    if (result != null) {
      _carregar();
    }
  }

  void _confirmarExclusao(BuildContext context, Colaborador colaborador) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir colaborador?'),
        content: Text('Deseja realmente excluir "${colaborador.nome}"?'),
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
                await context.read<ApiDataService>().removerColaborador(colaborador.id);
                navigator.pop();
                _carregar();
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class ColaboradorFormScreen extends StatefulWidget {
  final Colaborador? colaborador;

  const ColaboradorFormScreen({super.key, this.colaborador});

  @override
  State<ColaboradorFormScreen> createState() => _ColaboradorFormScreenState();
}

class _ColaboradorFormScreenState extends State<ColaboradorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _cpfController;
  String _tipo = 'motorista';
  bool _ativa = true;
  bool _salvando = false;

  static const _tipos = ['motorista', 'professor', 'monitor'];

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'professor':
        return 'Professor(a)';
      case 'monitor':
        return 'Monitor(a)';
      default:
        return 'Motorista';
    }
  }

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.colaborador?.nome ?? '');
    _telefoneController = TextEditingController(
      text: widget.colaborador?.telefone != null ? AppInputFormatters.formatTelefone(widget.colaborador!.telefone) : '',
    );
    _cpfController = TextEditingController(
      text: widget.colaborador?.cpf != null ? AppInputFormatters.formatCpf(widget.colaborador!.cpf) : '',
    );
    _tipo = widget.colaborador?.tipo ?? 'motorista';
    _ativa = widget.colaborador?.ativa ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final empresaId = auth.usuario?.empresaId;
    if (empresaId == null || empresaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário sem empresa vinculada.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final colaborador = Colaborador(
        id: widget.colaborador?.id ?? 'new-${const Uuid().v4()}',
        empresaId: widget.colaborador?.empresaId ?? empresaId,
        nome: _nomeController.text.trim(),
        tipo: _tipo,
        telefone: AppInputFormatters.telefoneRaw(_telefoneController.text.trim()),
        cpf: AppInputFormatters.cpfRaw(_cpfController.text.trim()),
        ativa: _ativa,
      );
      final resultado = await context.read<ApiDataService>().salvarColaborador(colaborador);
      if (mounted) Navigator.of(context).pop(resultado);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.colaborador != null && !widget.colaborador!.id.startsWith('new-');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Colaborador' : 'Novo Colaborador'),
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
                  _buildForm(),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdicao ? 'Salvar colaborador' : 'Cadastrar colaborador'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados do Colaborador',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome do colaborador',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _tipo,
          decoration: const InputDecoration(
            labelText: 'Tipo de colaborador',
            prefixIcon: Icon(Icons.work_outline),
          ),
          items: _tipos
              .map((tipo) => DropdownMenuItem(value: tipo, child: Text(_labelTipo(tipo))))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _tipo = value);
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _telefoneController,
          decoration: const InputDecoration(
            labelText: 'Telefone',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [AppInputFormatters.telefone()],
          validator: (value) => value == null || value.trim().isEmpty ? 'Informe o telefone.' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _cpfController,
          decoration: const InputDecoration(
            labelText: 'CPF',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [AppInputFormatters.cpf()],
          validator: (value) => value == null || value.trim().isEmpty ? 'Informe o CPF.' : null,
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Colaborador ativo'),
          subtitle: Text(
            _ativa ? 'Pode ser selecionado em rotas e escalas.' : 'Marca como inativo e não aparece em novas associações.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          value: _ativa,
          onChanged: (value) => setState(() => _ativa = value),
          activeThumbColor: AppTheme.secondary,
        ),
      ],
    );
  }
}
