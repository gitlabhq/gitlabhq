require 'rails_helper'

describe Banzai::Pipeline::WikiPipeline do
  describe 'TableOfContents' do
    it 'replaces the tag with the TableOfContentsFilter result' do
      markdown = <<-MD.strip_heredoc
          [[_TOC_]]

          ## Header

          Foo
      MD

      result = described_class.call(markdown, project: spy, project_wiki: double)

      aggregate_failures do
        expect(result[:output].text).not_to include '[['
        expect(result[:output].text).not_to include 'TOC'
        expect(result[:output].to_html).to include(result[:toc])
      end
    end

    it 'is case-sensitive' do
      markdown = <<-MD.strip_heredoc
          [[_toc_]]

          # Header 1

          Foo
      MD

      output = described_class.to_html(markdown, project: spy, project_wiki: double)

      expect(output).to include('[[<em>toc</em>]]')
    end

    it 'handles an empty pipeline result' do
      # No Markdown headers in this doc, so `result[:toc]` will be empty
      markdown = <<-MD.strip_heredoc
          [[_TOC_]]

          Foo
      MD

      output = described_class.to_html(markdown, project: spy, project_wiki: double)

      aggregate_failures do
        expect(output).not_to include('<ul>')
        expect(output).not_to include('[[<em>TOC</em>]]')
      end
    end
  end
end
