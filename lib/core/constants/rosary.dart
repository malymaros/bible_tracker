// TODO(kbs): verify all prayer texts and mystery inserts against the official KBS wording before release.

import 'package:bible_tracker/core/models/rosary.dart';

// ── Prayer texts ──────────────────────────────────────────────────────────

const String kPrayerSignOfCross = 'V mene Otca i Syna i Ducha Svätého. Amen.';

const String kPrayerOurFather =
    'Otče náš, ktorý si na nebesiach, posväť sa meno tvoje, príď kráľovstvo '
    'tvoje, buď vôľa tvoja ako v nebi, tak i na zemi. Chlieb náš každodenný '
    'daj nám dnes a odpusť nám naše viny, ako i my odpúšťame svojim vinníkom, '
    'a neuveď nás do pokušenia, ale zbav nás zlého. Amen.';

/// Hail Mary up to (and including) "Ježiš, " — the mystery insert follows.
const String kPrayerHailMaryBefore =
    'Zdravas, Mária, milosti plná, Pán s tebou. Požehnaná si medzi ženami a '
    'požehnaný je plod života tvojho, Ježiš, ';

/// Hail Mary after the mystery insert.
const String kPrayerHailMaryAfter =
    '. Svätá Mária, Matka Božia, pros za nás hriešnych teraz i v hodinu smrti '
    'našej. Amen.';

const String kPrayerGloryBe =
    'Sláva Otcu i Synu i Duchu Svätému, ako bolo na počiatku, tak nech je i '
    'teraz i vždycky i na veky vekov. Amen.';

const String kPrayerFatima =
    'Ó, Ježišu, odpusť nám naše hriechy, zachráň nás od pekelného ohňa a '
    'priveď do neba všetky duše, najmä tie, ktoré najviac potrebujú tvoje '
    'milosrdenstvo.';

const String kPrayerCreed =
    'Verím v Boha, Otca všemohúceho, Stvoriteľa neba i zeme. I v Ježiša '
    'Krista, jeho jediného Syna, nášho Pána, ktorý sa počal z Ducha Svätého, '
    'narodil sa z Márie Panny, trpel za vlády Poncia Piláta, bol ukrižovaný, '
    'umrel a bol pochovaný. Zostúpil k zosnulým, tretieho dňa vstal z mŕtvych, '
    'vystúpil na nebesia, sedí po pravici Boha Otca všemohúceho. Odtiaľ príde '
    'súdiť živých i mŕtvych. Verím v Ducha Svätého, svätú Cirkev katolícku, '
    'spoločenstvo svätých, odpustenie hriechov, vzkriesenie tela a večný '
    'život. Amen.';

const String kPrayerHailHolyQueen =
    'Zdravas, Kráľovná, Matka milosrdenstva, život, sladkosť a nádej naša, buď '
    'pozdravená! K tebe voláme, vyhnaní synovia Evy, k tebe vzdycháme, '
    'horekujúc a plačúc v tomto údolí sĺz. A preto, orodovnica naša, obráť na '
    'nás svoje milosrdné oči a Ježiša, požehnaný plod svojho života, ukáž nám '
    'po tomto putovaní. Ó, milostivá, ó, láskavá, ó, sladká Panna Mária!';

/// Inserts of the three introductory Hail Marys (faith, hope, love).
const List<String> kRosaryIntroInserts = [
  'ktorý nech rozmnožuje našu vieru',
  'ktorý nech upevňuje našu nádej',
  'ktorý nech roznecuje našu lásku',
];

// ── Prayer order labels ───────────────────────────────────────────────────

const String kRosaryStageIntro = 'Úvod';
const String kRosaryStageDecade = 'Desiatok';
const String kRosaryStageClosing = 'Záver';

const String kRosaryNameSignOfCross = 'Znamenie kríža';
const String kRosaryNameCreed = 'Verím v Boha';
const String kRosaryNameOurFather = 'Otče náš';
const String kRosaryNameHailMary = 'Zdravas, Mária';
const String kRosaryNameGloryBe = 'Sláva Otcu';
const String kRosaryNameFatima = 'Ó, Ježišu';
const String kRosaryNameHailHolyQueen = 'Zdravas, Kráľovná';
const String kRosaryNameAnnouncement = 'Ohlásenie tajomstva';

const String kRosarySubCrucifix = 'na krížiku';
const String kRosarySubLargeBead = 'veľké zrnko';
const String kRosarySubIntroHailMary = 'za vieru, nádej a lásku';
const String kRosarySubDecadeHailMary = 's vloženým tajomstvom za menom Ježiš';
const String kRosaryDecadeInsertNote =
    'Vložka sa mení podľa tajomstva desiatku – pozri zoznam tajomstiev vyššie.';
const String kRosaryMeditationHint = 'Krátko sa zamysli nad týmto tajomstvom.';

// ── Weekdays ──────────────────────────────────────────────────────────────

/// Short weekday labels, index 0 = Monday (`DateTime.weekday` - 1).
const List<String> kWeekdayShortLabels = [
  'Po',
  'Ut',
  'St',
  'Št',
  'Pi',
  'So',
  'Ne',
];

/// Full weekday names, index 0 = Monday (`DateTime.weekday` - 1).
const List<String> kWeekdayNames = [
  'pondelok',
  'utorok',
  'streda',
  'štvrtok',
  'piatok',
  'sobota',
  'nedeľa',
];

// ── The four rosaries, in display order ──────────────────────────────────

const List<Rosary> kRosaries = [
  Rosary(
    kind: RosaryKind.joyful,
    name: 'Radostný ruženec',
    daysLabel: 'pondelok, sobota',
    mysteryLabel: 'radostné tajomstvo',
    weekdays: [DateTime.monday, DateTime.saturday],
    mysteries: [
      RosaryMystery(
        number: 1,
        name: 'Zvestovanie Pána',
        shortName: 'Zvestovanie',
        insert: 'ktorého si, Panna, z Ducha Svätého počala',
        ref: ScriptureRef(
          bookId: 'luke',
          chapter: 1,
          verseStart: 26,
          verseEnd: 38,
        ),
      ),
      RosaryMystery(
        number: 2,
        name: 'Navštívenie Alžbety',
        shortName: 'Navštívenie Alžbety',
        insert: 'ktorého si, Panna, pri návšteve Alžbety v živote nosila',
        ref: ScriptureRef(
          bookId: 'luke',
          chapter: 1,
          verseStart: 39,
          verseEnd: 56,
        ),
      ),
      RosaryMystery(
        number: 3,
        name: 'Narodenie Pána',
        shortName: 'Narodenie',
        insert: 'ktorého si, Panna, v Betleheme porodila',
        ref: ScriptureRef(
          bookId: 'luke',
          chapter: 2,
          verseStart: 1,
          verseEnd: 20,
        ),
      ),
      RosaryMystery(
        number: 4,
        name: 'Obetovanie v chráme',
        shortName: 'Obetovanie v chráme',
        insert: 'ktorého si, Panna, v chráme obetovala',
        ref: ScriptureRef(
          bookId: 'luke',
          chapter: 2,
          verseStart: 22,
          verseEnd: 38,
        ),
      ),
      RosaryMystery(
        number: 5,
        name: 'Nájdenie v chráme',
        shortName: 'Nájdenie v chráme',
        insert: 'ktorého si, Panna, v chráme našla',
        ref: ScriptureRef(
          bookId: 'luke',
          chapter: 2,
          verseStart: 41,
          verseEnd: 52,
        ),
      ),
    ],
  ),
  Rosary(
    kind: RosaryKind.luminous,
    name: 'Ruženec svetla',
    daysLabel: 'štvrtok',
    mysteryLabel: 'tajomstvo svetla',
    weekdays: [DateTime.thursday],
    mysteries: [
      RosaryMystery(
        number: 1,
        name: 'Krst v Jordáne',
        shortName: 'Krst v Jordáne',
        insert: 'ktorý bol pokrstený v Jordáne',
        ref: ScriptureRef(
          bookId: 'matt',
          chapter: 3,
          verseStart: 13,
          verseEnd: 17,
        ),
      ),
      RosaryMystery(
        number: 2,
        name: 'Svadba v Káne',
        shortName: 'Svadba v Káne',
        insert: 'ktorý zjavil seba samého na svadbe v Káne',
        ref: ScriptureRef(
          bookId: 'john',
          chapter: 2,
          verseStart: 1,
          verseEnd: 12,
        ),
      ),
      RosaryMystery(
        number: 3,
        name: 'Ohlasovanie Božieho kráľovstva',
        shortName: 'Ohlasovanie kráľovstva',
        insert: 'ktorý ohlasoval Božie kráľovstvo a vyzýval ľud na pokánie',
        ref: ScriptureRef(
          bookId: 'mark',
          chapter: 1,
          verseStart: 14,
          verseEnd: 15,
        ),
      ),
      RosaryMystery(
        number: 4,
        name: 'Premenenie Pána',
        shortName: 'Premenenie',
        insert: 'ktorý sa zjavil vo svojej sláve na vrchu Tábor',
        ref: ScriptureRef(
          bookId: 'matt',
          chapter: 17,
          verseStart: 1,
          verseEnd: 8,
        ),
      ),
      RosaryMystery(
        number: 5,
        name: 'Ustanovenie Eucharistie',
        shortName: 'Ustanovenie Eucharistie',
        insert: 'ktorý ustanovil Eucharistiu',
        ref: ScriptureRef(
          bookId: 'matt',
          chapter: 26,
          verseStart: 26,
          verseEnd: 29,
        ),
      ),
    ],
  ),
  Rosary(
    kind: RosaryKind.sorrowful,
    name: 'Bolestný ruženec',
    daysLabel: 'utorok, piatok',
    mysteryLabel: 'bolestné tajomstvo',
    weekdays: [DateTime.tuesday, DateTime.friday],
    mysteries: [
      RosaryMystery(
        number: 1,
        name: 'Krvavý pot v Getsemanskej záhrade',
        shortName: 'Krvavý pot',
        insert: 'ktorý sa pre nás krvou potil',
        ref: ScriptureRef(
          bookId: 'luke',
          chapter: 22,
          verseStart: 39,
          verseEnd: 46,
        ),
      ),
      RosaryMystery(
        number: 2,
        name: 'Bičovanie',
        shortName: 'Bičovanie',
        insert: 'ktorého pre nás bičovali',
        ref: ScriptureRef(bookId: 'john', chapter: 19, verseStart: 1),
      ),
      RosaryMystery(
        number: 3,
        name: 'Korunovanie tŕním',
        shortName: 'Korunovanie tŕním',
        insert: 'ktorého pre nás tŕním korunovali',
        ref: ScriptureRef(
          bookId: 'matt',
          chapter: 27,
          verseStart: 27,
          verseEnd: 31,
        ),
      ),
      RosaryMystery(
        number: 4,
        name: 'Nesenie kríža',
        shortName: 'Nesenie kríža',
        insert: 'ktorý pre nás niesol ťažký kríž',
        ref: ScriptureRef(
          bookId: 'john',
          chapter: 19,
          verseStart: 16,
          verseEnd: 17,
        ),
      ),
      RosaryMystery(
        number: 5,
        name: 'Ukrižovanie',
        shortName: 'Ukrižovanie',
        insert: 'ktorého pre nás ukrižovali',
        ref: ScriptureRef(
          bookId: 'luke',
          chapter: 23,
          verseStart: 33,
          verseEnd: 46,
        ),
      ),
    ],
  ),
  Rosary(
    kind: RosaryKind.glorious,
    name: 'Slávnostný ruženec',
    daysLabel: 'streda, nedeľa',
    mysteryLabel: 'slávnostné tajomstvo',
    weekdays: [DateTime.wednesday, DateTime.sunday],
    mysteries: [
      RosaryMystery(
        number: 1,
        name: 'Zmŕtvychvstanie',
        shortName: 'Zmŕtvychvstanie',
        insert: 'ktorý slávne vstal z mŕtvych',
        ref: ScriptureRef(
          bookId: 'matt',
          chapter: 28,
          verseStart: 1,
          verseEnd: 10,
        ),
      ),
      RosaryMystery(
        number: 2,
        name: 'Nanebovstúpenie',
        shortName: 'Nanebovstúpenie',
        insert: 'ktorý slávne vystúpil do neba',
        ref: ScriptureRef(
          bookId: 'acts',
          chapter: 1,
          verseStart: 6,
          verseEnd: 11,
        ),
      ),
      RosaryMystery(
        number: 3,
        name: 'Zoslanie Ducha Svätého',
        shortName: 'Zoslanie Ducha Svätého',
        insert: 'ktorý nám zoslal Ducha Svätého',
        ref: ScriptureRef(
          bookId: 'acts',
          chapter: 2,
          verseStart: 1,
          verseEnd: 13,
        ),
      ),
      RosaryMystery(
        number: 4,
        name: 'Nanebovzatie Panny Márie',
        shortName: 'Nanebovzatie Panny Márie',
        insert: 'ktorý ťa, Panna, vzal do neba',
        ref: ScriptureRef(bookId: 'rev', chapter: 12, verseStart: 1),
      ),
      RosaryMystery(
        number: 5,
        name: 'Korunovanie Panny Márie',
        shortName: 'Korunovanie Panny Márie',
        insert: 'ktorý ťa, Panna, v nebi korunoval',
        ref: ScriptureRef(bookId: 'rev', chapter: 12, verseStart: 1),
      ),
    ],
  ),
];
