import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
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
  String _filtroStatus = 'todos';

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final service = context.read<ApiDataService>();
      final mensalidades = await service.listarMensalidades();
      final alunos = await service.listarAlunos();
      setState(() {
        _mensalidades = mensalidades;
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
    if (_filtroStatus == 'todos') return _mensalidades;
    return _mensalidades.where((m) => m.status == _filtroStatus).toList();
  }

  String _nomeAluno(String alunoId) {
    final aluno = _alunos.where((a) => a.id == alunoId).firstOrNull;
    return aluno?.nome ?? mensalidade.alunoNome ?? 'Aluno não encontrado';
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'pago':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'pendente':
      default:
        return Colors.orange;
    }
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'pago':
        return 'Pago';
      case 'cancelado':
        return 'Cancelado';
      case 'pendente':
      default:
        return 'Pendente';
    }
  }

  Future<void> _receber(Mensalidade mensalidade) async {
    final dataPagamento = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (dataPagamento == null) return;

    final atualizada = mensalidade.copyWith(
      status: 'pago',
      dataPagamento: dataPagamento,
    );

    try {
      await context.read<ApiDataService>().salvarMensalidade(atualizada);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensalidade recebida com sucesso.')),
        );
      }
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao receber: $e')),
        );
      }
    }
  }

  void _editar(Mensalidade mensalidade) {
    showDialog(
      context: context,
      builder: (_) => _EditarMensalidadeDialog(
        mensalidade: mensalidade,
        alunos: _alunos,
        onSalvar: (atualizada) async {
          try {
            await context.read<ApiDataService>().salvarMensalidade(atualizada);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mensalidade atualizada.')),
              );
            }
            _carregar();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao atualizar: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _excluir(Mensalidade mensalidade) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir mensalidade?'),
        content: const Text('Deseja realmente excluir esta mensalidade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await context.read<ApiDataService>().removerMensalidade(mensalidade.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensalidade excluída.')),
        );
      }
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mensalidades',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Acompanhe e receba as mensalidades geradas',
                                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'todos', label: Text('Todos')),
                                ButtonSegment(value: 'pendente', label: Text('Pendentes')),
                                ButtonSegment(value: 'pago', label: Text('Pagos')),
                                ButtonSegment(value: 'cancelado', label: Text('Cancelados')),
                              ],
                              selected: {_filtroStatus},
                              onSelectionChanged: (selected) {
                                setState(() => _filtroStatus = selected.first);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _mensalidadesFiltradas.isEmpty
                              ? const Center(child: Text('Nenhuma mensalidade encontrada.'))
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                          child: Card(
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                                            ),
                                            child: DataTable(
                                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                                              columns: const [
                                                DataColumn(label: Text('Aluno', style: TextStyle(fontWeight: FontWeight.bold))),
                                                DataColumn(label: Text('Vencimento', style: TextStyle(fontWeight: FontWeight.bold))),
                                                DataColumn(label: Text('Valor', style: TextStyle(fontWeight: FontWeight.bold))),
                                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                                DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                              ],
                                              rows: _mensalidadesFiltradas.map((mensalidade) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(Text(_nomeAluno(mensalidade.alunoId))),
                                                    DataCell(Text(_dateFormat.format(mensalidade.dataVencimento))),
                                                    DataCell(Text(_currency.format(mensalidade.valor))),
                                                    DataCell(
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _corStatus(mensalidade.status).shade50,
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: _corStatus(mensalidade.status).shade300),
                                                        ),
                                                        child: Text(
                                                          _labelStatus(mensalidade.status),
                                                          style: TextStyle(
                                                            color: _corStatus(mensalidade.status).shade700,
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
                                                          if (mensalidade.status == 'pendente')
                                                            IconButton(
                                                              icon: const Icon(Icons.payments, color: AppTheme.success),
                                                              tooltip: 'Receber',
                                                              onPressed: () => _receber(mensalidade),
                                                            ),
                                                          IconButton(
                                                            icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                                            tooltip: 'Editar',
                                                            onPressed: () => _editar(mensalidade),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                            tooltip: 'Excluir',
                                                            onPressed: () => _excluir(mensalidade),
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
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _EditarMensalidadeDialog extends StatefulWidget {
  final Mensalidade mensalidade;
  final List<Aluno> alunos;
  final ValueChanged<Mensalidade> onSalvar;

  const _EditarMensalidadeDialog({
    required this.mensalidade,
    required this.alunos,
    required this.onSalvar,
  });

  @override
  State<_EditarMensalidadeDialog> createState() => _EditarMensalidadeDialogState();
}

class _EditarMensalidadeDialogState extends State<_EditarMensalidadeDialog> {
  late final TextEditingController _valorController;
  late final TextEditingController _observacaoController;
  late String _alunoId;
  late String _status;
  late DateTime _dataVencimento;
  DateTime? _dataPagamento;

  final _statusOpcoes = ['pendente', 'pago', 'cancelado'];

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController(text: widget.mensalidade.valor.toStringAsFixed(2));
    _observacaoController = TextEditingController(text: widget.mensalidade.observacao ?? '');
    _alunoId = widget.mensalidade.alunoId;
    _status = widget.mensalidade.status;
    _dataVencimento = widget.mensalidade.dataVencimento;
    _dataPagamento = widget.mensalidade.dataPagamento;
  }

  @override
  void dispose() {
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataVencimento() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataVencimento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _dataVencimento = data);
  }

  Future<void> _selecionarDataPagamento() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataPagamento ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _dataPagamento = data);
  }

  void _salvar() {
    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido.')),
      );
      return;
    }

    final atualizada = widget.mensalidade.copyWith(
      alunoId: _alunoId,
      valor: valor,
      dataVencimento: _dataVencimento,
      dataPagamento: _status == 'pago' ? _dataPagamento : null,
      status: _status,
      observacao: _observacaoController.text.trim(),
    );

    Navigator.of(context).pop();
    widget.onSalvar(atualizada);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: const Text('Editar Mensalidade'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _alunoId,
              decoration: const InputDecoration(labelText: 'Aluno'),
              items: widget.alunos.map((Aluno aluno) {
                return DropdownMenuItem<String>(
                  value: aluno.id,
                  child: Text(aluno.nome, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) => setState(() => _alunoId = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              decoration: const InputDecoration(labelText: 'Valor'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data de vencimento'),
              subtitle: Text(dateFormat.format(_dataVencimento)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarDataVencimento,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _statusOpcoes.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status[0].toUpperCase() + status.substring(1)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            if (_status == 'pago') ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data de pagamento'),
                subtitle: Text(_dataPagamento != null ? dateFormat.format(_dataPagamento!) : 'Não informada'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selecionarDataPagamento,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacaoController,
              decoration: const InputDecoration(labelText: 'Observação'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
