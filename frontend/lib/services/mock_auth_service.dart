import '../models/empresa.dart';
import '../models/usuario.dart';

class MockAuthService {
  static final List<Empresa> _empresas = [
    Empresa(id: 'e1', nome: 'Transporte Escolar Alfa', cnpj: '11.111.111/0001-11', telefone: '(11) 11111-1111', endereco: 'Rua Alfa, 100'),
    Empresa(id: 'e2', nome: 'Transporte Escolar Beta', cnpj: '22.222.222/0002-22', telefone: '(22) 22222-2222', endereco: 'Rua Beta, 200'),
  ];

  static final List<Usuario> _usuarios = [
    Usuario(id: 'u1', empresaId: 'e1', nome: 'João Silva', email: 'joao@alfa.com', perfil: Perfil.admin),
    Usuario(id: 'u2', empresaId: 'e2', nome: 'Maria Souza', email: 'maria@beta.com', perfil: Perfil.admin),
    Usuario(id: 'u3', empresaId: 'e1', nome: 'Operador Alfa', email: 'operador@alfa.com', perfil: Perfil.operador),
  ];

  List<Empresa> get empresas => List.unmodifiable(_empresas);

  /// Retorna a senha de suporte no formato contínuo: diaDaSemana+ano+mes+diaDoMes
  /// Convenção: domingo = 1, segunda = 2, ..., sábado = 7.
  /// Exemplo: 420260722 (quarta-feira, 22 de julho de 2026)
  String gerarSenhaSuporte(DateTime data) {
    final diaSemana = data.weekday == 7 ? 1 : data.weekday + 1;
    final ano = data.year.toString();
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '$diaSemana$ano$mes$dia';
  }

  Future<Usuario?> login(String email, String senha, {DateTime? hoje}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    hoje ??= DateTime.now();

    // Login de suporte
    if (email.trim().toLowerCase() == 'suporte') {
      final senhaEsperada = gerarSenhaSuporte(hoje);
      if (senha.trim() == senhaEsperada) {
        return Usuario(
          id: 'suporte',
          nome: 'Suporte',
          email: 'suporte@sistema.com',
          perfil: Perfil.suporte,
        );
      }
      return null;
    }

    // Login de usuário comum
    final Usuario? usuario = _usuarios
        .where((u) => u.email.toLowerCase() == email.trim().toLowerCase() && u.ativo)
        .firstOrNull;
    if (usuario == null) return null;

    // Mock de verificação de senha (qualquer senha serve para usuários mockados)
    return usuario;
  }

  Empresa? buscarEmpresa(String? empresaId) {
    if (empresaId == null) return null;
    try {
      return _empresas.firstWhere((e) => e.id == empresaId);
    } catch (_) {
      return null;
    }
  }
}
