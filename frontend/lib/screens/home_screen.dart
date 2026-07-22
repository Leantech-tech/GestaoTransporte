import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/aluno.dart';
import '../models/escola.dart';
import '../providers/auth_provider.dart';
import 'alunos/alunos_list_screen.dart';
import 'escolas/escolas_list_screen.dart';
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
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
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

      setState(() {
        _escolas = escolas;
        _alunos = alunos;
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    final List<Widget> paginas = [
      _buildDashboardView(),
      const EscolasListScreen(),
      const AlunosListScreen(),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar Elegante
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
                  // Top Navbar Sofisticada
                  _TopNavbar(
                    title: _selectedIndex == 0
                        ? 'Visão Geral'
                        : _selectedIndex == 1
                            ? 'Gestão de Escolas'
                            : 'Gestão de Alunos',
                    onLogout: _logout,
                    onRefresh: _carregarDados,
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
          selectedIndex: _selectedIndex,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
          onDestinationSelected: (int index) {
            setState(() => _selectedIndex = index);
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
    final faturamentoTotal = _alunos.fold<double>(0, (sum, a) => sum + (a.ativo ? a.valor : 0));

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
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      _MetricCard(
                        title: 'Escolas Atendidas',
                        value: '$totalEscolas',
                        badgeText: 'Instituições',
                        icon: Icons.domain_rounded,
                        gradientColors: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      _MetricCard(
                        title: 'Mensalidades Pendentes',
                        value: '$alunosInadimplentes',
                        badgeText: 'Alunos inativos/pend.',
                        icon: Icons.pending_actions_rounded,
                        gradientColors: const [Color(0xFFEA580C), Color(0xFFC2410C)],
                        isWarning: true,
                        onTap: () => setState(() => _selectedIndex = 2),
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
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF1B263B),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo & Marca
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3282B8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 26),
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
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Gestão de Transporte',
                            style: TextStyle(
                              color: Color(0xFF3282B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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

          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),

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

          const Spacer(),
          const Divider(color: Colors.white10, height: 1),

          // Botão Logout no Rodapé da Sidebar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade800.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red.shade300, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Encerrar Sessão',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3282B8) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white60,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  const _TopNavbar({
    required this.title,
    required this.onLogout,
    required this.onRefresh,
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
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.badgeText,
    required this.icon,
    required this.gradientColors,
    this.isWarning = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
