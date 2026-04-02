import 'dart:convert';

class ProjectModel {
  final String id;
  String name;
  String description;
  String ownerAtSign;
  List<String> memberAtSigns;
  DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerAtSign,
    List<String>? memberAtSigns,
    DateTime? createdAt,
  })  : memberAtSigns = memberAtSigns ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'ownerAtSign': ownerAtSign,
        'memberAtSigns': memberAtSigns,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        ownerAtSign: json['ownerAtSign'] as String,
        memberAtSigns:
            List<String>.from(json['memberAtSigns'] as List<dynamic>? ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  factory ProjectModel.fromJsonString(String jsonString) =>
      ProjectModel.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());
}
