class Escola {
  final String id;
  final String empresaId;
  String nome;
  String enderecoCompleto;
  String? cep;
  String? numero;
  String? telefone;
  bool ativa;

  Escola({
    required this.id,
    required this.empresaId,
    required this.nome,
    required this.enderecoCompleto,
    this.cep,
    this.numero,
    this.telefone,
    this.ativa = true,
  });

  factory Escola.fromJson(Map<String, dynamic> json) {
    return Escola(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      nome: json['nome'] as String,
      enderecoCompleto: json['endereco_completo'] as String,
      cep: json['cep'] as String?,
      numero: json['numero'] as String?,
      telefone: json['telefone'] as String?,
      ativa: json['ativa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'endereco_completo': enderecoCompleto,
      if (cep != null && cep!.isNotEmpty) 'cep': cep,
      if (numero != null && numero!.isNotEmpty) 'numero': numero,
      if (telefone != null) 'telefone': telefone,
      'ativa': ativa,
    };
  }
}
