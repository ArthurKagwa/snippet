import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/app_settings.dart';
import 'package:snippet/data/json_store.dart';

class _MemoryStore implements JsonStore {
  final Map<String, Object?> docs = {};

  @override
  Future<Object?> read(String name) async => docs[name];

  @override
  Future<void> write(String name, Object? value) async => docs[name] = value;

  @override
  Future<void> delete(String name) async => docs.remove(name);
}

void main() {
  test('the export mark is on for a fresh install', () async {
    final settings = AppSettings(_MemoryStore());
    await settings.load();
    expect(settings.showMark, isTrue);
  });

  test('settings saved before version 2 turn the mark back on', () async {
    final store = _MemoryStore()..docs['settings'] = {'showMark': false};
    final settings = AppSettings(store);
    await settings.load();
    expect(settings.showMark, isTrue);
  });

  test('turning the mark off sticks after the migration', () async {
    final store = _MemoryStore();
    AppSettings(store).showMark = false;
    final reloaded = AppSettings(store);
    await reloaded.load();
    expect(reloaded.showMark, isFalse);
  });

  test('HD export is on for a fresh install', () async {
    final settings = AppSettings(_MemoryStore());
    await settings.load();
    expect(settings.hdExport, isTrue);
  });

  test('settings saved before version 3 turn HD on', () async {
    final store = _MemoryStore()
      ..docs['settings'] = {'version': 2, 'hdExport': false, 'showMark': false};
    final settings = AppSettings(store);
    await settings.load();
    expect(settings.hdExport, isTrue);
    expect(settings.showMark, isFalse);
  });

  test('choosing HD before version 3 stays on', () async {
    final store = _MemoryStore()
      ..docs['settings'] = {'version': 2, 'hdExport': true};
    final settings = AppSettings(store);
    await settings.load();
    expect(settings.hdExport, isTrue);
  });

  test('turning HD off sticks after the migration', () async {
    final store = _MemoryStore();
    AppSettings(store).hdExport = false;
    final reloaded = AppSettings(store);
    await reloaded.load();
    expect(reloaded.hdExport, isFalse);
  });
}
