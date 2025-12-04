class Event {
  final int id;
  final String title;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String location;
  final bool isActive;
  final String? link;
  final String? createdAt;
  final String? updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    required this.location,
    this.isActive = true,
    this.link,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      location: json['location'] ?? '',
      isActive: json['isActive'] ?? true,
      link: json['link'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'isActive': isActive,
      'link': link,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Event copyWith({
    int? id,
    String? title,
    String? description,
    String? startDate,
    String? endDate,
    String? location,
    bool? isActive,
    String? link,
    String? createdAt,
    String? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      link: link ?? this.link,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}