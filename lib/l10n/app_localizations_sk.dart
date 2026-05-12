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

  @override
  String get planCreateTitle => 'Vytvoriť plán čítania';

  @override
  String get planStartDate => 'Začiatok';

  @override
  String get planTotalDays => 'Počet dní';

  @override
  String get planIncludedBooks => 'Zahrnuté knihy';

  @override
  String get planSelectedChapters => 'Vybrané kapitoly';

  @override
  String get planDateRange => 'Rozsah dátumov';

  @override
  String get planDateRangeUnavailable => 'nedostupné';

  @override
  String get planCreateAction => 'Vytvoriť plán';

  @override
  String get planInvalidDayCount => 'Zadajte platný počet dní';

  @override
  String get planTooManyDays =>
      'Počet dní nemôže byť väčší ako počet vybraných kapitol';

  @override
  String get planSelectAtLeastOneBook => 'Vyberte aspoň jednu knihu';

  @override
  String get planTodayReading => 'Dnešné čítanie';

  @override
  String get planNoReadingToday => 'Na dnes nie je naplánované čítanie';

  @override
  String get planSchedule => 'Rozpis';

  @override
  String get planDay => 'Deň';

  @override
  String get planToday => 'dnes';

  @override
  String get planChapterCompleted => 'prečítané';

  @override
  String get planChapterIncomplete => 'neprečítané';

  @override
  String get planDeleteAction => 'Vymazať plán';

  @override
  String get planDeleteTitle => 'Vymazať plán?';

  @override
  String get planDeleteMessage =>
      'Rozpis čítania bude odstránený. Prečítané kapitoly zostanú zachované.';

  @override
  String get planCancel => 'Zrušiť';

  @override
  String get planAhead => 'V predstihu';

  @override
  String get planBehind => 'V sklze';

  @override
  String get planOnTrack => 'Podľa plánu';

  @override
  String get planCompletedChapters => 'Prečítané kapitoly';

  @override
  String get planExpectedByToday => 'Očakávané do dnes';

  @override
  String get planAheadBehind => 'Predstih/sklz';

  @override
  String get planCompletionPercent => 'Dokončenie';

  @override
  String get statsNoPlan => 'Najprv si vytvorte plán čítania.';

  @override
  String get statsPlanProgressTitle => 'Pokrok v aktuálnom pláne';

  @override
  String get statsRemainingPlanChapters => 'Zostávajúce kapitoly v pláne';

  @override
  String get statsPlanStatus => 'Stav plánu';

  @override
  String get statsTestamentsTitle => 'Starý a Nový zákon v pláne';

  @override
  String get statsOldTestamentInPlan => 'Starý zákon v aktuálnom pláne';

  @override
  String get statsNewTestamentInPlan => 'Nový zákon v aktuálnom pláne';

  @override
  String get statsDeuterocanonicalInPlan => 'Deuterokánonické knihy v pláne';

  @override
  String get statsBooksTitle => 'Knihy v aktuálnom pláne';

  @override
  String get statsCompletedBooksInPlan => 'Dokončené knihy v pláne';

  @override
  String get statsRemainingBooksInPlan => 'Zostávajúce knihy v pláne';

  @override
  String get statsFullyCompletedSelectedBooks =>
      'Úplne dokončené vybrané knihy';

  @override
  String get statsNotStartedSelectedBooks => 'Nezačaté vybrané knihy';

  @override
  String get statsTodaySummary => 'Dnešné čítanie v pláne';
}
