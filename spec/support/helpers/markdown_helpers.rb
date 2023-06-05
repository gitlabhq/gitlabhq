# frozen_string_literal: true

module MarkdownHelpers
  def remove_sourcepos(html)
    html.gsub(/\ ?data-sourcepos=".*?"/, '')
  end
end
