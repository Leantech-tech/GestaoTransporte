import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_theme.dart';
import '../../core/scrollable_data_table.dart';
import '../../core/section_card.dart';
import '../../models/colaborador.dart';
import '../../models/linha.dart';
import '../../models/veiculo.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_data_service.dart';

class LinhasListScreen extends StatefulWidget {
  const LinhasListScreen({super.key});

  @override
  State<LinhasListScreen> createState() => _LinhasListScreenState();
}

class _LinhasListScreenState extends State<LinhasListScreen> {
  bool _carregando = true;
  List<Linha> _linhas = [];
  List<Linha> _linhasFiltradas = [];
  List<Colaborador> _colaboradores = [];
  List<Veiculo> _veiculos = [];
  String? _erro;

  final TextEditingController _filtroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final service = context.read<ApiDataService>();
      final linhas = await service.listarLinhas();
      final colaboradores = await service.listarColaboradores();
      final veiculos = await service.listarVeiculos();

      setState(() {
        _linhas = linhas;
        _colaboradores = colaboradores;
        _veiculos = veiculos;
        _erro = null;
      });
      _aplicarFiltros();
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _aplicarFiltros() {
    final filtro = _filtroController.text.toLowerCase().trim();

    setState(() {
      if (filtro.isEmpty) {
        _linhasFiltradas = List.from(_linhas);
        return;
      }
      _linhasFiltradas = _linhas.where((l) {
        final colaborador = _colaboradores.where((c) => c.id == l.colaboradorId).firstOrNull;
        final veiculo = _veiculos.where((v) => v.id == l.veiculoId).firstOrNull;
        return l.nome.toLowerCase().contains(filtro) ||
            (colaborador?.nome ?? '').toLowerCase().contains(filtro) ||
            (veiculo?.nome ?? '').toLowerCase().contains(filtro) ||
            (veiculo?.placa ?? '').toLowerCase().contains(filtro);
      }).toList();
    });
  }

  String _nomeColaborador(String id) {
    return _colaboradores.where((c) => c.id == id).firstOrNull?.nome ?? id;
  }

  String _nomeVeiculo(String id) {
    return _veiculos.where((v) => v.id == id).firstOrNull?.nome ?? id;
  }

  String _placaVeiculo(String id) {
    return _veiculos.where((v) => v.id == id).firstOrNull?.placa ?? '-';
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
                                'Linhas',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Rotas vinculadas a colaboradores e veículos',
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
                            label: const Text('Nova linha'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _filtroController,
                        decoration: InputDecoration(
                          labelText: 'Pesquisar por linha, colaborador ou veículo',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                        onChanged: (_) => _aplicarFiltros(),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _linhasFiltradas.isEmpty
                            ? const Center(child: Text('Nenhuma linha cadastrada.'))
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
                                      DataColumn(label: Text('Colaborador', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Veículo', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Placa', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Origem → Destino', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _linhasFiltradas.map((linha) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                const Icon(Icons.route, size: 20, color: AppTheme.primary),
                                                const SizedBox(width: 10),
                                                Text(linha.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(_nomeColaborador(linha.colaboradorId))),
                                          DataCell(Text(_nomeVeiculo(linha.veiculoId))),
                                          DataCell(Text(_placaVeiculo(linha.veiculoId))),
                                          DataCell(Text('${linha.origem} → ${linha.destino}')),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                                  tooltip: 'Editar',
                                                  onPressed: () => _abrirFormulario(context, linha: linha),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                  tooltip: 'Excluir',
                                                  onPressed: () => _confirmarExclusao(context, linha),
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

  void _abrirFormulario(BuildContext context, {Linha? linha}) async {
    final result = await Navigator.of(context).push<Linha?>(
      MaterialPageRoute(
        builder: (_) => LinhaFormScreen(
          linha: linha,
          colaboradores: _colaboradores,
          veiculos: _veiculos,
        ),
      ),
    );
    if (result != null) {
      _carregar();
    }
  }

  void _confirmarExclusao(BuildContext context, Linha linha) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir linha?'),
        content: Text('Deseja realmente excluir "${linha.nome}"?'),
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
                await context.read<ApiDataService>().removerLinha(linha.id);
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

class LinhaFormScreen extends StatefulWidget {
  final Linha? linha;
  final List<Colaborador> colaboradores;
  final List<Veiculo> veiculos;

  const LinhaFormScreen({
    super.key,
    this.linha,
    required this.colaboradores,
    required this.veiculos,
  });

  @override
  State<LinhaFormScreen> createState() => _LinhaFormScreenState();
}

class _LinhaFormScreenState extends State<LinhaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _origemController;
  late final TextEditingController _destinoController;
  String? _colaboradorId;
  String? _veiculoId;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.linha?.nome ?? '');
    _origemController = TextEditingController(text: widget.linha?.origem ?? '');
    _destinoController = TextEditingController(text: widget.linha?.destino ?? '');
    _colaboradorId = widget.linha?.colaboradorId;
    _veiculoId = widget.linha?.veiculoId;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _origemController.dispose();
    _destinoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_colaboradorId == null || _colaboradorId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um colaborador.')),
      );
      return;
    }
    if (_veiculoId == null || _veiculoId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um veículo.')),
      );
      return;
    }

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
      final linha = Linha(
        id: widget.linha?.id ?? 'new-${const Uuid().v4()}',
        empresaId: widget.linha?.empresaId ?? empresaId,
        colaboradorId: _colaboradorId!,
        veiculoId: _veiculoId!,
        nome: _nomeController.text.trim(),
        origem: _origemController.text.trim(),
        destino: _destinoController.text.trim(),
      );
      final resultado = await context.read<ApiDataService>().salvarLinha(linha);
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
    final isEdicao = widget.linha != null && !widget.linha!.id.startsWith('new-');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Linha' : 'Nova Linha'),
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
                    title: 'Dados da Linha',
                    icon: Icons.route_outlined,
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da linha',
                          prefixIcon: Icon(Icons.route),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o nome da linha.' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _origemController,
                        decoration: const InputDecoration(
                          labelText: 'Origem',
                          prefixIcon: Icon(Icons.trip_origin),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe a origem.' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _destinoController,
                        decoration: const InputDecoration(
                          labelText: 'Destino',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o destino.' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Vínculos',
                    icon: Icons.link_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _colaboradorId,
                        decoration: const InputDecoration(
                          labelText: 'Colaborador',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: widget.colaboradores
                            .where((c) => c.ativa)
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.nome),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _colaboradorId = value),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Selecione um colaborador.' : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: _veiculoId,
                        decoration: const InputDecoration(
                          labelText: 'Veículo',
                          prefixIcon: Icon(Icons.directions_bus_outlined),
                        ),
                        items: widget.veiculos
                            .where((v) => v.ativo)
                            .map((v) => DropdownMenuItem(
                                  value: v.id,
                                  child: Text('${v.nome} (${v.placa})'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _veiculoId = value),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Selecione um veículo.' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdicao ? 'Salvar linha' : 'Cadastrar linha'),
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
