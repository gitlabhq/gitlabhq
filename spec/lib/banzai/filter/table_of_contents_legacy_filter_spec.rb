# frozen_string_literal: true

require 'spec_helper'

# TODO: This is now a legacy filter, and is only used with the Ruby parser.
# The current markdown parser now properly handles adding anchors to headers.
# The Ruby parser is now only for benchmarking purposes.
# issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601
RSpec.describe Banzai::Filter::TableOfContentsLegacyFilter, feature_category: :markdown do
  include FilterSpecHelper

  def header(level, text)
    "<h#{level}>#{text}</h#{level}>\n"
  end

  let_it_be(:context) { { markdown_engine: Banzai::Filter::MarkdownFilter::CMARK_ENGINE } }

  it 'does nothing when :no_header_anchors is truthy' do
    exp = act = header(1, 'Header')
    expect(filter(act, context.merge({ no_header_anchors: 1 })).to_html).to eq exp
  end

  it 'does nothing with empty headers' do
    exp = act = header(1, nil)
    expect(filter(act, context).to_html).to eq exp
  end

  1.upto(6) do |i|
    it "processes h#{i} elements" do
      html = header(i, "Header #{i}")
      doc = filter(html, context)

      expect(doc.css("h#{i} a").first.attr('id')).to eq "user-content-header-#{i}"
    end
  end

  describe 'anchor tag' do
    it 'has an `anchor` class' do
      doc = filter(header(1, 'Header'), context)
      expect(doc.css('h1 a').first.attr('class')).to eq 'anchor'
    end

    it 'has a namespaced id' do
      doc = filter(header(1, 'Header'), context)
      expect(doc.css('h1 a').first.attr('id')).to eq 'user-content-header'
    end

    it 'links to the non-namespaced id' do
      doc = filter(header(1, 'Header'), context)
      expect(doc.css('h1 a').first.attr('href')).to eq '#header'
    end

    describe 'generated IDs' do
      it 'translates spaces to dashes' do
        doc = filter(header(1, 'This header has spaces in it'), context)
        expect(doc.css('h1 a').first.attr('href')).to eq '#this-header-has-spaces-in-it'
      end

      it 'squeezes multiple spaces and dashes' do
        doc = filter(header(1, 'This---header     is poorly-formatted'), context)
        expect(doc.css('h1 a').first.attr('href')).to eq '#this-header-is-poorly-formatted'
      end

      it 'removes punctuation' do
        doc = filter(header(1, "This, header! is, filled. with @ punctuation?"), context)
        expect(doc.css('h1 a').first.attr('href')).to eq '#this-header-is-filled-with-punctuation'
      end

      it 'removes any leading or trailing spaces' do
        doc = filter(header(1, " \r\n\tTitle with spaces\r\n\t "), context)
        expect(doc.css('h1 a').first.attr('href')).to eq '#title-with-spaces'
      end

      it 'appends a unique number to duplicates' do
        doc = filter(header(1, 'One') + header(2, 'One'), context)

        expect(doc.css('h1 a').first.attr('href')).to eq '#one'
        expect(doc.css('h2 a').first.attr('href')).to eq '#one-1'
      end

      it 'prepends a prefix to digits-only ids' do
        doc = filter(header(1, "123") + header(2, "1.0"), context)

        expect(doc.css('h1 a').first.attr('href')).to eq '#anchor-123'
        expect(doc.css('h2 a').first.attr('href')).to eq '#anchor-10'
      end

      it 'supports Unicode' do
        doc = filter(header(1, '한글'), context)
        expect(doc.css('h1 a').first.attr('id')).to eq 'user-content-한글'
        # check that we encode the href to avoid issues with the
        # ExternalLinkFilter (see https://gitlab.com/gitlab-org/gitlab/issues/26210)
        expect(doc.css('h1 a').first.attr('href')).to eq "##{CGI.escape('한글')}"
      end

      it 'limits header href length with 255 characters' do
        doc = filter(header(1, 'a' * 500), context)

        expect(doc.css('h1 a').first.attr('href')).to eq "##{'a' * 255}"
      end
    end
  end

  describe 'result' do
    def result(html)
      HTML::Pipeline.new([described_class], context).call(html)
    end

    let(:results) { result(header(1, 'Header 1') + header(2, 'Header 2')) }
    let(:doc) { Nokogiri::XML::DocumentFragment.parse(results[:toc]) }

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

    context 'when table of contents nesting' do
      let(:results) do
        result(
          header(1, 'Header 1') +
          header(2, 'Header 1-1') +
          header(3, 'Header 1-1-1') +
          header(2, 'Header 1-2') +
          header(1, 'Header 2') +
          header(2, 'Header 2-1')
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
      end
    end

    context 'when header text contains escaped content' do
      let(:content) { '&lt;img src="x" onerror="alert(42)"&gt;' }
      let(:results) { result(header(1, content)) }

      it 'outputs escaped content' do
        expect(doc.inner_html).to include(content)
      end
    end
  end
end
