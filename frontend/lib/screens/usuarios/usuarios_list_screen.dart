import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_theme.dart';
import '../../core/section_card.dart';
import '../../models/empresa.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_data_service.dart';

class UsuariosListScreen extends StatefulWidget {
  const UsuariosListScreen({super.key});

  @override
  State<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends State<UsuariosListScreen> {
  bool _carregando = true;
  List<Usuario> _usuarios = [];
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
      final service = context.read<ApiDataService>();
      final auth = context.read<AuthProvider>();
      final usuarioLogado = auth.usuario;
      final empresas = await service.listarEmpresas();

      final usuarios = await service.listarUsuarios();
      final usuariosVisiveis = usuarioLogado?.isSuporte ?? false
          ? usuarios
          : usuarios.where((u) => u.empresaId == usuarioLogado?.empresaId).toList();

      setState(() {
        _usuarios = usuariosVisiveis;
        _empresas = empresas;
        _erro = null;
      });
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _carregando = false);
    }
  }

  String _nomeEmpresa(String? empresaId) {
    if (empresaId == null) return 'Não vinculada';
    final empresa = _empresas.where((e) => e.id == empresaId).firstOrNull;
    return empresa?.nome ?? empresaId;
  }

  @override
  Widget build(BuildContext context) {
    final usuarioLogado = context.read<AuthProvider>().usuario;
    final isSuporte = usuarioLogado?.isSuporte ?? false;
    final podeEditar = isSuporte || (usuarioLogado?.perfil == Perfil.admin);

    return Scaffold(
      floatingActionButton: podeEditar
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
                                'Usuários do Sistema',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gestão de acessos e vínculos com empresas',
                                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          if (podeEditar)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(160, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _abrirFormulario(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Novo Usuário'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _usuarios.isEmpty
                            ? const Center(child: Text('Nenhum usuário cadastrado.'))
                            : RefreshIndicator(
                                onRefresh: _carregar,
                                child: LayoutBuilder(
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
                                              columns: [
                                                const DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                                                const DataColumn(label: Text('E-mail', style: TextStyle(fontWeight: FontWeight.bold))),
                                                const DataColumn(label: Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold))),
                                                const DataColumn(label: Text('Empresa', style: TextStyle(fontWeight: FontWeight.bold))),
                                                const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                                if (podeEditar)
                                                  const DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                              ],
                                              rows: _usuarios.map((usuario) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.person, size: 20, color: AppTheme.primary),
                                                          const SizedBox(width: 10),
                                                          Text(usuario.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(Text(usuario.email)),
                                                    DataCell(Text(_labelPerfil(usuario.perfil))),
                                                    DataCell(Text(_nomeEmpresa(usuario.empresaId))),
                                                    DataCell(
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: usuario.ativo ? Colors.green.shade50 : Colors.red.shade50,
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: usuario.ativo ? Colors.green.shade300 : Colors.red.shade300),
                                                        ),
                                                        child: Text(
                                                          usuario.ativo ? 'Ativo' : 'Inativo',
                                                          style: TextStyle(
                                                            color: usuario.ativo ? Colors.green.shade700 : Colors.red.shade700,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (podeEditar)
                                                      DataCell(
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                                              tooltip: 'Editar',
                                                              onPressed: () => _abrirFormulario(context, usuario: usuario),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                                              tooltip: 'Excluir',
                                                              onPressed: () => _confirmarExclusao(context, usuario),
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
                      ),
                    ],
                  ),
                ),
    );
  }

  String _labelPerfil(Perfil perfil) {
    switch (perfil) {
      case Perfil.admin:
        return 'Administrador';
      case Perfil.operador:
        return 'Operador';
      case Perfil.suporte:
        return 'Suporte';
    }
  }

  void _abrirFormulario(BuildContext context, {Usuario? usuario}) async {
    final result = await Navigator.of(context).push<Usuario?>(
      MaterialPageRoute(
        builder: (_) => UsuarioFormScreen(
          usuario: usuario,
          empresas: _empresas,
        ),
      ),
    );
    if (result != null) _carregar();
  }

  void _confirmarExclusao(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir usuário?'),
        content: Text('Deseja realmente excluir "${usuario.nome}"?'),
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
                await context.read<ApiDataService>().removerUsuario(usuario.id);
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

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;
  final List<Empresa> empresas;

  const UsuarioFormScreen({super.key, this.usuario, required this.empresas});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _senhaController;
  Perfil _perfil = Perfil.operador;
  String? _empresaId;
  bool _ativo = true;
  bool _salvando = false;
  bool _mostrarSenha = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.usuario?.nome ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _senhaController = TextEditingController();
    _perfil = widget.usuario?.perfil ?? Perfil.operador;
    _empresaId = widget.usuario?.empresaId;
    _ativo = widget.usuario?.ativo ?? true;

    final auth = context.read<AuthProvider>();
    if (!auth.usuario!.isSuporte && _empresaId == null && auth.usuario?.empresaId != null) {
      _empresaId = auth.usuario!.empresaId;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final isSuporte = auth.usuario?.isSuporte ?? false;
    final isEdicao = widget.usuario != null && !widget.usuario!.id.startsWith('new-');

    if (!isEdicao && _senhaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma senha para o novo usuário.')),
      );
      return;
    }

    final empresaId = isSuporte ? _empresaId : auth.usuario?.empresaId;
    if (empresaId == null || empresaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma empresa para o usuário.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final usuario = Usuario(
        id: widget.usuario?.id ?? 'new-${const Uuid().v4()}',
        empresaId: empresaId,
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        perfil: _perfil,
        ativo: _ativo,
      );

      final senha = _senhaController.text.trim().isEmpty ? null : _senhaController.text.trim();
      final usuarioSalvo = await context.read<ApiDataService>().salvarUsuario(usuario, senha: senha);
      if (mounted) Navigator.of(context).pop(usuarioSalvo);
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
    final isEdicao = widget.usuario != null && !widget.usuario!.id.startsWith('new-');
    final auth = context.read<AuthProvider>();
    final isSuporte = auth.usuario?.isSuporte ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Usuário' : 'Novo Usuário'),
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
                    title: 'Dados do Usuário',
                    icon: Icons.person_outline,
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Informe o e-mail.';
                          if (!value.contains('@')) return 'E-mail inválido.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: !_mostrarSenha,
                        decoration: InputDecoration(
                          labelText: isEdicao ? 'Nova senha (deixe em branco para manter)' : 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_mostrarSenha ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                          ),
                        ),
                        validator: (value) {
                          if (!isEdicao && (value == null || value.trim().isEmpty)) {
                            return 'Informe a senha.';
                          }
                          if (value != null && value.isNotEmpty && value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Permissões e Vínculo',
                    icon: Icons.shield_outlined,
                    children: [
                      DropdownButtonFormField<Perfil>(
                        initialValue: _perfil,
                        decoration: const InputDecoration(
                          labelText: 'Perfil',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: Perfil.values
                            .where((p) => isSuporte || p != Perfil.suporte)
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(_labelPerfil(p)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _perfil = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      if (isSuporte)
                        DropdownButtonFormField<String?>(
                          initialValue: _empresaId,
                          decoration: const InputDecoration(
                            labelText: 'Empresa vinculada',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Nenhuma (suporte)'),
                            ),
                            ...widget.empresas.map((e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.nome),
                                )),
                          ],
                          onChanged: (value) => setState(() => _empresaId = value),
                        )
                      else
                        TextFormField(
                          initialValue: _empresaId != null
                              ? widget.empresas.where((e) => e.id == _empresaId).firstOrNull?.nome ?? 'Empresa do usuário logado'
                              : 'Empresa do usuário logado',
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Empresa vinculada',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
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
                        title: const Text('Usuário ativo'),
                        subtitle: Text(
                          _ativo ? 'Pode acessar o sistema normalmente.' : 'Bloqueado e impossibilitado de fazer login.',
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
                        : Text(isEdicao ? 'Salvar alterações' : 'Cadastrar usuário'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _labelPerfil(Perfil perfil) {
    switch (perfil) {
      case Perfil.admin:
        return 'Administrador';
      case Perfil.operador:
        return 'Operador';
      case Perfil.suporte:
        return 'Suporte';
    }
  }
}
