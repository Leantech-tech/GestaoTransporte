import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'gerar_mensalidade_screen.dart';
import 'receber_mensalidade_screen.dart';

class FinanceiroHubScreen extends StatelessWidget {
  final VoidCallback? onGerarMensalidade;
  final VoidCallback? onReceberMensalidade;

  const FinanceiroHubScreen({
    super.key,
    this.onGerarMensalidade,
    this.onReceberMensalidade,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financeiro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gerenciamento de mensalidades escolares',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 1,
              childAspectRatio: 2.5,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              children: [
                _OpcaoCard(
                  title: 'Gerar Mensalidade',
                  subtitle: 'Gerar mensalidades para alunos ativos',
                  icon: Icons.add_card,
                  gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  onTap: onGerarMensalidade ?? () => _abrir(context, const GerarMensalidadeScreen()),
                ),
                _OpcaoCard(
                  title: 'Receber Mensalidade',
                  subtitle: 'Listar, receber e gerenciar mensalidades',
                  icon: Icons.payments,
                  gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
                  onTap: onReceberMensalidade ?? () => _abrir(context, const ReceberMensalidadeScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrir(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _OpcaoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _OpcaoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
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
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
