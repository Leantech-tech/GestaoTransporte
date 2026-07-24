import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/input_formatters.dart';
import '../../models/aluno.dart';
import '../../models/mensalidade.dart';
import '../../services/api_data_service.dart';

class ReceberMensalidadeScreen extends StatefulWidget {
  const ReceberMensalidadeScreen({super.key});

  @override
  State<ReceberMensalidadeScreen> createState() => _ReceberMensalidadeScreenState();
}

class _ReceberMensalidadeScreenState extends State<ReceberMensalidadeScreen> {
  bool _carregando = true;
  List<Mensalidade> _mensalidades = [];
  List<Aluno> _alunos = [];
  String? _erro;

  String _filtroAluno = '';
  DateTime? _filtroDataVencimento;

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _filtroDataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _filtroDataController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final service = context.read<ApiDataService>();
      final mensalidades = await service.listarMensalidades();
      final alunos = await service.listarAlunos();
      setState(() {
        _mensalidades = mensalidades.where((m) => m.status != 'pago').toList();
        _alunos = alunos;
        _erro = null;
      });
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _carregando = false);
    }
  }

  List<Mensalidade> get _mensalidadesFiltradas {
    return _mensalidades.where((m) {
      final matchAluno = _filtroAluno.isEmpty ||
          _nomeAluno(m).toLowerCase().contains(_filtroAluno.toLowerCase());
      final matchData = _filtroDataVencimento == null ||
          _mesmaData(m.dataVencimento, _filtroDataVencimento!);
      return matchAluno && matchData;
    }).toList();
  }

  bool _mesmaData(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _nomeAluno(Mensalidade mensalidade) {
    final aluno = _alunos.where((a) => a.id == mensalidade.alunoId).firstOrNull;
    return aluno?.nome ?? mensalidade.alunoNome ?? 'Aluno não encontrado';
  }

  Future<void> _marcarComoPago(Mensalidade mensalidade) async {
    final service = context.read<ApiDataService>();
    final atualizada = mensalidade.copyWith(
      status: 'pago',
      dataPagamento: DateTime.now(),
    );

    try {
      await service.salvarMensalidade(atualizada);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensalidade recebida com sucesso.')),
      );
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao receber mensalidade: $e')),
      );
    }
  }

  Future<void> _editarMensalidade(BuildContext context, Mensalidade mensalidade) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<ApiDataService>();
    final valorController = TextEditingController(text: AppInputFormatters.moedaText(mensalidade.valor));
    DateTime? dataVencimento = mensalidade.dataVencimento;
    final dataController = TextEditingController(text: _dateFormat.format(dataVencimento));

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar mensalidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'R\$ 0,00',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [AppInputFormatters.moeda()],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: dataController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Data de vencimento',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              onTap: () async {
                final data = await showDatePicker(
                  context: context,
                  initialDate: dataVencimento,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (data != null) {
                  dataVencimento = data;
                  dataController.text = _dateFormat.format(data);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      final valor = AppInputFormatters.moedaDouble(valorController.text);

      final atualizada = mensalidade.copyWith(
        valor: valor,
        dataVencimento: dataVencimento,
      );
      await service.salvarMensalidade(atualizada);
      messenger.showSnackBar(
        const SnackBar(content: Text('Mensalidade atualizada.')),
      );
      _carregar();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e')),
      );
    }
  }

  void _confirmarExclusao(BuildContext context, Mensalidade mensalidade) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir mensalidade?'),
        content: Text('Deseja realmente excluir a mensalidade de "${_nomeAluno(mensalidade)}"?'),
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
                await context.read<ApiDataService>().removerMensalidade(mensalidade.id);
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

  Future<void> _selecionarDataFiltro() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _filtroDataVencimento ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (data == null) return;
    setState(() {
      _filtroDataVencimento = data;
      _filtroDataController.text = _dateFormat.format(data);
    });
  }

  void _limparFiltroData() {
    setState(() {
      _filtroDataVencimento = null;
      _filtroDataController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receber Mensalidade'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mensalidades',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Filtre por aluno e/ou data de vencimento. Marque o switch para confirmar o pagamento.',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        _buildFiltros(),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildTabela(),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 320 : double.infinity),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Pesquisar aluno',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _filtroAluno.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _filtroAluno = ''),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _filtroAluno = value.trim()),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 240 : double.infinity),
                  child: TextField(
                    controller: _filtroDataController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Data de vencimento',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIcon: _filtroDataVencimento != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _limparFiltroData,
                            )
                          : null,
                    ),
                    onTap: _selecionarDataFiltro,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabela() {
    if (_mensalidadesFiltradas.isEmpty) {
      return const Center(child: Text('Nenhuma mensalidade encontrada.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                  columns: const [
                    DataColumn(label: Text('Data de vencimento', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Valor', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aluno', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Pago', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _mensalidadesFiltradas.map((mensalidade) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_dateFormat.format(mensalidade.dataVencimento))),
                        DataCell(Text(_currency.format(mensalidade.valor))),
                        DataCell(Text(_nomeAluno(mensalidade))),
                        DataCell(
                          Switch(
                            value: mensalidade.status == 'pago',
                            onChanged: (value) {
                              if (value) {
                                _marcarComoPago(mensalidade);
                              }
                            },
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                tooltip: 'Editar',
                                onPressed: () => _editarMensalidade(context, mensalidade),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                tooltip: 'Excluir',
                                onPressed: () => _confirmarExclusao(context, mensalidade),
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
        );
      },
    );
  }
}
