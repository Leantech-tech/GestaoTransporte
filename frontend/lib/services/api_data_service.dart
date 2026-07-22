import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/aluno.dart';
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

  Future<int> gerarMensalidades({String? alunoId, required int quantidade, required bool gerarTodos}) async {
    final response = await _client.post('/mensalidades/gerar', {
      'aluno_id': alunoId,
      'quantidade': quantidade,
      'gerar_todos': gerarTodos,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _error(response);
    }
    final data = ApiClient.decodeBody(response);
    return (data['geradas'] as num).toInt();
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
    return Mensalidade.fromJson(ApiClient.decodeBody(response));
  }

  Future<void> removerMensalidade(String id) async {
    final response = await _client.delete('/mensalidades/$id');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _error(response);
    }
  }

  ApiException _error(http.Response response) {
    final data = ApiClient.decodeBody(response);
    return ApiException(data['error']?.toString() ?? 'Erro na requisição', statusCode: response.statusCode);
  }

  ApiException _msg(String msg) => ApiException(msg);
}
