import 'package:rest_client_builder/rest_client_builder.dart';


enum Role { admin, member, guest }

@RestModel()
class Address {
  const Address({
    this.city,
    this.country,
  });

  final String? city;
  final String? country;
}

@RestModel()
class User {
  const User({
    this.id,
    this.name,
    this.role,
    required this.createdAt,
    required this.tags,
    required this.scores,
    this.address,
    this.nickname = 'guest',
    this.localOnly,
  });

  final String? id;

  @JsonKey(name: 'user_name')
  final String? name;

  final Role? role;
  final DateTime createdAt;
  final List<String> tags;
  final Map<String, int> scores;
  final Address? address;

  @JsonKey(defaultValue: 'guest')
  final String nickname;

  @JsonKey(ignore: true)
  final String? localOnly;
}
