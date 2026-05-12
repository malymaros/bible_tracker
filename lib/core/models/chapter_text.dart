/// Scraped chapter text returned by [SsvScraper.fetchChapter].
///
/// Not to be confused with [ChapterTextRow] which is the Drift database row.
class ChapterText {
  final String htmlContent;
  final String? plainText;
  final String sourceUrl;
  final int parserVersion;

  const ChapterText({
    required this.htmlContent,
    this.plainText,
    required this.sourceUrl,
    required this.parserVersion,
  });
}
