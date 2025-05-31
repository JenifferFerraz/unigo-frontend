class Location {
  final int id;
  final String name;
  final String code;
  final String type;
  final String? description;
  final int? floor;
  final String? block;
  final double? latitude;
  final double? longitude;
  final String? nearbyLandmarks;
  final String? accessibilityNotes;

  Location({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.description,
    this.floor,
    this.block,
    this.latitude,
    this.longitude,
    this.nearbyLandmarks,
    this.accessibilityNotes,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      type: json['type'],
      description: json['description'],
      floor: json['floor'],
      block: json['block'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      nearbyLandmarks: json['nearbyLandmarks'],
      accessibilityNotes: json['accessibilityNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type,
      'description': description,
      'floor': floor,
      'block': block,
      'latitude': latitude,
      'longitude': longitude,
      'nearbyLandmarks': nearbyLandmarks,
      'accessibilityNotes': accessibilityNotes,
    };
  }
}

class ClassNotification {
  final int userId;
  final String userName;
  final String className;
  final String courseName;
  final String locationCode;
  final String locationName;
  final String block;
  final int? floor;
  final String startTime;
  final String endTime;

  ClassNotification({
    required this.userId,
    required this.userName,
    required this.className,
    required this.courseName,
    required this.locationCode,
    required this.locationName,
    required this.block,
    this.floor,
    required this.startTime,
    required this.endTime,
  });

  factory ClassNotification.fromJson(Map<String, dynamic> json) {
    return ClassNotification(
      userId: json['userId'],
      userName: json['userName'],
      className: json['className'],
      courseName: json['courseName'],
      locationCode: json['locationCode'],
      locationName: json['locationName'],
      block: json['block'],
      floor: json['floor'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}
