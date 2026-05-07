import '../../models/base_dto.dart';

/// Contract mínimo de um usuário autenticado. O app pode estender.
abstract class ArchbaseUser implements BaseDto {
  String get id;
  String get displayName;
  String? get email;
  List<String> get roles;

  bool hasRole(String role) => roles.contains(role);

  bool hasAnyRole(Iterable<String> required) =>
      required.any((r) => roles.contains(r));
}

/// Implementação simples para apps que não precisam de modelo customizado.
class SimpleArchbaseUser implements ArchbaseUser {
  SimpleArchbaseUser({
    required this.id,
    required this.displayName,
    this.email,
    this.roles = const [],
    this.extra = const {},
  });

  @override
  final String id;
  @override
  final String displayName;
  @override
  final String? email;
  @override
  final List<String> roles;
  final Map<String, dynamic> extra;

  @override
  bool hasRole(String role) => roles.contains(role);

  @override
  bool hasAnyRole(Iterable<String> required) =>
      required.any((r) => roles.contains(r));

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        if (email != null) 'email': email,
        'roles': roles,
        ...extra,
      };

  factory SimpleArchbaseUser.fromJson(Map<String, dynamic> json) {
    return SimpleArchbaseUser(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      displayName: (json['displayName'] ??
              json['fullName'] ??
              json['nome'] ??
              json['name'] ??
              json['email'] ??
              '')
          .toString(),
      email: json['email']?.toString(),
      roles: ((json['roles'] ?? json['authorities'] ?? []) as List)
          .map((e) => e.toString())
          .toList(),
      extra: Map<String, dynamic>.from(json),
    );
  }
}
