import 'package:snippet/services/content_config_service.dart';

/// A calendar cycling through [verses] for [days] days around [from].
Map<String, FeaturedVerse> rotatingCalendar(
  List<FeaturedVerse> verses, {
  required DateTime from,
  int days = 60,
}) => {
  if (verses.isNotEmpty)
    for (var i = -days; i < days; i++)
      localDateKey(DateTime(from.year, from.month, from.day + i)):
          verses[(i % verses.length + verses.length) % verses.length],
};

class CalendarContent implements ContentConfigService {
  const CalendarContent(this.calendar);

  final Map<String, FeaturedVerse> calendar;

  @override
  Future<ContentConfig> load() async => ContentConfig(verseCalendar: calendar);
}
