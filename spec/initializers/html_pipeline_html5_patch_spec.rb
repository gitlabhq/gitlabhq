# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'HTML::Pipeline::HTML5Patch', feature_category: :markdown do
  describe '.parse' do
    it 'parses HTML into an HTML5 fragment' do
      doc = HTML::Pipeline.parse('<p>hello</p>')

      expect(doc).to be_a(Nokogiri::HTML5::DocumentFragment)
    end

    it 'returns a non-string argument unchanged' do
      fragment = Nokogiri::HTML5::DocumentFragment.parse('<p>hello</p>')

      expect(HTML::Pipeline.parse(fragment)).to be(fragment)
    end

    it 'returns a nesting too deep message when max tree depth is exceeded' do
      html = '<div>' * 5000
      doc = HTML::Pipeline.parse(html)

      expect(doc.text).to include('nesting was too deep')
    end

    it 're-raises ArgumentError with a different message' do
      allow(Nokogiri::HTML5::DocumentFragment).to receive(:parse).and_raise(ArgumentError, 'something else')

      expect { HTML::Pipeline.parse('<p>test</p>') }.to raise_error(ArgumentError, 'something else')
    end
  end

  describe 'inline block-level raw HTML in list items' do
    it 'does not let an inline <div> swallow subsequent content' do
      html = "<ol>\n<li>first <div></li>\n<li>second <div></li>\n</ol>\n<p>After</p>\n"
      doc = HTML::Pipeline.parse(html)

      paragraph = doc.at_css('p')
      expect(paragraph).to be_present
      expect(paragraph.text).to eq('After')
      expect(paragraph.ancestors.map(&:name)).not_to include('ol')
    end

    it 'does not let an inline <section> swallow subsequent content' do
      html = "<ol>\n<li>first <section></li>\n<li>second <section></li>\n</ol>\n<p>After</p>\n"
      doc = HTML::Pipeline.parse(html)

      paragraph = doc.at_css('p')
      expect(paragraph).to be_present
      expect(paragraph.text).to eq('After')
      expect(paragraph.ancestors.map(&:name)).not_to include('ol')
    end
  end
end
