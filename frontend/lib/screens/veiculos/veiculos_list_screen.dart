import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_theme.dart';
import '../../core/input_formatters.dart';
import '../../core/scrollable_data_table.dart';
import '../../models/veiculo.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_data_service.dart';

class VeiculosListScreen extends StatefulWidget {
  const VeiculosListScreen({super.key});

  @override
  State<VeiculosListScreen> createState() => _VeiculosListScreenState();
}

class _VeiculosListScreenState extends State<VeiculosListScreen> {
  bool _carregando = true;
  List<Veiculo> _veiculos = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final veiculos = await context.read<ApiDataService>().listarVeiculos();
      setState(() {
        _veiculos = veiculos;
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
                                'Veículos',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Cadastro de veículos da frota',
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
                            label: const Text('Novo veículo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _veiculos.isEmpty
                            ? const Center(child: Text('Nenhum veículo cadastrado.'))
                            : ScrollableDataTable(
                                columnCount: 4,
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
                                      DataColumn(label: Text('Placa', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _veiculos.map((veiculo) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                const Icon(Icons.directions_bus, size: 20, color: AppTheme.primary),
                                                const SizedBox(width: 10),
                                                Text(veiculo.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(veiculo.placa)),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: veiculo.ativo ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: veiculo.ativo ? Colors.green.shade300 : Colors.red.shade300),
                                              ),
                                              child: Text(
                                                veiculo.ativo ? 'Ativo' : 'Inativo',
                                                style: TextStyle(
                                                  color: veiculo.ativo ? Colors.green.shade700 : Colors.red.shade700,
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
                                                  onPressed: () => _abrirFormulario(context, veiculo: veiculo),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                  tooltip: 'Excluir',
                                                  onPressed: () => _confirmarExclusao(context, veiculo),
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

  void _abrirFormulario(BuildContext context, {Veiculo? veiculo}) async {
    final result = await Navigator.of(context).push<Veiculo?>(
      MaterialPageRoute(builder: (_) => VeiculoFormScreen(veiculo: veiculo)),
    );
    if (result != null) {
      _carregar();
    }
  }

  void _confirmarExclusao(BuildContext context, Veiculo veiculo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: Text('Deseja realmente excluir "${veiculo.nome}"?'),
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
                await context.read<ApiDataService>().removerVeiculo(veiculo.id);
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

class VeiculoFormScreen extends StatefulWidget {
  final Veiculo? veiculo;

  const VeiculoFormScreen({super.key, this.veiculo});

  @override
  State<VeiculoFormScreen> createState() => _VeiculoFormScreenState();
}

class _VeiculoFormScreenState extends State<VeiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _placaController;
  bool _ativo = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.veiculo?.nome ?? '');
    _placaController = TextEditingController(text: widget.veiculo?.placa ?? '');
    _ativo = widget.veiculo?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _placaController.dispose();
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
      final veiculo = Veiculo(
        id: widget.veiculo?.id ?? 'new-${const Uuid().v4()}',
        empresaId: widget.veiculo?.empresaId ?? empresaId,
        nome: _nomeController.text.trim(),
        placa: AppInputFormatters.placaRaw(_placaController.text),
        ativo: _ativo,
      );
      final resultado = await context.read<ApiDataService>().salvarVeiculo(veiculo);
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
    final isEdicao = widget.veiculo != null && !widget.veiculo!.id.startsWith('new-');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Veículo' : 'Novo Veículo'),
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
                  const Text(
                    'Dados do Veículo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do veículo',
                      prefixIcon: Icon(Icons.directions_bus),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome do veículo.' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _placaController,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [AppInputFormatters.placa()],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a placa.';
                      }
                      if (!AppInputFormatters.placaValida(value)) {
                        return 'Placa inválida. Use o padrão antigo ou Mercosul.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Veículo ativo'),
                    subtitle: Text(
                      _ativo ? 'Veículo disponível para uso.' : 'Veículo inativo e não aparecerá em novas rotas.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    value: _ativo,
                    onChanged: (value) => setState(() => _ativo = value),
                    activeThumbColor: AppTheme.secondary,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdicao ? 'Salvar veículo' : 'Cadastrar veículo'),
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
