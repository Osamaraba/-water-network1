import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../services/notification_ws.dart';
import '../../models/notification.dart';
import '../../services/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationWsService.instance.stream.listen((data) {
      try {
        _prepend(AppNotification.fromJson(data));
      } catch (_) {}
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearUnread();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _load() async {
    try {
      final items = await NotificationService().getNotifications();
      if (mounted) {
        setState(() {
          _items = items
              .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prepend(AppNotification n) {
    if (!mounted) {
      return;
    }
    setState(() => _items.insert(0, n));
  }

  Future<void> _markRead(AppNotification n) async {
    final id = n.notificationId;
    if (n.isRead || id == null) return;
    try {
      await NotificationService().markRead(id);
      setState(() {
        final i = _items.indexWhere((e) => e.notificationId == id);
        if (i != -1) {
          _items[i] = AppNotification(
          notificationId: id,
          employeeId: n.employeeId,
          title: n.title,
          message: n.message,
          severity: n.severity,
          isRead: true,
          createdAt: n.createdAt,
        );
        }
      });
    } catch (_) {}
  }

  Future<void> _markAll() async {
    try {
      await NotificationService().markAllRead();
      setState(() => _items = _items
          .map((e) => AppNotification(
                notificationId: e.notificationId,
                employeeId: e.employeeId,
                title: e.title,
                message: e.message,
                severity: e.severity,
                isRead: true,
                createdAt: e.createdAt,
              ))
          .toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (_items.any((e) => !e.isRead))
            TextButton(
              onPressed: _markAll,
              child: const Text('تحديد الكل كمقروء',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                       Text('لا توجد إشعارات بعد',
                           style: TextStyle(color: Color(0xFF5C6B82), fontSize: 16)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final n = _items[index];
                    return Card(
                      color: n.isRead ? null : const Color(0xFFEAF1FB),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: n.severityColor.withValues(alpha: 0.15),
                          child: Icon(Icons.notifications, color: n.severityColor),
                        ),
                        title: Text(n.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.message,
                                  style: const TextStyle(fontSize: 13, height: 1.4)),
                              const SizedBox(height: 4),
                              Text(n.createdAt,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF5C6B82))),
                            ],
                          ),
                        ),
                        trailing: n.isRead
                            ? null
                            : const Icon(Icons.circle,
                                size: 10, color: Color(0xFF1E4D8C)),
                        onTap: () => _markRead(n),
                      ),
                    );
                  },
                ),
    );
  }
}
