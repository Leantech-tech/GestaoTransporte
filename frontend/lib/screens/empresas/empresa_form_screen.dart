import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_theme.dart';
import '../../core/input_formatters.dart';
import '../../core/section_card.dart';
import '../../models/empresa.dart';
import '../../services/api_data_service.dart';

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
