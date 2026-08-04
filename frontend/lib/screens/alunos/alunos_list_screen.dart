import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_theme.dart';
import '../../core/input_formatters.dart';
import '../../core/scrollable_data_table.dart';
import '../../core/section_card.dart';
import '../../models/aluno.dart';
import '../../models/escola.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_data_service.dart';
import '../escolas/escolas_list_screen.dart' show EscolaFormScreen;

class AlunosListScreen extends StatefulWidget {
  const AlunosListScreen({super.key});

  @override
  State<AlunosListScreen> createState() => _AlunosListScreenState();
}

class _AlunosListScreenState extends State<AlunosListScreen> {
  bool _carregando = true;
  List<Aluno> _alunos = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final alunos = await context.read<ApiDataService>().listarAlunos();
      setState(() {
        _alunos = alunos;
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
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
                                'Alunos Cadastrados',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gerenciamento de dados dos estudantes, mensalidades e responsáveis',
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
                            label: const Text('Novo Aluno'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _alunos.isEmpty
                            ? const Center(child: Text('Nenhum aluno cadastrado.'))
                            : ScrollableDataTable(
                                columnCount: isSuporte ? 9 : 10,
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
                                      const DataColumn(label: Text('Nome do Aluno', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Endereço', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Contrato', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Mensalidade', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Valor', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Vencimento', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Responsável Financeiro', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Telefone Responsável', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                      if (!isSuporte)
                                        const DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _alunos.map((aluno) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                const Icon(Icons.person, size: 20, color: AppTheme.primary),
                                                const SizedBox(width: 10),
                                                Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(aluno.endereco)),
                                          DataCell(Text(aluno.dataInicioContrato != null && aluno.dataFimContrato != null
                                              ? '${DateFormat('dd/MM/yyyy').format(aluno.dataInicioContrato!)} - ${DateFormat('dd/MM/yyyy').format(aluno.dataFimContrato!)}'
                                              : '-')),
                                          DataCell(Text(currency.format(aluno.mensalidade))),
                                          DataCell(Text(currency.format(aluno.valor))),
                                          DataCell(Text('Dia ${aluno.diaVencimento}')),
                                          DataCell(Text(aluno.responsavelNome)),
                                          DataCell(Text(aluno.responsavelTelefone)),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: aluno.ativo ? Colors.green.shade50 : Colors.orange.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: aluno.ativo ? Colors.green.shade300 : Colors.orange.shade300),
                                              ),
                                              child: Text(
                                                aluno.ativo ? 'Ativo' : 'Inativo / Pendente',
                                                style: TextStyle(
                                                  color: aluno.ativo ? Colors.green.shade700 : Colors.orange.shade800,
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
                                                    onPressed: () => _abrirFormulario(context, aluno: aluno),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                    tooltip: 'Excluir',
                                                    onPressed: () => _confirmarExclusao(context, aluno),
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

  void _abrirFormulario(BuildContext context, {Aluno? aluno}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlunoFormScreen(aluno: aluno),
      ),
    );
    if (result == true) _carregar();
  }

  void _confirmarExclusao(BuildContext context, Aluno aluno) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir aluno?'),
        content: Text('Deseja realmente excluir "${aluno.nome}"?'),
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
                await context.read<ApiDataService>().removerAluno(aluno.id);
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

class AlunoFormScreen extends StatefulWidget {
  final Aluno? aluno;

  const AlunoFormScreen({super.key, this.aluno});

  @override
  State<AlunoFormScreen> createState() => _AlunoFormScreenState();
}

class _AlunoFormScreenState extends State<AlunoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _mensalidadeController;
  late final TextEditingController _valorController;
  late final TextEditingController _diaVencimentoController;
  late final TextEditingController _responsavelController;
  late final TextEditingController _responsavelTelefoneController;
  late final TextEditingController _contratoDataInicialController;
  late final TextEditingController _contratoDataFinalController;
  String? _escolaIdSelecionada;
  bool _ativo = true;
  bool _salvando = false;
  bool _carregandoEscolas = true;
  List<Escola> _escolas = [];
  String? _erroEscolas;

  @override
  void initState() {
    super.initState();
    final aluno = widget.aluno;
    _nomeController = TextEditingController(text: aluno?.nome ?? '');
    _enderecoController = TextEditingController(text: aluno?.endereco ?? '');
    _mensalidadeController = TextEditingController(
      text: aluno != null ? AppInputFormatters.moedaText(aluno.mensalidade) : '',
    );
    _valorController = TextEditingController(
      text: aluno != null ? AppInputFormatters.moedaText(aluno.valor) : '',
    );
    _diaVencimentoController = TextEditingController(
      text: aluno?.diaVencimento.toString() ?? '',
    );
    _responsavelController = TextEditingController(text: aluno?.responsavelNome ?? '');
    _responsavelTelefoneController = TextEditingController(
      text: aluno != null ? AppInputFormatters.formatTelefone(aluno.responsavelTelefone) : '',
    );
    _contratoDataInicialController = TextEditingController(
      text: aluno?.dataInicioContrato != null ? DateFormat('dd/MM/yyyy').format(aluno!.dataInicioContrato!) : '',
    );
    _contratoDataFinalController = TextEditingController(
      text: aluno?.dataFimContrato != null ? DateFormat('dd/MM/yyyy').format(aluno!.dataFimContrato!) : '',
    );
    _escolaIdSelecionada = aluno?.escolaId;
    _ativo = aluno?.ativo ?? true;
    _carregarEscolas();
  }

  Future<void> _carregarEscolas() async {
    try {
      final escolas = await context.read<ApiDataService>().listarEscolas();
      setState(() {
        _escolas = escolas.where((e) => e.ativa).toList();
        _carregandoEscolas = false;
      });
    } catch (e) {
      setState(() {
        _erroEscolas = e.toString();
        _carregandoEscolas = false;
      });
    }
  }

  Future<void> _abrirFormularioEscola() async {
    final escola = await Navigator.of(context).push<Escola?>(
      MaterialPageRoute(
        builder: (_) => const EscolaFormScreen(),
      ),
    );
    if (escola != null) {
      await _carregarEscolas();
      setState(() => _escolaIdSelecionada = escola.id);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _mensalidadeController.dispose();
    _valorController.dispose();
    _diaVencimentoController.dispose();
    _responsavelController.dispose();
    _responsavelTelefoneController.dispose();
    _contratoDataInicialController.dispose();
    _contratoDataFinalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final initialDate = controller.text.isNotEmpty
        ? DateFormat('dd/MM/yyyy').parseStrict(controller.text)
        : DateTime.now();
    final firstDate = DateTime(DateTime.now().year - 5);
    final lastDate = DateTime(DateTime.now().year + 5);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione a data',
      confirmText: 'OK',
      cancelText: 'Cancelar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.secondary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
            dialogBackgroundColor: AppTheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(selected);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    if (_escolaIdSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma escola.')),
      );
      return;
    }

    final escolaSelecionada = _escolas.where((e) => e.id == _escolaIdSelecionada).firstOrNull;
    final empresaId = widget.aluno?.empresaId ??
        auth.usuario?.empresaId ??
        escolaSelecionada?.empresaId;

    if (empresaId == null || empresaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível identificar a empresa vinculada.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      DateTime? dataInicioContrato;
      DateTime? dataFimContrato;
      if (_contratoDataInicialController.text.isNotEmpty || _contratoDataFinalController.text.isNotEmpty) {
        if (_contratoDataInicialController.text.isEmpty || _contratoDataFinalController.text.isEmpty) {
          throw 'Informe data inicial e data final do contrato.';
        }
        dataInicioContrato = DateFormat('dd/MM/yyyy').parseStrict(_contratoDataInicialController.text.trim());
        dataFimContrato = DateFormat('dd/MM/yyyy').parseStrict(_contratoDataFinalController.text.trim());
        if (dataFimContrato.isBefore(dataInicioContrato)) {
          throw 'Data final deve ser igual ou posterior à data inicial.';
        }
      }
      final aluno = Aluno(
        id: widget.aluno?.id ?? 'new-${const Uuid().v4()}',
        empresaId: empresaId,
        escolaId: _escolaIdSelecionada!,
        nome: _nomeController.text.trim(),
        endereco: _enderecoController.text.trim(),
        mensalidade: AppInputFormatters.moedaDouble(_mensalidadeController.text),
        valor: AppInputFormatters.moedaDouble(_valorController.text),
        diaVencimento: int.parse(_diaVencimentoController.text.trim()),
        responsavelNome: _responsavelController.text.trim(),
        responsavelTelefone: _responsavelTelefoneController.text.trim(),
        dataInicioContrato: dataInicioContrato,
        dataFimContrato: dataFimContrato,
        ativo: _ativo,
      );

      await context.read<ApiDataService>().salvarAluno(aluno);
      if (mounted) Navigator.of(context).pop(true);
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
    final isEdicao = widget.aluno != null && !widget.aluno!.id.startsWith('new-');

    if (_carregandoEscolas) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Aluno' : 'Novo Aluno'),
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
                    title: 'Dados do Aluno',
                    icon: Icons.person_outline,
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do aluno',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _enderecoController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço do aluno',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o endereço.' : null,
                      ),
                      const SizedBox(height: 20),
                      if (_erroEscolas != null)
                        Text('Erro ao carregar escolas: $_erroEscolas', style: const TextStyle(color: AppTheme.error))
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _escolaIdSelecionada,
                                decoration: const InputDecoration(
                                  labelText: 'Escola',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                items: _escolas.map((Escola escola) {
                                  return DropdownMenuItem<String>(
                                    value: escola.id,
                                    child: Text(escola.nome, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _escolaIdSelecionada = value),
                                validator: (value) => value == null ? 'Selecione uma escola.' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Tooltip(
                              message: 'Cadastrar nova escola',
                              child: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _abrirFormularioEscola,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Mensalidade',
                    icon: Icons.payments_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mensalidadeController,
                              decoration: const InputDecoration(
                                labelText: 'Mensalidade',
                                prefixIcon: Icon(Icons.attach_money),
                                hintText: 'R\$ 0,00',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [AppInputFormatters.moeda()],
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Informe.' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _valorController,
                              decoration: const InputDecoration(
                                labelText: 'Valor',
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                                hintText: 'R\$ 0,00',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [AppInputFormatters.moeda()],
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Informe.' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _diaVencimentoController,
                        decoration: const InputDecoration(
                          labelText: 'Dia de vencimento (1-31)',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Informe o dia.';
                          final dia = int.tryParse(value);
                          if (dia == null || dia < 1 || dia > 31) return 'Dia inválido.';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Responsável Financeiro',
                    icon: Icons.people_alt_outlined,
                    children: [
                      TextFormField(
                        controller: _responsavelController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do responsável',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _responsavelTelefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone do responsável',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '(00) 00000-0000',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [AppInputFormatters.telefone()],
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o telefone.' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Contrato',
                    icon: Icons.description_outlined,
                    children: [
                      TextFormField(
                        controller: _contratoDataInicialController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Data inicial',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        onTap: () => _selectDate(context, _contratoDataInicialController),
                        validator: (value) {
                          if (_contratoDataFinalController.text.isNotEmpty &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Informe a data inicial.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _contratoDataFinalController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Data final',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        onTap: () => _selectDate(context, _contratoDataFinalController),
                        validator: (value) {
                          if (_contratoDataInicialController.text.isNotEmpty &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Informe a data final.';
                          }
                          return null;
                        },
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
                        title: const Text('Aluno ativo'),
                        subtitle: Text(
                          _ativo ? 'Incluído no faturamento e visível nas listagens.' : 'Inativo / pendente de pagamento.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        value: _ativo,
                        onChanged: (value) => setState(() => _ativo = value),
                        activeThumbColor: AppTheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdicao ? 'Salvar alterações' : 'Cadastrar aluno'),
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
