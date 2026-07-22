class Aluno {
  final String id;
  final String empresaId;
  String escolaId;
  String nome;
  String endereco;
  double mensalidade;
  double valor;
  int diaVencimento;
  String responsavelNome;
  String responsavelTelefone;
  bool ativo;

  Aluno({
    required this.id,
    required this.empresaId,
    required this.escolaId,
    required this.nome,
    required this.endereco,
    this.mensalidade = 0,
    this.valor = 0,
    required this.diaVencimento,
    required this.responsavelNome,
    required this.responsavelTelefone,
    this.ativo = true,
  });

  factory Aluno.fromJson(Map<String, dynamic> json) {
    return Aluno(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      escolaId: json['escola_id'] as String,
      nome: json['nome'] as String,
      endereco: json['endereco'] as String,
      mensalidade: (json['mensalidade'] as num).toDouble(),
      valor: (json['valor'] as num).toDouble(),
      diaVencimento: json['dia_vencimento'] as int,
      responsavelNome: json['responsavel_financeiro'] as String,
      responsavelTelefone: json['responsavel_telefone'] as String,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'escola_id': escolaId,
      'nome': nome,
      'endereco': endereco,
      'mensalidade': mensalidade,
      'valor': valor,
      'dia_vencimento': diaVencimento,
      'responsavel_financeiro': responsavelNome,
      'responsavel_telefone': responsavelTelefone,
      'ativo': ativo,
    };
  }
}
