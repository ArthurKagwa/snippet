import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/services/android_update_policy.dart';
import 'package:snippet/services/firebase_content_config_service.dart';
import 'package:snippet/services/play_listing.dart';
import 'package:snippet/services/play_update.dart';

void main() {
  group('parseMinAndroidBuild', () {
    test('accepts a Play version code', () {
      expect(parseMinAndroidBuild('14'), 14);
      expect(parseMinAndroidBuild(' 2100000000 '), 2100000000);
      expect(parseMinAndroidBuild('1'), 1);
    });

    test('rejects empty, zero, and malformed values', () {
      for (final raw in [
        '',
        '   ',
        '0',
        '-1',
        '+14',
        '014',
        '14.0',
        '1.0.7',
        '14abc',
        '1e2',
        '2100000001',
        '999999999999999999999',
      ]) {
        expect(parseMinAndroidBuild(raw), isNull, reason: raw);
      }
    });
  });

  group('update copy', () {
    test('uses the built-in copy when the value is blank or unsuitable', () {
      expect(parseAndroidUpdateTitle('  '), AndroidUpdatePolicy.defaultTitle);
      expect(
        parseAndroidUpdateTitle('Update\nnow'),
        AndroidUpdatePolicy.defaultTitle,
      );
      expect(
        parseAndroidUpdateTitle('x' * 81),
        AndroidUpdatePolicy.defaultTitle,
      );
      expect(parseAndroidUpdateMessage(''), AndroidUpdatePolicy.defaultMessage);
      expect(
        parseAndroidUpdateMessage('Line\nwith a bell \u0007'),
        AndroidUpdatePolicy.defaultMessage,
      );
      expect(
        parseAndroidUpdateMessage('y' * 401),
        AndroidUpdatePolicy.defaultMessage,
      );
    });

    test('keeps a clear title and message', () {
      expect(parseAndroidUpdateTitle(' Please update '), 'Please update');
      expect(
        parseAndroidUpdateMessage('A newer build\nis on Google Play.'),
        'A newer build\nis on Google Play.',
      );
    });
  });

  group('AndroidUpdatePolicy.blocks', () {
    const policy = AndroidUpdatePolicy(minBuild: 14);

    test('blocks only a known build below the minimum', () {
      expect(policy.blocks(13), isTrue);
      expect(policy.blocks(14), isFalse);
      expect(policy.blocks(15), isFalse);
      expect(policy.blocks(null), isFalse);
      expect(const AndroidUpdatePolicy().blocks(1), isFalse);
    });
  });

  test('bad minimum in remote content does not block', () {
    final policy = parseRemoteContent(
      verseCalendarJson: '{}',
      announcement: '',
      minAndroidBuild: 'soon',
      androidUpdateTitle: 'Go to https://evil.example',
      androidUpdateMessage: '',
    ).androidUpdate;
    expect(policy.minBuild, isNull);
    expect(policy.blocks(1), isFalse);
    expect(policy.title, 'Go to https://evil.example');
    expect(policy.message, AndroidUpdatePolicy.defaultMessage);
  });

  test('a valid minimum keeps the remote copy', () {
    final policy = parseRemoteContent(
      verseCalendarJson: 'not json',
      announcement: '',
      minAndroidBuild: '20',
      androidUpdateTitle: 'Please update',
      androidUpdateMessage: 'A newer Snippet is on Google Play.',
    ).androidUpdate;
    expect(policy.minBuild, 20);
    expect(policy.blocks(19), isTrue);
    expect(policy.blocks(20), isFalse);
    expect(policy.title, 'Please update');
    expect(policy.message, 'A newer Snippet is on Google Play.');
  });

  group('isSnippetPlayListing', () {
    test('accepts only this app listing', () {
      expect(isSnippetPlayListing(snippetPlayMarketUri), isTrue);
      expect(isSnippetPlayListing(snippetPlayHttpsUri), isTrue);
      expect(
        isSnippetPlayListing(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.arthur.snippet',
          ),
        ),
        isTrue,
      );
    });

    test('rejects other apps and other schemes', () {
      for (final raw in [
        'https://play.google.com/store/apps/details?id=com.other.app',
        'http://play.google.com/store/apps/details?id=com.arthur.snippet',
        'https://play.google.com/store/apps/details?id=com.arthur.snippet&url=https://evil.example',
        'https://evil.example/store/apps/details?id=com.arthur.snippet',
        'market://details?id=com.other.app',
        'market://launch?id=com.arthur.snippet',
        'intent://details?id=com.arthur.snippet#Intent;scheme=market;end',
        'https://user@play.google.com/store/apps/details?id=com.arthur.snippet',
      ]) {
        expect(isSnippetPlayListing(Uri.parse(raw)), isFalse, reason: raw);
      }
    });
  });

  test('the listing opener only tries this app', () async {
    final opened = <Uri>[];
    final ok = await openSnippetPlayListing(
      launch: (uri) async {
        opened.add(uri);
        return uri == snippetPlayHttpsUri;
      },
    );
    expect(ok, isTrue);
    expect(opened, [snippetPlayMarketUri, snippetPlayHttpsUri]);
    expect(opened.every(isSnippetPlayListing), isTrue);
  });

  test('a failed listing opener does not throw', () async {
    expect(await openSnippetPlayListing(launch: (uri) async => false), isFalse);
  });

  group('requestAndroidUpdate', () {
    test(
      'does not open the store when Play shows the immediate flow',
      () async {
        for (final status in [
          ImmediateUpdateStatus.completed,
          ImmediateUpdateStatus.cancelled,
        ]) {
          final flow = _Flow(status);
          final listing = _Listing();
          expect(
            await requestAndroidUpdate(flow: flow, listing: listing),
            UpdateAttempt.play,
          );
          expect(listing.opens, 0);
          expect(flow.starts, 1);
        }
      },
    );

    test('opens the store when Play has no immediate update', () async {
      for (final status in [
        ImmediateUpdateStatus.unavailable,
        ImmediateUpdateStatus.failed,
      ]) {
        final listing = _Listing();
        expect(
          await requestAndroidUpdate(flow: _Flow(status), listing: listing),
          UpdateAttempt.store,
        );
        expect(listing.opens, 1);
      }
    });

    test('opens the store when the immediate call throws', () async {
      final listing = _Listing();
      expect(
        await requestAndroidUpdate(flow: _Flow.throwing(), listing: listing),
        UpdateAttempt.store,
      );
      expect(listing.opens, 1);
    });

    test('stays failed when the store does not open', () async {
      final listing = _Listing()..result = false;
      expect(
        await requestAndroidUpdate(
          flow: _Flow(ImmediateUpdateStatus.unavailable),
          listing: listing,
        ),
        UpdateAttempt.failed,
      );
    });
  });
}

class _Flow implements AndroidUpdateFlow {
  _Flow(this.status) : throws = false;
  _Flow.throwing() : status = ImmediateUpdateStatus.failed, throws = true;

  final ImmediateUpdateStatus status;
  final bool throws;
  var starts = 0;

  @override
  Future<ImmediateUpdateStatus> startImmediate() async {
    starts++;
    if (throws) throw StateError('play down');
    return status;
  }

  @override
  Future<void> resumeInProgress() async {}
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
