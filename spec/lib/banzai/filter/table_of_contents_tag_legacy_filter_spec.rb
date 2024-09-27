# frozen_string_literal: true

require 'spec_helper'

# TODO: This is now a legacy filter, and is only used with the Ruby parser.
# The Ruby parser is now only for benchmarking purposes.
# issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601
# rubocop:disable RSpec/ContextWording -- legacy code
# rubocop:disable Layout/LineLength -- legacy code
RSpec.describe Banzai::Filter::TableOfContentsTagLegacyFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:context) { { markdown_engine: Banzai::Filter::MarkdownFilter::CMARK_ENGINE } }

  context 'table of contents' do
    shared_examples 'table of contents tag' do
      it 'replaces toc tag with ToC result' do
        doc = filter(html, context, { toc: "FOO" })

        expect(doc.to_html).to eq("FOO")
      end

      it 'handles an empty ToC result' do
        doc = filter(html, context)

        expect(doc.to_html).to eq ''
      end
    end

    context '[[_TOC_]] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:html) { '<p>[[<em>TOC</em>]]</p>' }
      end
    end

    context '[[_toc_]] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:html) { '<p>[[<em>toc</em>]]</p>' }
      end
    end

    context '[TOC] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:html) { '<p>[TOC]</p>' }
      end
    end

    context '[toc] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:html) { '<p>[toc]</p>' }
      end
    end
  end

  describe 'structure of a toc' do
    def header(level, text)
      "#{'#' * level} #{text}\n"
    end

    def result(html)
      HTML::Pipeline.new([Banzai::Filter::MarkdownFilter, Banzai::Filter::TableOfContentsLegacyFilter, described_class]).call(html, context)
    end

    let(:results) { result("[toc]\n\n#{header(1, 'Header 1')}#{header(2, 'Header 2')}") }
    let(:doc) { results[:output] }

    it 'is contained within a `ul` element' do
      expect(doc.children.first.name).to eq 'ul'
      expect(doc.children.first.attr('class')).to eq 'section-nav'
    end

    it 'contains an `li` element for each header' do
      expect(doc.css('li').length).to eq 2

      links = doc.css('li a')

      expect(links.first.attr('href')).to eq '#header-1'
      expect(links.first.text).to eq 'Header 1'
      expect(links.last.attr('href')).to eq '#header-2'
      expect(links.last.text).to eq 'Header 2'
    end

    context 'table of contents nesting' do
      let(:results) do
        result(
          <<~MARKDOWN
            [toc]

            #{header(1, 'Header 1')}
            #{header(2, 'Header 1-1')}
            #{header(3, 'Header 1-1-1')}
            #{header(2, 'Header 1-2')}
            #{header(1, 'Header 2')}
            #{header(2, 'Header 2-1')}
            #{header(2, 'Header 2-1b')}
          MARKDOWN
        )
      end

      it 'keeps list levels regarding header levels' do
        items = doc.css('li')

        # Header 1
        expect(items[0].ancestors).to satisfy_none { |node| node.name == 'li' }

        # Header 1-1
        expect(items[1].ancestors).to include(items[0])

        # Header 1-1-1
        expect(items[2].ancestors).to include(items[0], items[1])

        # Header 1-2
        expect(items[3].ancestors).to include(items[0])
        expect(items[3].ancestors).not_to include(items[1])

        # Header 2
        expect(items[4].ancestors).to satisfy_none { |node| node.name == 'li' }

        # Header 2-1
        expect(items[5].ancestors).to include(items[4])

        # Header 2-1b
        expect(items[6].ancestors).to include(items[4])
      end
    end

    context 'header text contains escaped content' do
      let(:content) { '&lt;img src="x" onerror="alert(42)"&gt;' }
      let(:results) { result(header(1, content)) }

      it 'outputs escaped content' do
        expect(doc.inner_html).to include(content)
      end
    end
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/ContextWording
