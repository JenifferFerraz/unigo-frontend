class Room {
  final int id;
  final String name;
  final String? description;
  final dynamic geometry;
  final dynamic centroid;
  final int structureId;
  final int? floor;

  Room({
    required this.id,
    required this.name,
    this.description,
    this.geometry,
    this.centroid,
    required this.structureId,
    this.floor,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      geometry: json['geometry'],
      centroid: json['centroid'],
      structureId: json['structureId'],
      floor: json['floor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'geometry': geometry,
      'centroid': centroid,
      'structureId': structureId,
      'floor': floor,
    };
  }
}
