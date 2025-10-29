// models/notifications_model.dart
class NotificationModel {
  final int id;
  final String titre;
  final String contenu;
  final int membreId;
  final DateTime date;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.membreId,
    required this.date,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) => NotificationModel(
    id: map['notification_id'],
    titre: map['notification_titre'],
    contenu: map['notification_contenu'],
    membreId: map['membre_id'],
    date: DateTime.parse(map['notification_date']),
  );
}