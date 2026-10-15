/// Immutable models for bundled Bible text.
class Book {
  const Book({required this.id, required this.name, required this.chapters});

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    name: json['name'] as String,
    chapters: [
      for (final c in json['chapters'] as List<dynamic>)
        [for (final v in c as List<dynamic>) v as String],
    ],
  );

  final String id;
  final String name;

  /// chapters[chapterIndex][verseIndex]; numbers are index + 1.
  /// An empty string means the verse is absent in this translation.
  final List<List<String>> chapters;

  int get chapterCount => chapters.length;

  int verseCount(int chapter) => chapters[chapter - 1].length;
}

class Translation {
  const Translation({
    required this.id,
    required this.name,
    required this.license,
    required this.books,
  });

  factory Translation.fromJson(Map<String, dynamic> json) => Translation(
    id: json['id'] as String,
    name: json['name'] as String,
    license: json['license'] as String,
    books: [
      for (final b in json['books'] as List<dynamic>)
        Book.fromJson(b as Map<String, dynamic>),
    ],
  );

  final String id;
  final String name;
  final String license;
  final List<Book> books;

  Book? bookById(String id) {
    for (final b in books) {
      if (b.id == id) return b;
    }
    return null;
  }
}

/// A contiguous range of verses inside one chapter.
class VerseRange {
  const VerseRange({
    required this.bookId,
    required this.chapter,
    required this.startVerse,
    int? endVerse,
  }) : endVerse = endVerse ?? startVerse;

  final String bookId;
  final int chapter;
  final int startVerse;
  final int endVerse;

  VerseRange copyWith({
    String? bookId,
    int? chapter,
    int? startVerse,
    int? endVerse,
  }) => VerseRange(
    bookId: bookId ?? this.bookId,
    chapter: chapter ?? this.chapter,
    startVerse: startVerse ?? this.startVerse,
    endVerse: endVerse ?? this.endVerse,
  );

  @override
  bool operator ==(Object other) =>
      other is VerseRange &&
      other.bookId == bookId &&
      other.chapter == chapter &&
      other.startVerse == startVerse &&
      other.endVerse == endVerse;

  @override
  int get hashCode => Object.hash(bookId, chapter, startVerse, endVerse);
}

/// Resolved passage ready to display.
class Passage {
  const Passage({
    required this.range,
    required this.reference,
    required this.text,
    required this.translationId,
  });

  final VerseRange range;

  /// e.g. "John 3:16" or "Psalm 23:1–3".
  final String reference;
  final String text;
  final String translationId;
}
