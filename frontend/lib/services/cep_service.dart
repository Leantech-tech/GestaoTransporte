import 'dart:convert';
import 'package:http/http.dart' as http;

class CepResult {
  final String logradouro;
  final String bairro;
  final String localidade;
  final String uf;
  final bool sucesso;
  final String? erro;

  const CepResult({
    this.logradouro = '',
    this.bairro = '',
    this.localidade = '',
    this.uf = '',
    this.sucesso = false,
    this.erro,
  });

  String get enderecoCompleto {
    final partes = [
      logradouro,
      if (bairro.isNotEmpty) bairro,
      if (localidade.isNotEmpty) localidade,
      if (uf.isNotEmpty) uf,
    ];
    return partes.join(', ');
  }

  factory CepResult.fromJson(Map<String, dynamic> json) {
    return CepResult(
      logradouro: json['logradouro'] as String? ?? '',
      bairro: json['bairro'] as String? ?? '',
      localidade: json['localidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
      sucesso: json['erro'] != true,
    );
  }
}

class CepService {
  static Future<CepResult> consultar(String cep) async {
    final digits = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) {
      return const CepResult(erro: 'CEP inválido.', sucesso: false);
    }

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$digits/json/'),
      );

      if (response.statusCode != 200) {
        return CepResult(erro: 'Erro ao consultar CEP (${response.statusCode}).', sucesso: false);
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['erro'] == true) {
        return const CepResult(erro: 'CEP não encontrado.', sucesso: false);
      }

      return CepResult.fromJson(data);
    } catch (e) {
      return CepResult(erro: 'Erro ao consultar CEP: $e', sucesso: false);
    }
  }
}
