# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::EscapedCharFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'ensure we handle all the GitLab reference characters', :eager_load do
    reference_chars = ObjectSpace.each_object(Class).filter_map do |klass|
      next unless klass.included_modules.include?(Referable)
      next unless klass.respond_to?(:reference_prefix)
      next unless klass.reference_prefix.length == 1

      klass.reference_prefix
    end.compact

    reference_chars.all? do |char|
      Banzai::Filter::EscapedCharFilter::REFERENCE_CHARS.include?(char)
    end
  end

  it 'leaves reference chars untouched' do
    stub_commonmark_sourcepos_disabled

    markdown = Banzai::Filter::EscapedCharFilter::REFERENCE_CHARS.map { |char| "\\#{char}" }.join(' ')
    doc = Banzai::Filter::MarkdownFilter.new(markdown).call
    html = filter(doc).to_s

    Banzai::Filter::EscapedCharFilter::REFERENCE_CHARS.each do |item|
      char = item == '&' ? '&amp;' : item

      expect(html).to include("<span data-escaped-char>#{char}</span>")
    end
  end

  it 'removes spans for non-reference punctuation' do
    # rubocop:disable Style/StringConcatenation -- better format for escaping characters
    markdown = %q(\"\'\*\+\,\-\.\/\:\;\<\=\>\?\[\]\`\|) + %q[\(\)\\\\]
    # rubocop:enable Style/StringConcatenation

    doc = Banzai::Filter::MarkdownFilter.new(markdown).call

    expect(doc.to_s).to include('<span data-escaped-char')
    expect(filter(doc).to_s).not_to include('<span data-escaped-char')
  end

  it 'keeps html escaped text' do
    markdown = '[link](<foo\>)'
    doc = Banzai::Filter::MarkdownFilter.new(markdown).call

    expect(filter(doc).to_s).to eq '<p data-sourcepos="1:1-1:14">[link](&lt;foo&gt;)</p>'
  end
end
