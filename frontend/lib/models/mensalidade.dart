class Mensalidade {
  final String id;
  final String empresaId;
  final String alunoId;
  final String? alunoNome;
  final double valor;
  final DateTime dataVencimento;
  final DateTime? dataPagamento;
  final String status;
  final String? observacao;

  Mensalidade({
    required this.id,
    required this.empresaId,
    required this.alunoId,
    this.alunoNome,
    required this.valor,
    required this.dataVencimento,
    this.dataPagamento,
    required this.status,
    this.observacao,
  });

  factory Mensalidade.fromJson(Map<String, dynamic> json) {
    return Mensalidade(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      alunoId: json['aluno_id'] as String,
      alunoNome: json['aluno_nome'] as String?,
      valor: (json['valor'] as num).toDouble(),
      dataVencimento: DateTime.parse(json['data_vencimento'] as String),
      dataPagamento: json['data_pagamento'] != null
          ? DateTime.parse(json['data_pagamento'] as String)
          : null,
      status: json['status'] as String,
      observacao: json['observacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aluno_id': alunoId,
      'valor': valor,
      'data_vencimento': _formatDate(dataVencimento),
      'data_pagamento': dataPagamento != null ? _formatDate(dataPagamento!) : null,
      'status': status,
      'observacao': observacao,
    };
  }

  Mensalidade copyWith({
    String? id,
    String? empresaId,
    String? alunoId,
    String? alunoNome,
    double? valor,
    DateTime? dataVencimento,
    DateTime? dataPagamento,
    String? status,
    String? observacao,
  }) {
    return Mensalidade(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      alunoId: alunoId ?? this.alunoId,
      alunoNome: alunoNome ?? this.alunoNome,
      valor: valor ?? this.valor,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
