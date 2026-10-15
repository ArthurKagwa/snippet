import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Tiny named-document store for app state (library, settings).
abstract class JsonStore {
  Future<Object?> read(String name);
  Future<void> write(String name, Object? value);
  Future<void> delete(String name);
}

/// One JSON file per document in the app documents directory.
class FileJsonStore implements JsonStore {
  FileJsonStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file(String name) async =>
      File('${(await _directory()).path}/snippet_$name.json');

  @override
  Future<Object?> read(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return null;
      return jsonDecode(await f.readAsString());
    } on FormatException {
      return null; // corrupt file: start fresh rather than crash
    }
  }

  @override
  Future<void> write(String name, Object? value) async {
    final f = await _file(name);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(value), flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<void> delete(String name) async {
    final f = await _file(name);
    if (await f.exists()) await f.delete();
  }
}

/// In-memory store for tests.
class MemoryJsonStore implements JsonStore {
  final Map<String, String> _docs = {};

  @override
  Future<Object?> read(String name) async {
    final raw = _docs[name];
    return raw == null ? null : jsonDecode(raw);
  }

  @override
  Future<void> write(String name, Object? value) async =>
      _docs[name] = jsonEncode(value);

  @override
  Future<void> delete(String name) async => _docs.remove(name);
}
