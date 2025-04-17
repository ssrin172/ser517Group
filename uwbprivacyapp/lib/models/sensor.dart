class Sensor {
  final String id;
  final String name;
  final String type;

  Sensor({required this.id, required this.name, required this.type});

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}
