import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/services.dart';
import '../../services/verse_reminder_service.dart';

/// Refreshes retained Home state on resume, local midnight, and reminder taps.
class DailyVerseListener extends StatefulWidget {
  const DailyVerseListener({
    super.key,
    required this.onRefresh,
    required this.onNotification,
    required this.child,
  });

  final VoidCallback onRefresh;
  final ValueChanged<ReminderVerse?> onNotification;
  final Widget child;

  @override
  State<DailyVerseListener> createState() => _DailyVerseListenerState();
}

class _DailyVerseListenerState extends State<DailyVerseListener>
    with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<ReminderVerse?>? _opens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => widget.onRefresh(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _opens ??= Services.of(context).reminders.notificationOpens.listen(
      (verse) => widget.onNotification(verse),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _opens?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
