import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../services/api_data_service.dart';
import '../models/aluno.dart';
import '../models/escola.dart';
import '../models/usuario.dart';
import '../models/mensalidade.dart';
import '../providers/auth_provider.dart';
import 'alunos/alunos_list_screen.dart';
import 'escolas/escolas_list_screen.dart';
import 'financeiro/financeiro_hub_screen.dart';
import 'financeiro/gerar_mensalidade_screen.dart';
import 'financeiro/receber_mensalidade_screen.dart';
import 'colaboradores/colaboradores_list_screen.dart';
import 'empresas/empresas_list_screen.dart';
import 'usuarios/usuarios_list_screen.dart';
import 'veiculos/veiculos_list_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _carregando = true;
  List<Aluno> _alunos = [];
  List<Escola> _escolas = [];
  List<Mensalidade> _mensalidades = [];
  ApiDataService? _dataServiceListener;
  String? _erro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<AuthProvider>().dataService;
      service.addListener(_carregarDados);
      _dataServiceListener = service;
      _carregarDados();
    });
  }

  @override
  void dispose() {
    if (_dataServiceListener != null) {
      _dataServiceListener!.removeListener(_carregarDados);
    }
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final escolas = await auth.dataService.listarEscolas();
      final alunos = await auth.dataService.listarAlunos();
      // Carregar mensalidades para calcular faturamento real
      final mensalidades = await auth.dataService.listarMensalidades();

      setState(() {
        _escolas = escolas;
        _alunos = alunos;
        _mensalidades = mensalidades;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar dados do dashboard';
        _carregando = false;
      });
    }
  }

  void _logout() {
    final auth = context.read<AuthProvider>();
    auth.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _abrirFormularioEscola(BuildContext context) async {
    final result = await Navigator.of(context).push<Escola?>(
      MaterialPageRoute(builder: (_) => const EscolaFormScreen()),
    );
    if (result != null) _carregarDados();
  }

  Future<void> _abrirFormularioAluno(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlunoFormScreen()),
    );
    if (result == true) _carregarDados();
  }

  Future<void> _abrirFormularioColaborador(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ColaboradorFormScreen()),
    );
    if (result != null) _carregarDados();
  }

  // Índices de navegação:
  // 0 = Dashboard
  // 1 = Escolas
  // 2 = Alunos
  // 3 = Financeiro Hub (mobile)
  // 4 = Gerar Mensalidade
  // 5 = Receber Mensalidade
  // 6 = Admin Hub (mobile)
  // 7 = Empresas
  // 8 = Usuários
  // 9 = Colaboradores
  // 10 = Veículos

  String get _tituloAppBar {
    switch (_selectedIndex) {
      case 0:
        return 'Visão Geral';
      case 1:
        return 'Gestão de Escolas';
      case 2:
        return 'Gestão de Alunos';
      case 3:
      case 6:
        return 'Administração';
      case 4:
        return 'Gerar Mensalidade';
      case 5:
        return 'Receber Mensalidade';
      case 7:
        return 'Gestão de Empresas';
      case 8:
        return 'Gestão de Usuários';
      case 9:
        return 'Gestão de Colaboradores';
      case 10:
        return 'Gestão de Veículos';
      default:
        return '';
    }
  }

  VoidCallback? get _acaoAdicionar {
    if (_selectedIndex == 1) {
      return () => _abrirFormularioEscola(context);
    }
    if (_selectedIndex == 2) {
      return () => _abrirFormularioAluno(context);
    }
    if (_selectedIndex == 9) {
      return () => _abrirFormularioColaborador(context);
    }
    return null;
  }

  int get _bottomNavIndex {
    if (_selectedIndex <= 3) return _selectedIndex;
    if (_selectedIndex == 4 || _selectedIndex == 5) return 3;
    if (_selectedIndex == 6 || _selectedIndex == 7 || _selectedIndex == 8 || _selectedIndex == 9 || _selectedIndex == 10) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    final List<Widget> paginas = [
      _buildDashboardView(),
      const EscolasListScreen(),
      const AlunosListScreen(),
      FinanceiroHubScreen(
        onGerarMensalidade: () => setState(() => _selectedIndex = 4),
        onReceberMensalidade: () => setState(() => _selectedIndex = 5),
      ),
      const GerarMensalidadeScreen(),
      const ReceberMensalidadeScreen(),
      _AdminHubScreen(
        onEmpresas: () => setState(() => _selectedIndex = 7),
        onUsuarios: () => setState(() => _selectedIndex = 8),
        onColaboradores: () => setState(() => _selectedIndex = 9),
      ),
      const EmpresasListScreen(),
      const UsuariosListScreen(),
      const ColaboradoresListScreen(),
      const VeiculosListScreen(),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _CustomSidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              onLogout: _logout,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopNavbar(
                    title: _tituloAppBar,
                    onLogout: _logout,
                    onRefresh: _carregarDados,
                    onAdd: _acaoAdicionar,
                  ),
                  Expanded(child: paginas[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: paginas[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _bottomNavIndex,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
          onDestinationSelected: (int index) {
            if (index == 3) {
              setState(() => _selectedIndex = 3);
            } else if (index == 4) {
              setState(() => _selectedIndex = 6);
            } else {
              setState(() => _selectedIndex = index);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded, color: AppTheme.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.domain_outlined),
              selectedIcon: Icon(Icons.domain_rounded, color: AppTheme.primary),
              label: 'Escolas',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded, color: AppTheme.primary),
              label: 'Alunos',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary),
              label: 'Financeiro',
            ),
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primary),
              label: 'Admin',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    final totalEscolas = _escolas.length;
    final totalAlunos = _alunos.length;
    final alunosInadimplentes = _alunos.where((a) => !a.ativo).length;
    final alunosAdimplentes = totalAlunos - alunosInadimplentes;
    // Somar todas as mensalidades lançadas, independentemente do status `ativo`.
    // Somar apenas mensalidades marcadas como pagas
    final faturamentoTotal = _mensalidades
      .where((m) => m.status.toLowerCase() == 'pago')
      .fold<double>(0, (sum, m) => sum + m.valor);

    // Mapeamento alunos por escola para o gráfico
    final Map<String, int> alunosPorEscola = {};
    for (var escola in _escolas) {
      final qtd = _alunos.where((a) => a.escolaId == escola.id).length;
      alunosPorEscola[escola.nome] = qtd;
    }

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Boas-Vindas Moderno
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C75), Color(0xFF1B263B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F4C75).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.space_dashboard_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-vindo de volta, ${usuario?.nome ?? 'Usuário'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          usuario?.isSuporte ?? false
                              ? 'Acesso de Suporte Técnico — Painel Consolidado'
                              : 'Acompanhe as métricas de transporte escolar em tempo real',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_carregando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_erro != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                      const SizedBox(height: 12),
                      Text(_erro!, style: const TextStyle(color: AppTheme.error, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _carregarDados,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Grid de Cards Indicadores Sofisticados
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1100 ? 4 : (width > 650 ? 2 : 1);

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: width > 1100 ? 2.4 : 2.8,
                    children: [
                      _MetricCard(
                        title: 'Total de Alunos',
                        value: '$totalAlunos',
                        badgeText: '$alunosAdimplentes ativos',
                        icon: Icons.groups_rounded,
                        gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      _MetricCard(
                        title: 'Escolas Atendidas',
                        value: '$totalEscolas',
                        badgeText: 'Instituições',
                        icon: Icons.domain_rounded,
                        gradientColors: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      ),
                      _MetricCard(
                        title: 'Mensalidades Pendentes',
                        value: '$alunosInadimplentes',
                        badgeText: 'Alunos inativos/pend.',
                        icon: Icons.pending_actions_rounded,
                        gradientColors: const [Color(0xFFEA580C), Color(0xFFC2410C)],
                        isWarning: true,
                      ),
                      _MetricCard(
                        title: 'Faturamento Mensal',
                        value: 'R\$ ${faturamentoTotal.toStringAsFixed(2)}',
                        badgeText: 'Mensalidades ativas',
                        icon: Icons.account_balance_wallet_rounded,
                        gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Seção de Gráficos do Dashboard
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 900;
                  return isWideScreen
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _ChartCard(
                                title: 'Status de Pagamento dos Alunos',
                                subtitle: 'Proporção entre adimplentes e pendentes',
                                child: SizedBox(
                                  height: 240,
                                  child: _DonutChart(
                                    active: alunosAdimplentes,
                                    inactive: alunosInadimplentes,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: _ChartCard(
                                title: 'Distribuição de Alunos por Escola',
                                subtitle: 'Quantidade de estudantes matriculados em cada escola',
                                child: SizedBox(
                                  height: 240,
                                  child: _BarChart(data: alunosPorEscola),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _ChartCard(
                              title: 'Status de Pagamento dos Alunos',
                              subtitle: 'Proporção entre adimplentes e pendentes',
                              child: SizedBox(
                                height: 220,
                                child: _DonutChart(
                                  active: alunosAdimplentes,
                                  inactive: alunosInadimplentes,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _ChartCard(
                              title: 'Distribuição de Alunos por Escola',
                              subtitle: 'Quantidade de estudantes matriculados em cada escola',
                              child: SizedBox(
                                height: 220,
                                child: _BarChart(data: alunosPorEscola),
                              ),
                            ),
                          ],
                        );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ADMIN HUB (mobile)
// ==========================================

class _AdminHubScreen extends StatelessWidget {
  final VoidCallback onEmpresas;
  final VoidCallback onColaboradores;
  final VoidCallback onUsuarios;

  const _AdminHubScreen({
    required this.onEmpresas,
    required this.onColaboradores,
    required this.onUsuarios,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSuporte = auth.usuario?.isSuporte ?? false;
    final isAdmin = auth.usuario?.perfil == Perfil.admin;

    if (!isSuporte && !isAdmin) {
      return const Center(child: Text('Acesso restrito a administradores.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Administração',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gerencie empresas e usuários do sistema',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                if (isSuporte) ...[
                  ListTile(
                    leading: const Icon(Icons.business, color: AppTheme.primary),
                    title: const Text('Empresas', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Transportadoras escolares cadastradas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onEmpresas,
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.people, color: AppTheme.primary),
                  title: const Text('Usuários', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Acessos e vínculos com empresas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onUsuarios,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENTES DE NAVEGAÇÃO E SIDEBAR ELEGANTE
// ==========================================

class _CustomSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;

  const _CustomSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final financeiroSelecionado = selectedIndex == 4 || selectedIndex == 5;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          // Logo & Marca
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_bus_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final auth = context.watch<AuthProvider>();
                      final empresaNome = auth.usuario?.isSuporte ?? false
                          ? 'Suporte'
                          : (auth.empresa?.nome ?? 'Gestão de Transporte');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            empresaNome,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Gestão de Transporte',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Itens de Menu
          _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),
          _SidebarItem(
            icon: Icons.domain_rounded,
            label: 'Escolas',
            isSelected: selectedIndex == 1,
            onTap: () => onDestinationSelected(1),
          ),
          _SidebarItem(
            icon: Icons.groups_rounded,
            label: 'Alunos',
            isSelected: selectedIndex == 2,
            onTap: () => onDestinationSelected(2),
          ),
          Builder(
            builder: (context) {
              final auth = context.watch<AuthProvider>();
              final isSuporte = auth.usuario?.isSuporte ?? false;
              final isAdmin = auth.usuario?.perfil == Perfil.admin;
              if (!isSuporte && !isAdmin) return const SizedBox.shrink();

              return Column(
                children: [
                  _SidebarItem(
                    icon: Icons.person_outline,
                    label: 'Colaboradores',
                    isSelected: selectedIndex == 9,
                    onTap: () => onDestinationSelected(9),
                  ),
                  _SidebarItem(
                    icon: Icons.directions_car_rounded,
                    label: 'Veículos',
                    isSelected: selectedIndex == 10,
                    onTap: () => onDestinationSelected(10),
                  ),
                ],
              );
            },
          ),
          _ExpandableSidebarItem(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Financeiro',
            isExpanded: financeiroSelecionado,
            isSelected: financeiroSelecionado,
            onTap: () => onDestinationSelected(4),
            children: [
              _SidebarSubItem(
                label: 'Gerar mensalidade',
                isSelected: selectedIndex == 4,
                onTap: () => onDestinationSelected(4),
              ),
              _SidebarSubItem(
                label: 'Receber mensalidade',
                isSelected: selectedIndex == 5,
                onTap: () => onDestinationSelected(5),
              ),
            ],
          ),
          Builder(
            builder: (context) {
              final auth = context.watch<AuthProvider>();
              final isSuporte = auth.usuario?.isSuporte ?? false;
              final isAdmin = auth.usuario?.perfil == Perfil.admin;
              if (!isSuporte && !isAdmin) return const SizedBox.shrink();
              final adminSelecionado = selectedIndex == 7 || selectedIndex == 8;
              return _ExpandableSidebarItem(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Administração',
                isExpanded: adminSelecionado,
                isSelected: adminSelecionado,
                onTap: () => onDestinationSelected(7),
                children: [
                  if (isSuporte)
                    _SidebarSubItem(
                      label: 'Empresas',
                      isSelected: selectedIndex == 7,
                      onTap: () => onDestinationSelected(7),
                    ),
                  _SidebarSubItem(
                    label: 'Usuários',
                    isSelected: selectedIndex == 8,
                    onTap: () => onDestinationSelected(8),
                  ),
                ],
              );
            },
          ),

          const Spacer(),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Botão Logout no Rodapé da Sidebar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Encerrar Sessão',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavbar extends StatelessWidget {
  final String title;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final VoidCallback? onAdd;

  const _TopNavbar({
    required this.title,
    required this.onLogout,
    required this.onRefresh,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          if (onAdd != null) ...[
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primary),
              tooltip: 'Novo',
              onPressed: onAdd,
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            tooltip: 'Atualizar',
            onPressed: onRefresh,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
            tooltip: 'Sair',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ExpandableSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback? onTap;
  final List<Widget> children;

  const _ExpandableSidebarItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.isSelected,
    this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right,
                        color: isSelected ? AppTheme.textSecondary : const Color(0xFFCBD5E1),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarSubItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 2, bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CARDS DE MÉTRICAS E GRÁFICOS PERSONALIZADOS
// ==========================================

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String badgeText;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isWarning;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.badgeText,
    required this.icon,
    required this.gradientColors,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isWarning ? const Color(0xFFC2410C) : AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: gradientColors.first.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: gradientColors.first,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// Gráfico de Rosca (Donut Chart) Customizado via Canvas
class _DonutChart extends StatelessWidget {
  final int active;
  final int inactive;

  const _DonutChart({required this.active, required this.inactive});

  @override
  Widget build(BuildContext context) {
    final total = active + inactive;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: CustomPaint(
            painter: _DonutChartPainter(active: active, inactive: inactive),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Text(
                    'Alunos',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: const Color(0xFF059669),
                label: 'Adimplentes',
                value: '$active',
              ),
              const SizedBox(height: 12),
              _LegendItem(
                color: const Color(0xFFEA580C),
                label: 'Inadimplentes',
                value: '$inactive',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int active;
  final int inactive;

  _DonutChartPainter({required this.active, required this.inactive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final total = active + inactive;

    final paintBg = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;

    canvas.drawCircle(center, radius, paintBg);

    if (total == 0) return;

    final activeAngle = 2 * pi * (active / total);
    final inactiveAngle = 2 * pi * (inactive / total);

    final paintActive = Paint()
      ..color = const Color(0xFF059669)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22;

    final paintInactive = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22;

    // Desenha arco de adimplentes
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      activeAngle,
      false,
      paintActive,
    );

    // Desenha arco de inadimplentes
    if (inactive > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + activeAngle + 0.05,
        inactiveAngle - 0.05,
        false,
        paintInactive,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Gráfico de Barras Customizado via Canvas
class _BarChart extends StatelessWidget {
  final Map<String, int> data;

  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Nenhuma escola cadastrada', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final maxVal = data.values.isEmpty ? 1 : data.values.reduce(max);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: data.entries.map((entry) {
            final double heightPercentage = maxVal == 0 ? 0 : (entry.value / maxVal);
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: max(20.0, constraints.maxHeight * 0.65 * heightPercentage),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3282B8), Color(0xFF0F4C75)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message: entry.key,
                  child: SizedBox(
                    width: 90,
                    child: Text(
                      entry.key,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
