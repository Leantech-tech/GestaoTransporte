import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/scrollable_data_table.dart';
import '../../models/empresa.dart';
import '../../providers/auth_provider.dart';
import '../../screens/empresas/empresa_form_screen.dart';
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

    if (!isSuporte) {
      return const Scaffold(
        body: Center(child: Text('Acesso restrito a suporte.')),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
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
