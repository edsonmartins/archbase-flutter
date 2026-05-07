import 'package:archbase_flutter/archbase_flutter.dart';

import 'pdv.dart';

enum VisitaStatus with LabeledEnum {
  planejada('PLANEJADA', 'Planejada'),
  emAndamento('EM_ANDAMENTO', 'Em andamento'),
  concluida('CONCLUIDA', 'Concluída'),
  cancelada('CANCELADA', 'Cancelada');

  const VisitaStatus(this.value, this.label);

  @override
  final String value;
  @override
  final String label;
}

/// Visita a um PDV — entidade central do CRUD do demo.
class Visita implements BaseDto {
  Visita({
    required this.id,
    required this.pdv,
    required this.status,
    required this.dataAgendada,
    this.dataConclusao,
    this.observacao,
    this.fotoBase64,
  });

  final String id;
  final Pdv pdv;
  final VisitaStatus status;
  final DateTime dataAgendada;
  final DateTime? dataConclusao;
  final String? observacao;
  final String? fotoBase64;

  bool get concluida => status == VisitaStatus.concluida;
  bool get atrasada =>
      status == VisitaStatus.planejada && DateTime.now().isAfter(dataAgendada);

  Visita copyWith({
    VisitaStatus? status,
    DateTime? dataAgendada,
    DateTime? dataConclusao,
    String? observacao,
    String? fotoBase64,
  }) {
    return Visita(
      id: id,
      pdv: pdv,
      status: status ?? this.status,
      dataAgendada: dataAgendada ?? this.dataAgendada,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      observacao: observacao ?? this.observacao,
      fotoBase64: fotoBase64 ?? this.fotoBase64,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'pdv': pdv.toJson(),
    'status': status.value,
    'dataAgendada': dataAgendada.toIso8601String(),
    'dataConclusao': dataConclusao?.toIso8601String(),
    if (observacao != null) 'observacao': observacao,
    if (fotoBase64 != null) 'fotoBase64': fotoBase64,
  };

  factory Visita.fromJson(Map<String, dynamic> json) {
    return Visita(
      id: json['id'].toString(),
      pdv: Pdv.fromJson((json['pdv'] as Map).cast<String, dynamic>()),
      status: LabeledEnums.fromString(
        VisitaStatus.values,
        json['status']?.toString(),
      ),
      dataAgendada: JsonParse.date(json['dataAgendada']) ?? DateTime.now(),
      dataConclusao: JsonParse.date(json['dataConclusao']),
      observacao: json['observacao']?.toString(),
      fotoBase64: json['fotoBase64']?.toString(),
    );
  }
}
