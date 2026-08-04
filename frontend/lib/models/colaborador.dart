class Colaborador {
  final String id;
  final String empresaId;
  String nome;
  String tipo;
  String telefone;
  String cpf;
  bool ativa;

  Colaborador({
    required this.id,
    required this.empresaId,
    required this.nome,
    required this.tipo,
    required this.telefone,
    required this.cpf,
    this.ativa = true,
  });

  factory Colaborador.fromJson(Map<String, dynamic> json) {
    return Colaborador(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      nome: json['nome'] as String,
      tipo: json['tipo'] as String,
      telefone: json['telefone'] as String,
      cpf: json['cpf'] as String,
      ativa: json['ativa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empresa_id': empresaId,
      'nome': nome,
      'tipo': tipo,
      'telefone': telefone,
      'cpf': cpf,
      'ativa': ativa,
    };
  }

  Colaborador copyWith({
    String? id,
    String? empresaId,
    String? nome,
    String? tipo,
    String? telefone,
    String? cpf,
    bool? ativa,
  }) {
    return Colaborador(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      ativa: ativa ?? this.ativa,
    );
  }
}
