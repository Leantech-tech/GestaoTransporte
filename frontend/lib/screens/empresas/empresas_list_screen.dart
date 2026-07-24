import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_theme.dart';
import '../../core/input_formatters.dart';
import '../../core/scrollable_data_table.dart';
import '../../core/section_card.dart';
import '../../models/empresa.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_data_service.dart';

class EmpresasListScreen extends StatefulWidget {
  const EmpresasListScreen({super.key});

  @override
  State<EmpresasListScreen> createState() => _EmpresasListScreenState();
}

class _EmpresasListScreenState extends State<EmpresasListScreen> {
  bool _carregando = true;
  List<Empresa> _empresas = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final empresas = await context.read<ApiDataService>().listarEmpresas();
      setState(() {
        _empresas = empresas;
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
          ? FloatingActionButton(
              onPressed: () => _abrirFormulario(context),
              child: const Icon(Icons.add),
            )
          : null,
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
                                'Empresas Cadastradas',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Transportadoras escolares e suas informações',
                                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          if (isSuporte)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(160, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _abrirFormulario(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Nova Empresa'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _empresas.isEmpty
                            ? const Center(child: Text('Nenhuma empresa cadastrada.'))
                            : ScrollableDataTable(
                                columnCount: 5,
                                onRefresh: _carregar,
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                                    columns: [
                                      const DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('CNPJ', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Telefone', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                      if (isSuporte)
                                        const DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _empresas.map((empresa) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                const Icon(Icons.business, size: 20, color: AppTheme.primary),
                                                const SizedBox(width: 10),
                                                Text(empresa.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(empresa.cnpj ?? '-')),
                                          DataCell(Text(empresa.telefone ?? '-')),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: empresa.ativa ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: empresa.ativa ? Colors.green.shade300 : Colors.red.shade300),
                                              ),
                                              child: Text(
                                                empresa.ativa ? 'Ativa' : 'Inativa',
                                                style: TextStyle(
                                                  color: empresa.ativa ? Colors.green.shade700 : Colors.red.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isSuporte)
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                                    tooltip: 'Editar',
                                                    onPressed: () => _abrirFormulario(context, empresa: empresa),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                    tooltip: 'Excluir',
                                                    onPressed: () => _confirmarExclusao(context, empresa),
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

  void _abrirFormulario(BuildContext context, {Empresa? empresa}) async {
    final result = await Navigator.of(context).push<Empresa?>(
      MaterialPageRoute(
        builder: (_) => EmpresaFormScreen(empresa: empresa),
      ),
    );
    if (result != null) _carregar();
  }

  void _confirmarExclusao(BuildContext context, Empresa empresa) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir empresa?'),
        content: Text('Deseja realmente excluir "${empresa.nome}"?'),
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
                await context.read<ApiDataService>().removerEmpresa(empresa.id);
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

class EmpresaFormScreen extends StatefulWidget {
  final Empresa? empresa;

  const EmpresaFormScreen({super.key, this.empresa});

  @override
  State<EmpresaFormScreen> createState() => _EmpresaFormScreenState();
}

class _EmpresaFormScreenState extends State<EmpresaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _enderecoController;
  bool _ativa = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.empresa?.nome ?? '');
    _cnpjController = TextEditingController(
      text: widget.empresa?.cnpj != null ? AppInputFormatters.cnpjRaw(widget.empresa!.cnpj!) : '',
    );
    _telefoneController = TextEditingController(
      text: widget.empresa?.telefone != null ? AppInputFormatters.formatTelefone(widget.empresa!.telefone!) : '',
    );
    _enderecoController = TextEditingController(text: widget.empresa?.endereco ?? '');
    _ativa = widget.empresa?.ativa ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      final empresa = Empresa(
        id: widget.empresa?.id ?? 'new-${const Uuid().v4()}',
        nome: _nomeController.text.trim(),
        cnpj: _cnpjController.text.trim().isEmpty ? null : _cnpjController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty ? null : _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim().isEmpty ? null : _enderecoController.text.trim(),
        ativa: _ativa,
      );

      final empresaSalva = await context.read<ApiDataService>().salvarEmpresa(empresa);
      if (mounted) Navigator.of(context).pop(empresaSalva);
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
    final isEdicao = widget.empresa != null && !widget.empresa!.id.startsWith('new-');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Empresa' : 'Nova Empresa'),
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
                    title: 'Dados da Empresa',
                    icon: Icons.business_outlined,
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da empresa',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _cnpjController,
                        decoration: const InputDecoration(
                          labelText: 'CNPJ',
                          prefixIcon: Icon(Icons.numbers_outlined),
                          hintText: '00.000.000/0000-00',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [AppInputFormatters.cnpj()],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '(00) 00000-0000',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [AppInputFormatters.telefone()],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _enderecoController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
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
                        title: const Text('Empresa ativa'),
                        subtitle: Text(
                          _ativa ? 'Disponível para vínculo de usuários e escolas.' : 'Inativa e oculta para novos vínculos.',
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
                        : Text(isEdicao ? 'Salvar alterações' : 'Cadastrar empresa'),
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
