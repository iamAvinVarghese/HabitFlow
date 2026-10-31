import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:habitflow/domain/providers/notification_providers.dart';

class BlinkingNotificationIcon extends ConsumerStatefulWidget {
  const BlinkingNotificationIcon({super.key});

  @override
  ConsumerState<BlinkingNotificationIcon> createState() => _BlinkingNotificationIconState();
}

class _BlinkingNotificationIconState extends ConsumerState<BlinkingNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showNotificationBottomSheet(BuildContext context) {
    // Mark notifications as read and refresh history
    ref.read(hasNewNotificationsProvider.notifier).markAsRead();
    ref.invalidate(notificationHistoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Consumer(
            builder: (context, ref, child) {
              final historyAsync = ref.watch(notificationHistoryProvider);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notification Center',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: hapticLight(() => Navigator.pop(context)),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  historyAsync.when(
                    data: (logs) {
                      if (logs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(Icons.notifications_off_rounded, color: Colors.white30, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'No notifications yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      }

                      return Expanded(
                        child: ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final title = log['title'] as String;
                            final time = log['time'] as DateTime;
                            final timeStr = DateFormat('jm').format(time);
                            final dateStr = DateFormat('MMM d').format(time);

                            IconData iconData = Icons.notifications_active_rounded;
                            final t = title.toLowerCase();
                            if (t.contains('morning')) {
                              iconData = Icons.wb_sunny_rounded;
                            } else if (t.contains('night')) {
                              iconData = Icons.bed_rounded;
                            } else if (t.contains('task')) {
                              iconData = Icons.check_circle_outline_rounded;
                            } else if (t.contains('habit')) {
                              iconData = Icons.repeat_rounded;
                            } else if (t.contains('focus') || t.contains('break')) {
                              iconData = Icons.timer_rounded;
                            }

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.white10,
                                child: Icon(iconData, color: Colors.white70, size: 20),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                log['body'] as String,
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                              trailing: Text(
                                '$dateStr\n$timeStr',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Text(
                        'Error loading notifications: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNew = ref.watch(hasNewNotificationsProvider);

    if (hasNew) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return IconButton(
          icon: Icon(
            Icons.notifications_rounded,
            color: hasNew
                ? Colors.white.withOpacity(_opacityAnimation.value)
                : Colors.white60,
          ),
          onPressed: hapticLight(() {
            _showNotificationBottomSheet(context);
          }),
          tooltip: 'Notifications',
        );
      },
    );
  }
}
