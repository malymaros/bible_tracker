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

  /// Pauses before fetching a chapter again after HTTP 429 (too many
  /// requests) or a dropped connection. Seen 2026-11: the server refuses
  /// after ~80 requests at [requestDelay] and accepts again within a minute.
  static const List<Duration> retryDelays = [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 60),
    Duration(seconds: 60),
  ];
}
