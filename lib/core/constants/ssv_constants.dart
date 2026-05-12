abstract final class SsvConstants {
  static const String baseUrl = 'https://biblia.ssv.sk/biblia/kniha';

  /// CSS selector for the chapter text block confirmed on real SSV pages.
  /// Structure: div.ssv-bb-module > div.wrapper > div.inbox
  static const String chapterContentSelector =
      '.ssv-bb-module .wrapper > .inbox';

  /// Bumped when the parser logic changes so stale cached rows can be
  /// identified and re-fetched.
  static const int parserVersion = 1;

  /// Polite delay between consecutive HTTP requests to biblia.ssv.sk.
  static const Duration requestDelay = Duration(milliseconds: 300);
}
