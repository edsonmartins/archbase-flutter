import 'package:archbase_flutter/archbase_flutter.dart';

/// Ponto-de-venda (loja, mercado, posto). Usado como entidade principal
/// de listagem.
class Pdv implements BaseDto {
  Pdv({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.cidade,
    required this.uf,
    required this.latitude,
    required this.longitude,
    this.responsavel,
  });

  final String id;
  final String nome;
  final String endereco;
  final String cidade;
  final String uf;
  final double latitude;
  final double longitude;
  final String? responsavel;

  String get cidadeUf => '$cidade/$uf';

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'endereco': endereco,
    'cidade': cidade,
    'uf': uf,
    'latitude': latitude,
    'longitude': longitude,
    if (responsavel != null) 'responsavel': responsavel,
  };

  factory Pdv.fromJson(Map<String, dynamic> json) {
    return Pdv(
      id: json['id'].toString(),
      nome: json['nome'].toString(),
      endereco: (json['endereco'] ?? '').toString(),
      cidade: (json['cidade'] ?? '').toString(),
      uf: (json['uf'] ?? '').toString(),
      latitude: JsonParse.decimal(json['latitude']) ?? 0,
      longitude: JsonParse.decimal(json['longitude']) ?? 0,
      responsavel: json['responsavel']?.toString(),
    );
  }
}
