class Empresa {
  final String id;
  final String nome;
  final String? cnpj;
  final String? telefone;
  final String? endereco;
  final bool ativa;

  Empresa({
    required this.id,
    required this.nome,
    this.cnpj,
    this.telefone,
    this.endereco,
    this.ativa = true,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cnpj: json['cnpj'] as String?,
      telefone: json['telefone'] as String?,
      endereco: json['endereco'] as String?,
      ativa: json['ativa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      if (cnpj != null) 'cnpj': cnpj,
      if (telefone != null) 'telefone': telefone,
      if (endereco != null) 'endereco': endereco,
      'ativa': ativa,
    };
  }
}
