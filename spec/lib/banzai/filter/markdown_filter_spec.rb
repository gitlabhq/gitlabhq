# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MarkdownFilter, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax
  include FilterSpecHelper

  describe 'markdown engine from context' do
    it 'finds the correct engine' do
      expect(described_class.new('foo', { markdown_engine: :cmark }).render_engine)
        .to eq Banzai::Filter::MarkdownEngines::Cmark
    end

    it 'defaults to the GLFM_ENGINE' do
      default_engine = Banzai::Filter::MarkdownFilter::GLFM_ENGINE.to_s.classify
      engine = "Banzai::Filter::MarkdownEngines::#{default_engine}".constantize

      expect(described_class.new('foo', {}).render_engine).to eq engine
    end

    it 'raise error for unrecognized engines' do
      expect { described_class.new('foo', { markdown_engine: :foo_bar }).render_engine }.to raise_error(NameError)
    end
  end

  describe 'parse_sourcepos' do
    where(:sourcepos, :expected) do
      '1:1-1:4'     | { start: { row: 0, col: 0 }, end: { row: 0, col: 3 } }
      '12:22-1:456' | { start: { row: 11, col: 21 }, end: { row: 0, col: 455 } }
      '0:0-0:0'     | { start: { row: 0, col: 0 }, end: { row: 0, col: 0 } }
      '-1:2-3:-4'   | nil
    end

    with_them do
      it 'correctly parses' do
        expect(described_class.parse_sourcepos(sourcepos)).to eq expected
      end
    end
  end

  describe 'code block' do
    it 'adds language to lang attribute when specified' do
      result = filter("```html\nsome code\n```", no_sourcepos: true)

      expect(result).to start_with('<pre lang="html"><code>')
    end

    it 'does not add language to lang attribute when not specified' do
      result = filter("```\nsome code\n```", no_sourcepos: true)

      expect(result).to start_with('<pre><code>')
    end

    it 'works with utf8 chars in language' do
      result = filter("```日\nsome code\n```", no_sourcepos: true)

      expect(result).to start_with('<pre lang="日"><code>')
    end

    it 'works with additional language parameters' do
      result = filter("```ruby:red gem foo\nsome code\n```", no_sourcepos: true)

      expect(result).to include('lang="ruby:red"')
      expect(result).to include('data-meta="gem foo"')
    end
  end

  describe 'source line position' do
    it 'defaults to add data-sourcepos' do
      result = filter('test')

      expect(result).to eq '<p data-sourcepos="1:1-1:4">test</p>'
    end

    it 'disables data-sourcepos' do
      result = filter('test', no_sourcepos: true)

      expect(result).to eq '<p>test</p>'
    end
  end

  describe 'footnotes in tables' do
    it 'processes footnotes in table cells' do
      text = <<-MD.strip_heredoc
        | Column1   |
        | --------- |
        | foot [^1] |

        [^1]: a footnote
      MD

      result = filter(text, no_sourcepos: true)

      expect(result).to include('<td>foot <sup')
      expect(result).to include('<section class="footnotes" data-footnotes>')
    end
  end

  describe 'multiline blockquotes' do
    it 'works and has correct data-sourcepos references' do
      text = <<~MD
        - item one

          >>>
          Paragraph 1
          >>>
        - item two
      MD

      expected = <<~EXPECTED
        <ul data-sourcepos="1:1-6:10">
        <li data-sourcepos="1:1-5:5">
        <p data-sourcepos="1:3-1:10">item one</p>
        <blockquote data-sourcepos="3:3-5:5">
        <p data-sourcepos="4:3-4:13">Paragraph 1</p>
        </blockquote>
        </li>
        <li data-sourcepos="6:1-6:10">
        <p data-sourcepos="6:3-6:10">item two</p>
        </li>
        </ul>
      EXPECTED

      result = filter(text, no_sourcepos: false)

      expect(result).to eq(expected.strip)
    end
  end

  it 'properly handles mixture with HTML comments and raw markdown' do
    text = <<~MD
      <!-- html comment -->

      >>>
      something
      >>>

      <h1>
      test
      </h1>
    MD

    expected = <<~EXPECTED
    <!-- html comment -->
    <blockquote data-sourcepos="3:1-5:3">
    <p data-sourcepos="4:1-4:9">something</p>
    </blockquote>
    <h1>
    test
    </h1>
    EXPECTED

    result = filter(text, no_sourcepos: false)

    expect(result).to eq(expected.strip)
  end
end
