class Task {
  final String id; // Firestore-generated ID
  final int? localId; // Optional integer ID for local use
  String title;
  bool isCompleted;

  Task({
    required this.id,
    this.localId,
    required this.title,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localId': localId,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      localId: map['localId'],
      title: map['title'],
      isCompleted: map['isCompleted'],
    );
  }
}
