enum Perfil { admin, operador, suporte }

class Usuario {
  final String id;
  final String? empresaId;
  final String nome;
  final String email;
  final Perfil perfil;
  final bool ativo;

  Usuario({
    required this.id,
    this.empresaId,
    required this.nome,
    required this.email,
    required this.perfil,
    this.ativo = true,
  });

  bool get isSuporte => perfil == Perfil.suporte;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String?,
      nome: json['nome'] as String,
      email: json['email'] as String,
      perfil: _parsePerfil(json['perfil'] as String),
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  static Perfil _parsePerfil(String value) {
    return Perfil.values.firstWhere(
      (p) => p.name == value,
      orElse: () => Perfil.operador,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'perfil': perfil.name,
      'ativo': ativo,
      if (empresaId != null) 'empresa_id': empresaId,
    };
  }

  Usuario copyWith({
    String? id,
    String? empresaId,
    String? nome,
    String? email,
    Perfil? perfil,
    bool? ativo,
  }) {
    return Usuario(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      perfil: perfil ?? this.perfil,
      ativo: ativo ?? this.ativo,
    );
  }
}
