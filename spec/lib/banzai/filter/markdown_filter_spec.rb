require 'spec_helper'

describe Banzai::Filter::MarkdownFilter do
  include FilterSpecHelper

  describe 'markdown engine from context' do
    it 'defaults to CommonMark' do
      expect_any_instance_of(Banzai::Filter::MarkdownEngines::CommonMark).to receive(:render).and_return('test')

      filter('test')
    end

    it 'uses Redcarpet' do
      expect_any_instance_of(Banzai::Filter::MarkdownEngines::Redcarpet).to receive(:render).and_return('test')

      filter('test', { markdown_engine: :redcarpet })
    end

    it 'uses CommonMark' do
      expect_any_instance_of(Banzai::Filter::MarkdownEngines::CommonMark).to receive(:render).and_return('test')

      filter('test', { markdown_engine: :common_mark })
    end
  end

  describe 'code block' do
    context 'using CommonMark' do
      before do
        stub_const('Banzai::Filter::MarkdownFilter::DEFAULT_ENGINE', :common_mark)
      end

      it 'adds language to lang attribute when specified' do
        result = filter("```html\nsome code\n```")

        expect(result).to start_with("<pre><code lang=\"html\">")
      end

      it 'does not add language to lang attribute when not specified' do
        result = filter("```\nsome code\n```")

        expect(result).to start_with("<pre><code>")
      end
    end

    context 'using Redcarpet' do
      before do
        stub_const('Banzai::Filter::MarkdownFilter::DEFAULT_ENGINE', :redcarpet)
      end

      it 'adds language to lang attribute when specified' do
        result = filter("```html\nsome code\n```")

        expect(result).to start_with("\n<pre><code lang=\"html\">")
      end

      it 'does not add language to lang attribute when not specified' do
        result = filter("```\nsome code\n```")

        expect(result).to start_with("\n<pre><code>")
      end
    end
  end
end
