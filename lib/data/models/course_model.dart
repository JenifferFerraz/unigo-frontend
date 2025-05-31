class Course {
  final int id;
  final String name;
  final int period;
  final String shift;
  final String className;

  Course({
    required this.id,
    required this.name,
    required this.period,
    required this.shift,
    required this.className,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      period: json['period'],
      shift: json['shift'],
      className: json['className'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'period': period,
      'shift': shift,
      'className': className,
    };
  }
}
