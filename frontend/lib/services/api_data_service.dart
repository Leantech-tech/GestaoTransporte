import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/aluno.dart';
import '../models/empresa.dart';
import '../models/escola.dart';
import '../models/mensalidade.dart';
import '../models/usuario.dart';
import 'api_client.dart';

class ApiDataService extends ChangeNotifier {
  final ApiClient _client;
  Usuario? _usuarioLogado;

  ApiDataService(this._client);

  Usuario? get usuarioLogado => _usuarioLogado;

  set usuarioLogado(Usuario? usuario) {
    _usuarioLogado = usuario;
    notifyListeners();
  }

  bool get isSuporte => _usuarioLogado?.isSuporte ?? false;

  Future<List<Escola>> listarEscolas() async {
    final response = await _client.get('/escolas');
    if (response.statusCode != 200) {
      throw _error(response);
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((e) => Escola.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Usuario>> listarUsuarios() async {
    final response = await _client.get('/usuarios');
    if (response.statusCode != 200) {
      throw _error(response);
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Empresa>> listarEmpresas() async {
    final response = await _client.get('/empresas');
    if (response.statusCode != 200) {
      throw _error(response);
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((e) => Empresa.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Aluno>> listarAlunos() async {
    final response = await _client.get('/alunos');
    if (response.statusCode != 200) {
      throw _error(response);
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((e) => Aluno.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Escola> salvarEscola(Escola escola) async {
    http.Response response;
    if (escola.id.isEmpty) {
      throw _msg('ID da escola não pode estar vazio');
    }
    if (escola.id.startsWith('new-')) {
      response = await _client.post('/escolas', escola.toJson());
    } else {
      response = await _client.put('/escolas/${escola.id}', escola.toJson());
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _error(response);
    }
    return Escola.fromJson(ApiClient.decodeBody(response));
  }

  Future<Usuario> salvarUsuario(Usuario usuario, {String? senha}) async {
    http.Response response;
    if (usuario.id.isEmpty) {
      throw _msg('ID do usuário não pode estar vazio');
    }
    final body = usuario.toJson();
    if (senha != null && senha.isNotEmpty) {
      body['senha'] = senha;
    }
    if (usuario.id.startsWith('new-')) {
      response = await _client.post('/usuarios', body);
    } else {
      response = await _client.put('/usuarios/${usuario.id}', body);
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _error(response);
    }
    return Usuario.fromJson(ApiClient.decodeBody(response));
  }

  Future<Empresa> salvarEmpresa(Empresa empresa) async {
    http.Response response;
    if (empresa.id.isEmpty) {
      throw _msg('ID da empresa não pode estar vazio');
    }
    if (empresa.id.startsWith('new-')) {
      response = await _client.post('/empresas', empresa.toJson());
    } else {
      response = await _client.put('/empresas/${empresa.id}', empresa.toJson());
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _error(response);
    }
    return Empresa.fromJson(ApiClient.decodeBody(response));
  }

  Future<Aluno> salvarAluno(Aluno aluno) async {
    http.Response response;
    if (aluno.id.isEmpty) {
      throw _msg('ID do aluno não pode estar vazio');
    }
    if (aluno.id.startsWith('new-')) {
      response = await _client.post('/alunos', aluno.toJson());
    } else {
      response = await _client.put('/alunos/${aluno.id}', aluno.toJson());
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _error(response);
    }
    return Aluno.fromJson(ApiClient.decodeBody(response));
  }

  Future<void> removerEscola(String id) async {
    final response = await _client.delete('/escolas/$id');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _error(response);
    }
  }

  Future<void> removerUsuario(String id) async {
    final response = await _client.delete('/usuarios/$id');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _error(response);
    }
  }

  Future<void> removerEmpresa(String id) async {
    final response = await _client.delete('/empresas/$id');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _error(response);
    }
  }

  Future<void> removerAluno(String id) async {
    final response = await _client.delete('/alunos/$id');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _error(response);
    }
  }

  Future<List<Mensalidade>> listarMensalidades() async {
    final response = await _client.get('/mensalidades');
    if (response.statusCode != 200) {
      throw _error(response);
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((e) => Mensalidade.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GerarMensalidadesResult> gerarMensalidades({
    String? alunoId,
    required int quantidade,
    required bool gerarTodos,
    DateTime? dataEmissao,
  }) async {
    final body = <String, dynamic>{
      'aluno_id': alunoId,
      'quantidade': quantidade,
      'gerar_todos': gerarTodos,
    };
    if (dataEmissao != null) {
      body['data_emissao'] = _formatDate(dataEmissao);
    }
    final response = await _client.post('/mensalidades/gerar', body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _error(response);
    }
    final data = ApiClient.decodeBody(response);
    final mensalidades = (data['mensalidades'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    // Notify listeners that mensalidades may have changed on the server
    notifyListeners();
    return GerarMensalidadesResult(
      geradas: (data['geradas'] as num).toInt(),
      mensalidades: mensalidades,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<Mensalidade> salvarMensalidade(Mensalidade mensalidade) async {
    http.Response response;
    if (mensalidade.id.isEmpty) {
      throw _msg('ID da mensalidade não pode estar vazio');
    }
    if (mensalidade.id.startsWith('new-')) {
      response = await _client.post('/mensalidades', mensalidade.toJson());
    } else {
      response = await _client.put('/mensalidades/${mensalidade.id}', mensalidade.toJson());
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _error(response);
    }
    final result = Mensalidade.fromJson(ApiClient.decodeBody(response));
    notifyListeners();
    return result;
  }

  Future<void> removerMensalidade(String id) async {
    final response = await _client.delete('/mensalidades/$id');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _error(response);
    }
    notifyListeners();
  }

  ApiException _error(http.Response response) {
    final data = ApiClient.decodeBody(response);
    return ApiException(data['error']?.toString() ?? 'Erro na requisição', statusCode: response.statusCode);
  }

  ApiException _msg(String msg) => ApiException(msg);
}

class GerarMensalidadesResult {
  final int geradas;
  final List<String> mensalidades;

  const GerarMensalidadesResult({
    required this.geradas,
    required this.mensalidades,
  });
}
