import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/services/export_service.dart';
import 'package:snippet/services/gallery_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/gallery');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('fromSave keeps View only for a content URI on Android', () {
    expect(
      SavedGalleryImage.fromSave(android: false, contentUri: null)?.photosApp,
      isTrue,
    );
    final saved = SavedGalleryImage.fromSave(
      android: true,
      contentUri: 'content://media/external/images/media/3',
    );
    expect(saved?.uri, 'content://media/external/images/media/3');
    expect(saved?.canView, isTrue);
    expect(
      SavedGalleryImage.fromSave(
        android: true,
        contentUri: 'file:///tmp/card.png',
      ),
      isNull,
    );
    expect(SavedGalleryImage.fromSave(android: true, contentUri: null), isNull);
  });

  test('savePng returns a content URI and drops anything else', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      expect(call.method, 'savePng');
      expect(call.arguments['album'], 'Snippet');
      return calls == 1
          ? 'content://media/external/images/media/4'
          : 'file:///tmp/card.png';
    });
    const gallery = GalleryChannel(channel);

    expect(
      await gallery.savePng(
        Uint8List.fromList([1, 2, 3]),
        name: 'card',
        album: 'Snippet',
      ),
      'content://media/external/images/media/4',
    );
    expect(
      await gallery.savePng(
        Uint8List.fromList([1]),
        name: 'card',
        album: 'Snippet',
      ),
      isNull,
    );
  });

  test('view reports failure instead of throwing', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'viewImage');
      if (call.arguments['uri'] == 'content://ok') return true;
      throw PlatformException(code: 'NO_VIEWER');
    });
    const gallery = GalleryChannel(channel);

    expect(await gallery.view('file:///tmp/card.png'), isFalse);
    expect(await gallery.view('content://ok'), isTrue);
    expect(await gallery.view('content://missing'), isFalse);
  });

  test('opening Photos without the plugin does not throw', () async {
    const service = DeviceExportService();
    expect(
      await service.openSaved(const SavedGalleryImage.photosApp()),
      isFalse,
    );
  });
}
