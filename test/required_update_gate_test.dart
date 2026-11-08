import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/app.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/features/shell/app_shell.dart';
import 'package:snippet/services/android_update_policy.dart';
import 'package:snippet/services/content_config_service.dart';
import 'package:snippet/services/play_listing.dart';
import 'package:snippet/services/play_update.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<MemoryJsonStore> boot(
    WidgetTester tester, {
    required _Config config,
    required int? build,
    bool enforce = true,
    _Flow? flow,
    _Listing? listing,
  }) async {
    final store = MemoryJsonStore();
    await store.write('kept', {'verse': 'PSA 46:10'});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SnippetApp(
        key: UniqueKey(),
        store: store,
        contentConfig: config,
        enforceAndroidUpdate: enforce,
        androidBuild: _Build(build),
        updateFlow: flow ?? _Flow(ImmediateUpdateStatus.unavailable),
        playListing: listing ?? _Listing(),
      ),
    );
    await settle(tester);
    return store;
  }

  testWidgets('a build below the minimum cannot reach the app', (tester) async {
    final store = await boot(
      tester,
      config: _Config(_policy(14, title: 'Please update')),
      build: 13,
    );

    expect(find.byKey(const Key('required-update')), findsOneWidget);
    expect(find.text('Please update'), findsOneWidget);
    expect(find.text(AndroidUpdatePolicy.defaultMessage), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Not now'), findsNothing);
    expect(find.text('Later'), findsNothing);
    expect(find.byType(AppShell), findsNothing);
    expect(find.byKey(const Key('nav-styles')), findsNothing);
    expect(await store.read('kept'), {'verse': 'PSA 46:10'});

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(await navigator.maybePop(), isTrue);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('required-update')), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(await store.read('kept'), {'verse': 'PSA 46:10'});
  });

  testWidgets('the current and newer builds are allowed', (tester) async {
    for (final build in [14, 15]) {
      await boot(tester, config: _Config(_policy(14)), build: build);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byKey(const Key('required-update')), findsNothing);
    }
  });

  testWidgets('no minimum, a bad minimum, or an unknown build stays open', (
    tester,
  ) async {
    await boot(tester, config: _Config(AndroidUpdatePolicy.none), build: 1);
    expect(find.byType(AppShell), findsOneWidget);

    await boot(
      tester,
      config: _Config(parseAndroidUpdatePolicy(minAndroidBuild: 'soon')),
      build: 1,
    );
    expect(find.byType(AppShell), findsOneWidget);

    await boot(tester, config: _Config(_policy(14)), build: null);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('a failed config read does not invent a requirement', (
    tester,
  ) async {
    final config = _Config(_policy(99))..loadError = Exception('offline');
    await boot(tester, config: config, build: 1);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byKey(const Key('required-update')), findsNothing);
  });

  testWidgets('other platforms ignore the Android minimum', (tester) async {
    await boot(tester, config: _Config(_policy(100)), build: 1, enforce: false);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byKey(const Key('required-update')), findsNothing);
  });

  testWidgets('Update opens the store when Play has no immediate update', (
    tester,
  ) async {
    final flow = _Flow(ImmediateUpdateStatus.unavailable);
    final listing = _Listing();
    await boot(
      tester,
      config: _Config(_policy(14)),
      build: 13,
      flow: flow,
      listing: listing,
    );

    await tester.tap(find.byKey(const Key('required-update-button')));
    await tester.pumpAndSettle();

    expect(flow.starts, 1);
    expect(listing.opens, 1);
    expect(find.byKey(const Key('required-update')), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('cancelling an immediate update does not open the store', (
    tester,
  ) async {
    final listing = _Listing();
    await boot(
      tester,
      config: _Config(_policy(14)),
      build: 13,
      flow: _Flow(ImmediateUpdateStatus.cancelled),
      listing: listing,
    );

    await tester.tap(find.byKey(const Key('required-update-button')));
    await tester.pumpAndSettle();

    expect(listing.opens, 0);
    expect(find.byKey(const Key('required-update')), findsOneWidget);
    expect(find.byKey(const Key('required-update-error')), findsNothing);
  });

  testWidgets('a store failure stays on the screen', (tester) async {
    final listing = _Listing()..result = false;
    await boot(
      tester,
      config: _Config(_policy(14)),
      build: 13,
      listing: listing,
    );

    await tester.tap(find.byKey(const Key('required-update-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('required-update-error')), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('resume rechecks and leaves when the build is allowed', (
    tester,
  ) async {
    final config = _Config(_policy(14));
    final build = _Build(13);
    final flow = _Flow(ImmediateUpdateStatus.unavailable);
    final store = MemoryJsonStore();
    await store.write('kept', {'verse': 'PSA 46:10'});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SnippetApp(
        store: store,
        contentConfig: config,
        enforceAndroidUpdate: true,
        androidBuild: build,
        updateFlow: flow,
        playListing: _Listing(),
      ),
    );
    await settle(tester);
    expect(find.byKey(const Key('required-update')), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(config.refreshes, greaterThan(0));
    expect(flow.resumes, 1);
    expect(find.byKey(const Key('required-update')), findsOneWidget);

    build.code = 14;
    config.config = ContentConfig(
      androidUpdate: const AndroidUpdatePolicy(minBuild: 14),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byKey(const Key('required-update')), findsNothing);
    expect(await store.read('kept'), {'verse': 'PSA 46:10'});
  });

  testWidgets('a failed recheck does not lift a real requirement', (
    tester,
  ) async {
    final config = _Config(_policy(14));
    await boot(tester, config: config, build: 13);
    config.refreshError = Exception('offline');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(find.byKey(const Key('required-update')), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });
}

AndroidUpdatePolicy _policy(int minBuild, {String? title}) {
  return AndroidUpdatePolicy(
    minBuild: minBuild,
    title: title ?? AndroidUpdatePolicy.defaultTitle,
  );
}

class _Config implements ContentConfigService {
  _Config(AndroidUpdatePolicy policy)
    : config = ContentConfig(androidUpdate: policy);

  ContentConfig config;
  Object? loadError;
  Object? refreshError;
  var refreshes = 0;

  @override
  Future<ContentConfig> load() async {
    final error = loadError;
    if (error != null) throw error;
    return config;
  }

  @override
  Future<ContentConfig> refresh() async {
    refreshes++;
    final error = refreshError;
    if (error != null) throw error;
    return config;
  }
}

class _Build implements AndroidBuildReader {
  _Build(this.code);
  int? code;

  @override
  Future<int?> readVersionCode() async => code;
}

class _Flow implements AndroidUpdateFlow {
  _Flow(this.status);
  final ImmediateUpdateStatus status;
  var starts = 0;
  var resumes = 0;

  @override
  Future<ImmediateUpdateStatus> startImmediate() async {
    starts++;
    return status;
  }

  @override
  Future<void> resumeInProgress() async {
    resumes++;
  }
}

class _Listing implements PlayListing {
  var opens = 0;
  var result = true;

  @override
  Future<bool> open() async {
    opens++;
    return result;
  }
}
