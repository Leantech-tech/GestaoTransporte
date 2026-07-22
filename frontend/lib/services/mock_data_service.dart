import 'package:flutter/material.dart';

import '../models/aluno.dart';
import '../models/escola.dart';
import '../models/usuario.dart';

class MockDataService extends ChangeNotifier {
  final List<Escola> _escolas = [
    Escola(id: 'esc1', empresaId: 'e1', nome: 'Escola Municipal Alfa', enderecoCompleto: 'Rua das Flores, 500 - Centro'),
    Escola(id: 'esc2', empresaId: 'e1', nome: 'Colégio Particular Beta', enderecoCompleto: 'Av. Brasil, 1200 - Jardim'),
    Escola(id: 'esc3', empresaId: 'e2', nome: 'Escola Estadual Gamma', enderecoCompleto: 'Rua do Sol, 300 - Bairro Novo'),
  ];

  final List<Aluno> _alunos = [
    Aluno(
      id: 'a1',
      empresaId: 'e1',
      escolaId: 'esc1',
      nome: 'Pedro Henrique',
      endereco: 'Rua A, 45 - Centro',
      mensalidade: 450.00,
      valor: 450.00,
      diaVencimento: 10,
      responsavelNome: 'Ana Paula',
      responsavelTelefone: '(11) 99999-0001',
    ),
    Aluno(
      id: 'a2',
      empresaId: 'e1',
      escolaId: 'esc2',
      nome: 'Laura Beatriz',
      endereco: 'Rua B, 88 - Jardim',
      mensalidade: 520.00,
      valor: 520.00,
      diaVencimento: 15,
      responsavelNome: 'Carlos Eduardo',
      responsavelTelefone: '(11) 99999-0002',
    ),
    Aluno(
      id: 'a3',
      empresaId: 'e2',
      escolaId: 'esc3',
      nome: 'Gabriel Santos',
      endereco: 'Rua C, 12 - Bairro Novo',
      mensalidade: 380.00,
      valor: 380.00,
      diaVencimento: 5,
      responsavelNome: 'Fernanda Lima',
      responsavelTelefone: '(22) 99999-0003',
    ),
  ];

  Usuario? _usuarioLogado;

  Usuario? get usuarioLogado => _usuarioLogado;

  set usuarioLogado(Usuario? usuario) {
    _usuarioLogado = usuario;
    notifyListeners();
  }

  bool get isSuporte => _usuarioLogado?.isSuporte ?? false;

  List<Escola> listarEscolas() {
    if (_usuarioLogado == null) return [];
    if (_usuarioLogado!.isSuporte) return List.unmodifiable(_escolas);
    return _escolas.where((e) => e.empresaId == _usuarioLogado!.empresaId).toList();
  }

  List<Aluno> listarAlunos() {
    if (_usuarioLogado == null) return [];
    if (_usuarioLogado!.isSuporte) return List.unmodifiable(_alunos);
    return _alunos.where((a) => a.empresaId == _usuarioLogado!.empresaId).toList();
  }

  Escola? buscarEscola(String id) {
    try {
      return _escolas.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Aluno? buscarAluno(String id) {
    try {
      return _alunos.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void salvarEscola(Escola escola) {
    final index = _escolas.indexWhere((e) => e.id == escola.id);
    if (index >= 0) {
      _escolas[index] = escola;
    } else {
      _escolas.add(escola);
    }
    notifyListeners();
  }

  void salvarAluno(Aluno aluno) {
    final index = _alunos.indexWhere((a) => a.id == aluno.id);
    if (index >= 0) {
      _alunos[index] = aluno;
    } else {
      _alunos.add(aluno);
    }
    notifyListeners();
  }

  void removerEscola(String id) {
    _escolas.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void removerAluno(String id) {
    _alunos.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void inativarEscola(String id) {
    final escola = buscarEscola(id);
    if (escola != null) {
      escola.ativa = false;
      notifyListeners();
    }
  }

  void inativarAluno(String id) {
    final aluno = buscarAluno(id);
    if (aluno != null) {
      aluno.ativo = false;
      notifyListeners();
    }
  }
}
