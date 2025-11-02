class Event {
  final int id;
  final String title;
  final String city;
  final String location;
  final String date;
  final String? description;
  final bool isSubscribed;

  Event({
    required this.id,
    required this.title,
    required this.city,
    required this.location,
    required this.date,
    this.description,
    this.isSubscribed = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      city: json['city'] ?? '',
      location: json['location'] ?? '',
      date: json['date'] ?? '',
      description: json['description'],
      isSubscribed: json['isSubscribed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'city': city,
      'location': location,
      'date': date,
      'description': description,
      'isSubscribed': isSubscribed,
    };
  }

  Event copyWith({
    int? id,
    String? title,
    String? city,
    String? location,
    String? date,
    String? description,
    bool? isSubscribed,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      city: city ?? this.city,
      location: location ?? this.location,
      date: date ?? this.date,
      description: description ?? this.description,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}
