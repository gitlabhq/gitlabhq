# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::MarkdownFilter do
  include FilterSpecHelper

  describe 'markdown engine from context' do
    it 'defaults to CommonMark' do
      expect_next_instance_of(Banzai::Filter::MarkdownEngines::CommonMark) do |instance|
        expect(instance).to receive(:render).and_return('test')
      end

      filter('test')
    end

    it 'uses CommonMark' do
      expect_next_instance_of(Banzai::Filter::MarkdownEngines::CommonMark) do |instance|
        expect(instance).to receive(:render).and_return('test')
      end

      filter('test', { markdown_engine: :common_mark })
    end
  end

  describe 'code block' do
    context 'using CommonMark' do
      before do
        stub_const('Banzai::Filter::MarkdownFilter::DEFAULT_ENGINE', :common_mark)
      end

      it 'adds language to lang attribute when specified' do
        result = filter("```html\nsome code\n```", no_sourcepos: true)

        expect(result).to start_with('<pre><code lang="html">')
      end

      it 'does not add language to lang attribute when not specified' do
        result = filter("```\nsome code\n```", no_sourcepos: true)

        expect(result).to start_with('<pre><code>')
      end

      it 'works with utf8 chars in language' do
        result = filter("```日\nsome code\n```", no_sourcepos: true)

        expect(result).to start_with('<pre><code lang="日">')
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
      expect(result).to include('<section class="footnotes">')
    end
  end
end
