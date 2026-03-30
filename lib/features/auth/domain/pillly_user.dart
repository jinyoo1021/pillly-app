class PilllyUser {
  const PilllyUser({
    required this.id,
    required this.email,
    this.name,
    this.language,
    this.timezone,
  });

  final String id;
  final String email;
  final String? name;
  final String? language;
  final String? timezone;

  factory PilllyUser.fromMap(Map<String, dynamic> map) {
    return PilllyUser(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      language: map['language'] as String?,
      timezone: map['timezone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      if (name != null) 'name': name,
      if (language != null) 'language': language,
      if (timezone != null) 'timezone': timezone,
    };
  }

  PilllyUser copyWith({
    String? name,
    String? language,
    String? timezone,
  }) {
    return PilllyUser(
      id: id,
      email: email,
      name: name ?? this.name,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
    );
  }
}