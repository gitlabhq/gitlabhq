# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MarkdownFilter, feature_category: :team_planning do
  include FilterSpecHelper

  describe 'markdown engine from context' do
    it 'finds the correct engine' do
      expect(described_class.render_engine(:common_mark)).to eq Banzai::Filter::MarkdownEngines::CommonMark
    end

    it 'defaults to the DEFAULT_ENGINE' do
      default_engine = Banzai::Filter::MarkdownFilter::DEFAULT_ENGINE.to_s.classify
      default = "Banzai::Filter::MarkdownEngines::#{default_engine}".constantize

      expect(described_class.render_engine(nil)).to eq default
    end

    it 'raise error for unrecognized engines' do
      expect { described_class.render_engine(:foo_bar) }.to raise_error(NameError)
    end
  end

  describe 'code block' do
    context 'using CommonMark' do
      before do
        stub_const('Banzai::Filter::MarkdownFilter::DEFAULT_ENGINE', :common_mark)
      end

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

        expect(result).to start_with('<pre lang="ruby:red" data-meta="gem foo"><code>')
      end
    end
  end

  describe 'source line position' do
    context 'using CommonMark' do
      before do
        stub_const('Banzai::Filter::MarkdownFilter::DEFAULT_ENGINE', :common_mark)
      end

      it 'defaults to add data-sourcepos' do
        result = filter('test')

        expect(result).to eq '<p data-sourcepos="1:1-1:4">test</p>'
      end

      it 'disables data-sourcepos' do
        result = filter('test', no_sourcepos: true)

        expect(result).to eq '<p>test</p>'
      end
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
