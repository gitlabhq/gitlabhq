const { existsSync } = require('fs');
const path = require('path');
const { marked } = require('marked');

const NON_WORD_RE = /[^\p{L}\p{M}\p{N}\p{Pc}\- \t]/gu;
const blockLevelRenderer = () => '';
const inlineLevelRenderer = (token) => token;

/**
 * We use a custom marked rendered to get rid of all the contents we don't need.
 * All we care about are the headings' anchors.
 * We slugify the titles the same way as in
 * https://gitlab.com/gitlab-org/ruby/gems/gitlab_kramdown/-/blob/bbc5ac439a2e6af60cbcce9a157283b2c5b59b38/lib/gitlab_kramdown/parser/header.rb#L78.
 */
marked.use({
  renderer: {
    // The below blocks' renderer simply returns an empty string as we don't need them while extracting anchors.
    paragraph: blockLevelRenderer,
    list: blockLevelRenderer,
    table: blockLevelRenderer,
    code: blockLevelRenderer,
    blockquote: blockLevelRenderer,
    hr: blockLevelRenderer,

    // The inline renderer just returns the token's text. This ensures that headings don't contain any HTML.
    strong: inlineLevelRenderer,
    em: inlineLevelRenderer,
    codespan: inlineLevelRenderer,

    /**
     * This renders headings as their slugified text which we can then use to get a list of
     * anchors in the doc.
     *
     * @param {string} text
     * @returns {string} Slugified heading text
     */
    heading(text) {
      const slugified = text
        .toLowerCase()
        .replace(/&amp;/g, '&')
        .replace(/&#39;/g, "'")
        .replace(/&quot;/g, '"')
        .replace(/[ \t]/g, '-')
        .replace(NON_WORD_RE, '');

      return `${slugified}\n`;
    },
  },
});

module.exports = {
  /**
   * Infers the Markdown documentation file path from the helper's `path` argument.
   * If the path doesn't match a .md file directly, we assume it's a directory containing an index.md file.
   *
   * @param {string} pathArg The documentation path passed to the helper
   * @returns {string} The documentation file path
   */
  getDocsFilePath(pathArg) {
    const docsPath = pathArg
      .replace(/#.*$/, '') // Remove the anchor if any
      .replace(/\.(html|md)$/, ''); // Remove the file extension if any
    const docsFilePath = path.join(__dirname, '../../../../doc', docsPath);
    return existsSync(`${docsFilePath}.md`)
      ? `${docsFilePath}.md`
      : path.join(docsFilePath, 'index.md');
  },
  /**
   * Extracts existing anchors in a given Markdown file.
   * If some anchors appear multiple times in the document, they are deduplicated by appending an
   * incremental index.
   *
   * @param {string} content The raw content from the Markdown file
   * @returns {string[]} The list of anchors
   */
  getAnchorsInMarkdown(content) {
    const markdown = marked.parse(content.toString());
    const anchors = markdown.split('\n').filter(Boolean);
    const counters = {};

    return anchors.map((anchor) => {
      counters[anchor] = counters[anchor] ? counters[anchor] + 1 : 0;
      return anchor + (counters[anchor] > 0 ? `-${counters[anchor]}` : '');
    });
  },
};
