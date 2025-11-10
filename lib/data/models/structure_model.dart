import 'package:latlong2/latlong.dart';


class Structure {
  final int id;
  final String name;
  final String? description;
  final dynamic geometry;
  final dynamic centroid;
  final List<int>? floors;
  final int? structureId;

  Structure({
    required this.id,
    required this.name,
    this.description,
    this.geometry,
    this.centroid,
    this.floors,
    this.structureId,
  });

  factory Structure.fromJson(Map<String, dynamic> json) {
    return Structure(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      geometry: json['geometry'],
      centroid: json['centroid'],
      floors: json['floors'] != null ? List<int>.from(json['floors']) : null,
      structureId: json['structureId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'geometry': geometry,
      'centroid': centroid,
      'floors': floors,
      'structureId': structureId,
    };
  }
}