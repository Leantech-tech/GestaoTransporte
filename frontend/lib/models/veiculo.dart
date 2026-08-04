class Veiculo {
  final String id;
  final String empresaId;
  String nome;
  String placa;
  bool ativo;

  Veiculo({
    required this.id,
    required this.empresaId,
    required this.nome,
    required this.placa,
    this.ativo = true,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    return Veiculo(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      nome: json['nome'] as String,
      placa: json['placa'] as String,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empresa_id': empresaId,
      'nome': nome,
      'placa': placa,
      'ativo': ativo,
    };
  }

  Veiculo copyWith({
    String? id,
    String? empresaId,
    String? nome,
    String? placa,
    bool? ativo,
  }) {
    return Veiculo(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nome: nome ?? this.nome,
      placa: placa ?? this.placa,
      ativo: ativo ?? this.ativo,
    );
  }
}
