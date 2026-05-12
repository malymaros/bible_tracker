import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_sk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('sk')];

  /// Application title shown in the OS task switcher
  ///
  /// In sk, this message translates to:
  /// **'Bible Tracker'**
  String get appTitle;

  /// Label for the Bible browser tab
  ///
  /// In sk, this message translates to:
  /// **'Biblia'**
  String get tabBiblia;

  /// Label for the reading plan tab
  ///
  /// In sk, this message translates to:
  /// **'Plán'**
  String get tabPlan;

  /// Label for the statistics tab
  ///
  /// In sk, this message translates to:
  /// **'Štatistika'**
  String get tabStatistika;

  /// Heading shown on the Bible browser placeholder screen
  ///
  /// In sk, this message translates to:
  /// **'Biblia'**
  String get screenBiblia;

  /// Heading shown on the reading plan placeholder screen
  ///
  /// In sk, this message translates to:
  /// **'Plán čítania'**
  String get screenPlan;

  /// Heading shown on the statistics placeholder screen
  ///
  /// In sk, this message translates to:
  /// **'Štatistika čítania'**
  String get screenStatistika;

  /// Book text has not been downloaded
  ///
  /// In sk, this message translates to:
  /// **'nestiahnuté'**
  String get bibleStatusNotDownloaded;

  /// Only some chapters of a book are downloaded
  ///
  /// In sk, this message translates to:
  /// **'čiastočne stiahnuté'**
  String get bibleStatusPartial;

  /// A book is currently downloading
  ///
  /// In sk, this message translates to:
  /// **'sťahuje sa'**
  String get bibleStatusDownloading;

  /// All chapters of a book are downloaded
  ///
  /// In sk, this message translates to:
  /// **'stiahnuté'**
  String get bibleStatusDownloaded;

  /// Book download failed
  ///
  /// In sk, this message translates to:
  /// **'chyba'**
  String get bibleStatusError;

  /// Action to download all chapters of a book
  ///
  /// In sk, this message translates to:
  /// **'Stiahnuť knihu'**
  String get bibleDownloadBook;

  /// Action to delete cached book text
  ///
  /// In sk, this message translates to:
  /// **'Vymazať stiahnutý text'**
  String get bibleDeleteDownloadedText;

  /// Offline reader state when chapter text is missing
  ///
  /// In sk, this message translates to:
  /// **'Kapitola nie je stiahnutá'**
  String get readerChapterNotDownloaded;

  /// Offline reader state when local chapter loading fails
  ///
  /// In sk, this message translates to:
  /// **'Kapitolu sa nepodarilo načítať'**
  String get readerChapterLoadError;

  /// Reader previous chapter button label
  ///
  /// In sk, this message translates to:
  /// **'Predchádzajúca'**
  String get readerPreviousChapter;

  /// Reader next chapter button label
  ///
  /// In sk, this message translates to:
  /// **'Ďalšia'**
  String get readerNextChapter;

  /// Reader action to mark the current chapter as read
  ///
  /// In sk, this message translates to:
  /// **'Označiť ako prečítané'**
  String get readerMarkRead;

  /// Reader action to mark the current chapter as unread
  ///
  /// In sk, this message translates to:
  /// **'Označiť ako neprečítané'**
  String get readerMarkUnread;

  /// Reader action to open the chapter on the SSV website
  ///
  /// In sk, this message translates to:
  /// **'Otvoriť na webe SSV'**
  String get readerOpenSsv;

  /// Generic close button
  ///
  /// In sk, this message translates to:
  /// **'Zavrieť'**
  String get readerClose;

  /// No description provided for @planCreateTitle.
  ///
  /// In sk, this message translates to:
  /// **'Vytvoriť plán čítania'**
  String get planCreateTitle;

  /// No description provided for @planStartDate.
  ///
  /// In sk, this message translates to:
  /// **'Začiatok'**
  String get planStartDate;

  /// No description provided for @planTotalDays.
  ///
  /// In sk, this message translates to:
  /// **'Počet dní'**
  String get planTotalDays;

  /// No description provided for @planIncludedBooks.
  ///
  /// In sk, this message translates to:
  /// **'Zahrnuté knihy'**
  String get planIncludedBooks;

  /// No description provided for @planSelectedChapters.
  ///
  /// In sk, this message translates to:
  /// **'Vybrané kapitoly'**
  String get planSelectedChapters;

  /// No description provided for @planDateRange.
  ///
  /// In sk, this message translates to:
  /// **'Rozsah dátumov'**
  String get planDateRange;

  /// No description provided for @planDateRangeUnavailable.
  ///
  /// In sk, this message translates to:
  /// **'nedostupné'**
  String get planDateRangeUnavailable;

  /// No description provided for @planCreateAction.
  ///
  /// In sk, this message translates to:
  /// **'Vytvoriť plán'**
  String get planCreateAction;

  /// No description provided for @planInvalidDayCount.
  ///
  /// In sk, this message translates to:
  /// **'Zadajte platný počet dní'**
  String get planInvalidDayCount;

  /// No description provided for @planTooManyDays.
  ///
  /// In sk, this message translates to:
  /// **'Počet dní nemôže byť väčší ako počet vybraných kapitol'**
  String get planTooManyDays;

  /// No description provided for @planSelectAtLeastOneBook.
  ///
  /// In sk, this message translates to:
  /// **'Vyberte aspoň jednu knihu'**
  String get planSelectAtLeastOneBook;

  /// No description provided for @planTodayReading.
  ///
  /// In sk, this message translates to:
  /// **'Dnešné čítanie'**
  String get planTodayReading;

  /// No description provided for @planNoReadingToday.
  ///
  /// In sk, this message translates to:
  /// **'Na dnes nie je naplánované čítanie'**
  String get planNoReadingToday;

  /// No description provided for @planSchedule.
  ///
  /// In sk, this message translates to:
  /// **'Rozpis'**
  String get planSchedule;

  /// No description provided for @planDay.
  ///
  /// In sk, this message translates to:
  /// **'Deň'**
  String get planDay;

  /// No description provided for @planToday.
  ///
  /// In sk, this message translates to:
  /// **'dnes'**
  String get planToday;

  /// No description provided for @planChapterCompleted.
  ///
  /// In sk, this message translates to:
  /// **'prečítané'**
  String get planChapterCompleted;

  /// No description provided for @planChapterIncomplete.
  ///
  /// In sk, this message translates to:
  /// **'neprečítané'**
  String get planChapterIncomplete;

  /// No description provided for @planDeleteAction.
  ///
  /// In sk, this message translates to:
  /// **'Vymazať plán'**
  String get planDeleteAction;

  /// No description provided for @planDeleteTitle.
  ///
  /// In sk, this message translates to:
  /// **'Vymazať plán?'**
  String get planDeleteTitle;

  /// No description provided for @planDeleteMessage.
  ///
  /// In sk, this message translates to:
  /// **'Rozpis čítania bude odstránený. Prečítané kapitoly zostanú zachované.'**
  String get planDeleteMessage;

  /// No description provided for @planCancel.
  ///
  /// In sk, this message translates to:
  /// **'Zrušiť'**
  String get planCancel;

  /// No description provided for @planAhead.
  ///
  /// In sk, this message translates to:
  /// **'V predstihu'**
  String get planAhead;

  /// No description provided for @planBehind.
  ///
  /// In sk, this message translates to:
  /// **'V sklze'**
  String get planBehind;

  /// No description provided for @planOnTrack.
  ///
  /// In sk, this message translates to:
  /// **'Podľa plánu'**
  String get planOnTrack;

  /// No description provided for @planCompletedChapters.
  ///
  /// In sk, this message translates to:
  /// **'Prečítané kapitoly'**
  String get planCompletedChapters;

  /// No description provided for @planExpectedByToday.
  ///
  /// In sk, this message translates to:
  /// **'Očakávané do dnes'**
  String get planExpectedByToday;

  /// No description provided for @planAheadBehind.
  ///
  /// In sk, this message translates to:
  /// **'Predstih/sklz'**
  String get planAheadBehind;

  /// No description provided for @planCompletionPercent.
  ///
  /// In sk, this message translates to:
  /// **'Dokončenie'**
  String get planCompletionPercent;

  /// No description provided for @navBooks.
  ///
  /// In sk, this message translates to:
  /// **'Knihy'**
  String get navBooks;

  /// No description provided for @planDailyProgress.
  ///
  /// In sk, this message translates to:
  /// **'Denný pokrok'**
  String get planDailyProgress;

  /// No description provided for @planTotalProgressTitle.
  ///
  /// In sk, this message translates to:
  /// **'Pokrok plánu'**
  String get planTotalProgressTitle;

  /// No description provided for @planBooksUnit.
  ///
  /// In sk, this message translates to:
  /// **'kníh'**
  String get planBooksUnit;

  /// No description provided for @planChaptersCompletedLower.
  ///
  /// In sk, this message translates to:
  /// **'kapitol prečítaných'**
  String get planChaptersCompletedLower;

  /// No description provided for @planBooksInPlan.
  ///
  /// In sk, this message translates to:
  /// **'Knihy v pláne'**
  String get planBooksInPlan;

  /// No description provided for @planCurrentPlan.
  ///
  /// In sk, this message translates to:
  /// **'Aktuálny plán'**
  String get planCurrentPlan;

  /// No description provided for @planCompleteBookTitle.
  ///
  /// In sk, this message translates to:
  /// **'Označiť knihu ako prečítanú?'**
  String get planCompleteBookTitle;

  /// No description provided for @planCompleteBookMessage.
  ///
  /// In sk, this message translates to:
  /// **'Všetky kapitoly tejto knihy v aktuálnom pláne budú označené ako prečítané:'**
  String get planCompleteBookMessage;

  /// No description provided for @planCompleteBookAction.
  ///
  /// In sk, this message translates to:
  /// **'Označiť knihu'**
  String get planCompleteBookAction;

  /// No description provided for @statsNoPlan.
  ///
  /// In sk, this message translates to:
  /// **'Najprv si vytvorte plán čítania.'**
  String get statsNoPlan;

  /// No description provided for @statsPlanProgressTitle.
  ///
  /// In sk, this message translates to:
  /// **'Pokrok v aktuálnom pláne'**
  String get statsPlanProgressTitle;

  /// No description provided for @statsRemainingPlanChapters.
  ///
  /// In sk, this message translates to:
  /// **'Zostávajúce kapitoly v pláne'**
  String get statsRemainingPlanChapters;

  /// No description provided for @statsPlanStatus.
  ///
  /// In sk, this message translates to:
  /// **'Stav plánu'**
  String get statsPlanStatus;

  /// No description provided for @statsTestamentsTitle.
  ///
  /// In sk, this message translates to:
  /// **'Starý a Nový zákon v pláne'**
  String get statsTestamentsTitle;

  /// No description provided for @statsOldTestamentInPlan.
  ///
  /// In sk, this message translates to:
  /// **'Starý zákon v aktuálnom pláne'**
  String get statsOldTestamentInPlan;

  /// No description provided for @statsNewTestamentInPlan.
  ///
  /// In sk, this message translates to:
  /// **'Nový zákon v aktuálnom pláne'**
  String get statsNewTestamentInPlan;

  /// No description provided for @statsDeuterocanonicalInPlan.
  ///
  /// In sk, this message translates to:
  /// **'Deuterokánonické knihy v pláne'**
  String get statsDeuterocanonicalInPlan;

  /// No description provided for @statsBooksTitle.
  ///
  /// In sk, this message translates to:
  /// **'Knihy v aktuálnom pláne'**
  String get statsBooksTitle;

  /// No description provided for @statsCompletedBooksInPlan.
  ///
  /// In sk, this message translates to:
  /// **'Dokončené knihy v pláne'**
  String get statsCompletedBooksInPlan;

  /// No description provided for @statsRemainingBooksInPlan.
  ///
  /// In sk, this message translates to:
  /// **'Zostávajúce knihy v pláne'**
  String get statsRemainingBooksInPlan;

  /// No description provided for @statsFullyCompletedSelectedBooks.
  ///
  /// In sk, this message translates to:
  /// **'Úplne dokončené vybrané knihy'**
  String get statsFullyCompletedSelectedBooks;

  /// No description provided for @statsNotStartedSelectedBooks.
  ///
  /// In sk, this message translates to:
  /// **'Nezačaté vybrané knihy'**
  String get statsNotStartedSelectedBooks;

  /// No description provided for @statsTodaySummary.
  ///
  /// In sk, this message translates to:
  /// **'Dnešné čítanie v pláne'**
  String get statsTodaySummary;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['sk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'sk':
      return AppLocalizationsSk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
