import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';

/// An employee's notifications — new job posts and edits to jobs they're on.
class NotificationsPage extends StatefulWidget {
  final AuthResult session;
  const NotificationsPage({required this.session, super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.getMyNotifications(token: widget.session.token, employeeId: widget.session.userId);
  }

  Future<void> _refresh() async {
    final future = ApiClient.getMyNotifications(
      token: widget.session.token,
      employeeId: widget.session.userId,
    );
    setState(() => _future = future);
    await future;
  }

  Future<void> _markAllRead() async {
    await ApiClient.markAllNotificationsRead(token: widget.session.token, employeeId: widget.session.userId);
    if (mounted) await _refresh();
  }

  Future<void> _tapNotification(AppNotification notification) async {
    if (!notification.read) {
      await ApiClient.markNotificationRead(
        token: widget.session.token,
        employeeId: widget.session.userId,
        notificationId: notification.id,
      );
      if (mounted) _refresh();
    }
  }

  String _relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: FCircularProgress());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(snapshot.error.toString(), style: TextStyle(color: colors.error)),
              ),
            );
          }

          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No notifications yet.',
                      textAlign: TextAlign.center,
                      style: typography.body.sm.copyWith(color: colors.mutedForeground),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => FDivider(style: .delta(color: colors.border)),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _tapNotification(notification),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!notification.read)
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 10),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                            )
                          else
                            const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.message,
                                  style: typography.body.sm.copyWith(
                                    fontWeight: notification.read ? FontWeight.w400 : FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _relativeTime(notification.createdAt),
                                  style: typography.body.xs.copyWith(color: colors.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
