class SosContact {
  final String id;
  final String name;
  final String phone;

  const SosContact({required this.id, required this.name, required this.phone});

  factory SosContact.fromJson(Map<String, dynamic> json) {
    return SosContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone': phone};
  }

  SosContact copyWith({String? id, String? name, String? phone}) {
    return SosContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}
