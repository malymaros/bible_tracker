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

  String get planCreateTitle;
  String get planStartDate;
  String get planTotalDays;
  String get planIncludedBooks;
  String get planSelectedChapters;
  String get planDateRange;
  String get planDateRangeUnavailable;
  String get planCreateAction;
  String get planInvalidDayCount;
  String get planTooManyDays;
  String get planSelectAtLeastOneBook;
  String get planTodayReading;
  String get planNoReadingToday;
  String get planSchedule;
  String get planDay;
  String get planToday;
  String get planChapterCompleted;
  String get planChapterIncomplete;
  String get planDeleteAction;
  String get planDeleteTitle;
  String get planDeleteMessage;
  String get planCancel;
  String get planAhead;
  String get planBehind;
  String get planOnTrack;
  String get planCompletedChapters;
  String get planExpectedByToday;
  String get planAheadBehind;
  String get planCompletionPercent;
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
