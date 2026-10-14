class SpecialtyModel {
  final String id;
  final String name;
  final String? description;
  final String? iconName;

  const SpecialtyModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon_name': iconName,
  };
}
