# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MarkdownFilter, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax
  include FilterSpecHelper

  describe 'markdown engine from context' do
    it 'finds the correct engine' do
      expect(described_class.new('foo', { markdown_engine: :common_mark }).render_engine)
        .to eq Banzai::Filter::MarkdownEngines::CommonMark
    end

    it 'defaults to the RUST_ENGINE' do
      default_engine = Banzai::Filter::MarkdownFilter::RUST_ENGINE.to_s.classify
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
end
