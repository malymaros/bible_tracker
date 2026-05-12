// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'Bible Tracker';

  @override
  String get tabBiblia => 'Biblia';

  @override
  String get tabPlan => 'Plán';

  @override
  String get tabStatistika => 'Štatistika';

  @override
  String get screenBiblia => 'Biblia';

  @override
  String get screenPlan => 'Plán čítania';

  @override
  String get screenStatistika => 'Štatistika čítania';

  @override
  String get bibleStatusNotDownloaded => 'nestiahnuté';

  @override
  String get bibleStatusPartial => 'čiastočne stiahnuté';

  @override
  String get bibleStatusDownloading => 'sťahuje sa';

  @override
  String get bibleStatusDownloaded => 'stiahnuté';

  @override
  String get bibleStatusError => 'chyba';

  @override
  String get bibleDownloadBook => 'Stiahnuť knihu';

  @override
  String get bibleDeleteDownloadedText => 'Vymazať stiahnutý text';

  @override
  String get readerChapterNotDownloaded => 'Kapitola nie je stiahnutá';

  @override
  String get readerChapterLoadError => 'Kapitolu sa nepodarilo načítať';

  @override
  String get readerPreviousChapter => 'Predchádzajúca';

  @override
  String get readerNextChapter => 'Ďalšia';

  @override
  String get readerMarkRead => 'Označiť ako prečítané';

  @override
  String get readerMarkUnread => 'Označiť ako neprečítané';

  @override
  String get readerOpenSsv => 'Otvoriť na webe SSV';

  @override
  String get readerClose => 'Zavrieť';
}
