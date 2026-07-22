import '../models/empresa.dart';
import '../models/usuario.dart';
import 'api_client.dart';

class ApiAuthService {
  final ApiClient _client = ApiClient();

  ApiClient get client => _client;

  /// Retorna a senha de suporte no formato contínuo: diaDaSemana+ano+mes+dia
  /// Convenção: domingo = 1, segunda = 2, ..., sábado = 7.
  /// Exemplo: 420260722 (quarta-feira, 22 de julho de 2026)
  String gerarSenhaSuporte(DateTime data) {
    final diaSemana = data.weekday == 7 ? 1 : data.weekday + 1;
    final ano = data.year.toString();
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '$diaSemana$ano$mes$dia';
  }

  Future<(Usuario, String, Empresa?)> login(String email, String senha, {DateTime? hoje}) async {
    hoje ??= DateTime.now();

    final response = await _client.post('/login', {
      'email': email.trim(),
      'senha': senha.trim(),
    });

    final data = ApiClient.decodeBody(response);

    if (response.statusCode != 200) {
      throw ApiException(data['error']?.toString() ?? 'Erro ao realizar login', statusCode: response.statusCode);
    }

    final token = data['token'] as String;
    final usuario = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
    final empresaJson = data['empresa'] as Map<String, dynamic>?;
    final empresa = empresaJson != null ? Empresa.fromJson(empresaJson) : null;

    _client.setToken(token);
    return (usuario, token, empresa);
  }

  void logout() {
    _client.setToken(null);
  }
}
