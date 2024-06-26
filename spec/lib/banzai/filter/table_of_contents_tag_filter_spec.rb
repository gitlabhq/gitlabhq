# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TableOfContentsTagFilter, feature_category: :team_planning do
  include FilterSpecHelper

  context 'table of contents' do
    shared_examples 'table of contents tag' do
      it 'replaces toc tag with ToC result' do
        doc = pipeline_filter(markdown)

        expect(doc.to_html).to include('<ul class="section-nav">')
        expect(doc.to_html).to include('<li><a href="#foo">Foo</a></li>')
      end
    end

    context '[[_TOC_]] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:markdown) { "[[_TOC_]]\n\n# Foo" }
      end

      it_behaves_like 'table of contents tag' do
        let(:markdown) { "[[_toc_]]\n\n# Foo" }
      end

      it 'does not recognize the toc' do
        doc = pipeline_filter("this [[_toc_]]\n\n# Foo")

        expect(doc.to_html).to include('this <a href="_toc_" data-wikilink="true">_toc_</a>')
        expect(doc.to_html).to include('Foo</h1>')
      end
    end

    context '[TOC] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:markdown) { "[TOC]\n\n# Foo" }
      end

      it_behaves_like 'table of contents tag' do
        let(:markdown) { "[toc]\n\n# Foo" }
      end

      it 'does not recognize the toc' do
        doc = pipeline_filter("this [toc]\n\n# Foo")

        expect(doc.to_html).to include('this [toc]')
        expect(doc.to_html).to include('Foo</h1>')
      end
    end
  end

  describe 'structure of a toc' do
    def header(level, text)
      "#{'#' * level} #{text}\n"
    end

    def result(html)
      HTML::Pipeline.new([Banzai::Filter::MarkdownFilter, described_class]).call(html)
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

  it_behaves_like 'pipeline timing check'

  def pipeline_filter(text, context = {})
    context = { project: nil, no_sourcepos: true }.merge(context)

    doc = Banzai::Pipeline::PreProcessPipeline.call(text, {})
    doc = Banzai::Pipeline::FullPipeline.call(doc[:output], context)

    doc[:output]
  end
end
