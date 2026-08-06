class Empresa {
  final String id;
  final String nome;
  final String? cnpj;
  final String? telefone;
  final String? cep;
  final String? endereco;
  final String? numero;
  final bool ativa;

  Empresa({
    required this.id,
    required this.nome,
    this.cnpj,
    this.telefone,
    this.cep,
    this.endereco,
    this.numero,
    this.ativa = true,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cnpj: json['cnpj'] as String?,
      telefone: json['telefone'] as String?,
      cep: json['cep'] as String?,
      endereco: json['endereco'] as String?,
      numero: json['numero'] as String?,
      ativa: json['ativa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      if (cnpj != null) 'cnpj': cnpj,
      if (telefone != null) 'telefone': telefone,
      if (cep != null && cep!.isNotEmpty) 'cep': cep,
      if (endereco != null) 'endereco': endereco,
      if (numero != null && numero!.isNotEmpty) 'numero': numero,
      'ativa': ativa,
    };
  }

  Empresa copyWith({
    String? id,
    String? nome,
    String? cnpj,
    String? telefone,
    String? cep,
    String? endereco,
    String? numero,
    bool? ativa,
  }) {
    return Empresa(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      cep: cep ?? this.cep,
      endereco: endereco ?? this.endereco,
      numero: numero ?? this.numero,
      ativa: ativa ?? this.ativa,
    );
  }
}
