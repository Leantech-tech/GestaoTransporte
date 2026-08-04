class Escola {
  final String id;
  final String empresaId;
  String nome;
  String enderecoCompleto;
  String? telefone;
  bool ativa;

  Escola({
    required this.id,
    required this.empresaId,
    required this.nome,
    required this.enderecoCompleto,
    this.telefone,
    this.ativa = true,
  });

  factory Escola.fromJson(Map<String, dynamic> json) {
    return Escola(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      nome: json['nome'] as String,
      enderecoCompleto: json['endereco_completo'] as String,
      telefone: json['telefone'] as String?,
      ativa: json['ativa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'endereco_completo': enderecoCompleto,
      if (telefone != null) 'telefone': telefone,
      'ativa': ativa,
    };
  }
}
