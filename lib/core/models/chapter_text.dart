/// Scraped chapter text returned by [SsvScraper.fetchChapter].
///
/// Not to be confused with [ChapterTextRow] which is the Drift database row.
class ChapterText {
  final String htmlContent;
  final String? plainText;

  /// Inner HTML of the chapter's footnotes block (`div.faqs`); null when the
  /// chapter has no notes.
  final String? notesHtml;
  final String sourceUrl;
  final int parserVersion;

  const ChapterText({
    required this.htmlContent,
    this.plainText,
    this.notesHtml,
    required this.sourceUrl,
    required this.parserVersion,
  });
}
