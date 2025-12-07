
import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

// --- Modèle de Données ---
class NotificationModel {
  final int id;
  final String title;
  final String content;
  final DateTime date;
  final String? type;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.type,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map[DbHelper.NOTIFICATION_ID],
      title: map[DbHelper.NOTIFICATION_TITRE],
      content: map[DbHelper.NOTIFICATION_CONTENU],
      date: DateTime.parse(map[DbHelper.NOTIFICATION_DATE]),
      type: map[DbHelper.NOTIFICATION_TYPE],
      isRead: map[DbHelper.NOTIFICATION_IS_READ] == 1,
    );
  }
}

// --- Écran Principal ---
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = DbHelper.getNotifications().then(
        (maps) => maps.map((map) => NotificationModel.fromMap(map)).toList(),
      );
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await DbHelper.markNotificationAsRead(notification.id);
      _loadNotifications();
    }
  }

  Future<void> _deleteNotification(int id) async {
    await DbHelper.deleteNotification(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Notification supprimée.'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating),
    );
    _loadNotifications();
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Row(children: [Icon(Icons.delete_sweep_outlined, color: Colors.red), SizedBox(width: 10), Expanded(child: Text('Vider les notifications'))]),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les notifications ?'),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          TextButton(child: const Text('Annuler'), onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
            child: const Text('Supprimer'),
            onPressed: () async {
              await DbHelper.clearAllNotifications();
              if (mounted) Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Toutes les notifications ont été supprimées.'), backgroundColor: Colors.green[700], behavior: SnackBarBehavior.floating),
              );
              _loadNotifications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.notifications), SizedBox(width: 8), Text('Notifications')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearAllDialog,
            tooltip: 'Tout supprimer',
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune notification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildNotificationCard(notification),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isSuccess = notification.type == 'success';
    final color = isSuccess ? Colors.green : Colors.blue;

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(color: Colors.red[700], borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: notification.isRead ? Colors.transparent : color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: () => _markAsRead(notification),
          leading: CircleAvatar(backgroundColor: notification.isRead ? Colors.grey[300] : color.withOpacity(0.2), child: Icon(Icons.notifications_active_outlined, color: notification.isRead ? Colors.grey[600] : color)),
          title: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(DateFormat('d MMM yyyy, HH:mm', 'fr_FR').format(notification.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
