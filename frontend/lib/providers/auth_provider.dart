import 'package:flutter/material.dart';

import '../models/empresa.dart';
import '../models/usuario.dart';
import '../services/api_auth_service.dart';
import '../services/api_client.dart';
import '../services/api_data_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  late final ApiAuthService _authService = ApiAuthService();
  late final ApiDataService _dataService = ApiDataService(_apiClient);

  Usuario? _usuario;
  Empresa? _empresa;
  String? _token;
  String? _erro;
  bool _carregando = false;

  Usuario? get usuario => _usuario;
  Empresa? get empresa => _empresa;
  String? get erro => _erro;
  bool get carregando => _carregando;
  String? get token => _token;
  bool get estaLogado => _usuario != null;

  ApiClient get apiClient => _apiClient;
  ApiDataService get dataService => _dataService;

  Future<bool> login(String email, String senha) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final (usuario, token, empresa) = await _authService.login(email, senha);

      _usuario = usuario;
      _empresa = empresa;
      _token = token;
      _apiClient.setToken(token);
      _dataService.usuarioLogado = usuario;
      _carregando = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _erro = e.message;
      _carregando = false;
      notifyListeners();
      return false;
    } catch (e) {
      _erro = 'Erro ao realizar login.';
      _carregando = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _usuario = null;
    _empresa = null;
    _token = null;
    _erro = null;
    _apiClient.setToken(null);
    _dataService.usuarioLogado = null;
    _authService.logout();
    notifyListeners();
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }
}
