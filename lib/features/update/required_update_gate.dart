import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../services/android_update_policy.dart';
import '../../services/play_listing.dart';
import '../../services/play_update.dart';
import '../../services/services.dart';
import 'required_update_screen.dart';

enum _Phase { checking, open, blocked }

/// Shows [child] unless this Android build is below the Remote Config minimum.
///
/// While the check is running the app is not shown, so a slow fetch cannot
/// flash the home screen. A missing, offline or unreadable config does not
/// invent a requirement. Back from the blocked screen does not open the app.
class RequiredUpdateGate extends StatefulWidget {
  const RequiredUpdateGate({
    super.key,
    required this.child,
    required this.androidBuild,
    required this.updateFlow,
    required this.playListing,
    this.enforce,
  });

  final Widget child;
  final AndroidBuildReader androidBuild;
  final AndroidUpdateFlow updateFlow;
  final PlayListing playListing;

  /// When null, only Android enforces the minimum. Tests pass true or false.
  final bool? enforce;

  @override
  State<RequiredUpdateGate> createState() => _RequiredUpdateGateState();
}

class _RequiredUpdateGateState extends State<RequiredUpdateGate>
    with WidgetsBindingObserver {
  _Phase _phase = _Phase.checking;
  AndroidUpdatePolicy _policy = AndroidUpdatePolicy.none;
  var _storeFailed = false;
  var _updating = false;
  var _ticket = 0;

  bool get _enforce {
    final override = widget.enforce;
    if (override != null) return override;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    // Widget tests set FLUTTER_TEST, which makes [defaultTargetPlatform]
    // Android. The test binding is not the app's binding, so those tests
    // stay on the normal UI unless they pass enforce: true.
    var widgetTest = false;
    assert(() {
      widgetTest = WidgetsBinding.instance is! WidgetsFlutterBinding;
      return true;
    }());
    return !widgetTest;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_enforce) {
      _phase = _Phase.open;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_evaluate(refresh: false));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_enforce) return;
    unawaited(_recheckAfterResume());
  }

  Future<void> _recheckAfterResume() async {
    final wasBlocked = _phase == _Phase.blocked;
    await _evaluate(refresh: true);
    if (!mounted || !wasBlocked || _phase != _Phase.blocked || _updating) {
      return;
    }
    await widget.updateFlow.resumeInProgress();
  }

  Future<void> _evaluate({required bool refresh}) async {
    if (!mounted) return;
    final ticket = ++_ticket;
    final service = Services.of(context).contentConfig;
    final AndroidUpdatePolicy policy;
    final int? build;
    try {
      final config = refresh ? await service.refresh() : await service.load();
      build = await widget.androidBuild.readVersionCode();
      policy = config.androidUpdate;
    } catch (e) {
      debugPrint('Update check failed: $e');
      if (!mounted || ticket != _ticket) return;
      // A failed first read must not block. A failed recheck keeps the
      // last real decision, so a blip neither invents nor lifts a requirement.
      if (!refresh) setState(() => _phase = _Phase.open);
      return;
    }
    if (!mounted || ticket != _ticket) return;
    final blocked = _enforce && policy.blocks(build);
    setState(() {
      _policy = policy;
      _phase = blocked ? _Phase.blocked : _Phase.open;
      if (!blocked) _storeFailed = false;
    });
  }

  Future<void> _onUpdate() async {
    if (_updating) return;
    _updating = true;
    try {
      final attempt = await requestAndroidUpdate(
        flow: widget.updateFlow,
        listing: widget.playListing,
      );
      if (!mounted) return;
      setState(() => _storeFailed = attempt == UpdateAttempt.failed);
      await _evaluate(refresh: true);
    } finally {
      _updating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_enforce || _phase == _Phase.open) return widget.child;
    if (_phase == _Phase.checking) {
      return PopScope(
        canPop: false,
        child: ColoredBox(color: context.colors.black),
      );
    }
    return RequiredUpdateScreen(
      title: _policy.title,
      message: _policy.message,
      storeFailed: _storeFailed,
      onUpdate: _onUpdate,
    );
  }
}
