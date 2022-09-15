# frozen_string_literal: true

module HtmlEscapedHelpers
  extend self

  # Checks if +content+ contains HTML escaped tags and returns its match.
  #
  # It matches escaped opening and closing tags `&lt;<name>` and
  # `&lt;/<name>`. The match is discarded if the tag is inside a quoted
  # attribute value.
  # Foor example, `<div title="We allow # &lt;b&gt;bold&lt;/b&gt;">`.
  #
  # @return [MatchData, nil] Returns the match or +nil+ if no match was found.
  def match_html_escaped_tags(content)
    match_data = %r{&lt;\s*(?:/\s*)?\w+}.match(content)
    return unless match_data

    # Escaped HTML tags are allowed inside quoted attribute values like:
    # `title="Press &lt;back&gt;"`
    return if %r{=\s*["'][^>]*\z}.match?(match_data.pre_match)

    match_data
  end
end
