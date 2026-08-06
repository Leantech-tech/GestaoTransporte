class Linha {
  final String id;
  final String empresaId;
  final String colaboradorId;
  final String veiculoId;
  String nome;
  String origem;
  String destino;

  Linha({
    required this.id,
    required this.empresaId,
    required this.colaboradorId,
    required this.veiculoId,
    required this.nome,
    required this.origem,
    required this.destino,
  });

  factory Linha.fromJson(Map<String, dynamic> json) {
    return Linha(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      colaboradorId: json['colaborador_id'] as String,
      veiculoId: json['veiculo_id'] as String,
      nome: json['nome'] as String,
      origem: json['origem'] as String,
      destino: json['destino'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empresa_id': empresaId,
      'colaborador_id': colaboradorId,
      'veiculo_id': veiculoId,
      'nome': nome,
      'origem': origem,
      'destino': destino,
    };
  }

  Linha copyWith({
    String? id,
    String? empresaId,
    String? colaboradorId,
    String? veiculoId,
    String? nome,
    String? origem,
    String? destino,
  }) {
    return Linha(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      veiculoId: veiculoId ?? this.veiculoId,
      nome: nome ?? this.nome,
      origem: origem ?? this.origem,
      destino: destino ?? this.destino,
    );
  }
}
