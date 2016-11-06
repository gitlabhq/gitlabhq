require 'spec_helper'

describe Banzai::Filter::RichReferenceFilter, lib: true do
  include FilterSpecHelper

  describe '#call' do
    context 'with data-rich-ref-verbosity of 1' do
      def doc(title)
        Nokogiri::HTML.fragment(
          "<a href='#' data-rich-ref-verbosity='1' title='#{title}'>#1</a>"
        )
      end

      it 'appends the issue title' do
        title = 'An issue title'

        expect(filter(doc(title)).at_css('a').text).to include(title)
      end

      context 'but no title' do
        it 'does not modify the document' do
          document = doc(nil)

          expect(filter(document)).to eq(document)
        end
      end
    end

    context 'with data-rich-ref-verbosity of 0' do
      it 'does not modify the document' do
        doc = Nokogiri::HTML.fragment("<a href='#' data-rich-ref-verbosity='0'>#1</a>")

        expect(filter(doc)).to eq(doc)
      end
    end

    context 'with no data-rich-ref-verbosity' do
      it 'does not modify the document' do
        doc = Nokogiri::HTML.fragment("<a href='#'>#1+</a>")

        expect(filter(doc)).to eq(doc)
      end
    end

    context 'with no <a> tag in the document' do
      it 'does not modify the document' do
        doc = Nokogiri::HTML.fragment('<p>Some text</p>')

        expect(filter(doc)).to eq(doc)
      end
    end

    context 'with data-rich-ref-verbosity of 2' do
      let(:doc) do
        Nokogiri::HTML.fragment("<a href='#' data-rich-ref-verbosity='2' title='#{title}'>#1</a>")
      end

      let(:title) { 'An issue title' }

      it 'appends the issue title' do
        expect(filter(doc).at_css('a').text).to include(title)
      end

      it 'adds an extra "+"' do
        expect(filter(doc).to_html).to include('+')
      end
    end

    context 'with data-rich-ref-verbosity of 3' do
      let(:doc) do
        Nokogiri::HTML.fragment("<a href='#' data-rich-ref-verbosity='3' title='#{title}'>#1</a>")
      end

      let(:title) { 'An issue title' }

      it 'appends the issue title' do
        expect(filter(doc).at_css('a').text).to include(title)
      end

      it 'adds two extra "+"' do
        expect(filter(doc).to_html).to include('++')
      end
    end

    context 'with more than one links with data-rich-ref-verbosity' do
      let(:doc) do
        Nokogiri::HTML.fragment(
          "<a href='#' title='first title'>#1</a> but also " +
          "<a href='#' data-rich-ref-verbosity='1' title='second title'>#2</a> and " +
          "<a href='#' data-rich-ref-verbosity='1' title='third title'>#3</a>"
        )
      end

      it 'appends the issue title for all links with data-rich-ref-verbosity' do
        html = filter(doc).to_html

        expect(html).not_to include('#1 first title')
        expect(html).to include('#2 second title')
        expect(html).to include('#3 third title')
      end
    end

    context 'with text attribute following a rich-ref link and rich-ref-verbosity > 1' do
      let(:doc) do
        Nokogiri::HTML.fragment(
          "<a href='#' data-rich-ref-verbosity='#{rich_ref_verbosity}' title='a title'>#1</a>Something else here."
        )
      end

      let(:rich_ref_verbosity) { 2 }

      it 'adds an extra node with missing "+"s' do
        expect(filter(doc).to_html).to include('+' * (rich_ref_verbosity - 1))
      end
    end

    context 'with non-text attribute following a rich-ref link and rich-ref-verbosity > 1' do
      let(:doc) do
        Nokogiri::HTML.fragment(
          "<a href='#' data-rich-ref-verbosity='2' title='a title'>#1</a><a href='#'>#2</a>"
        )
      end

      it 'adds a text node for extra "+"s' do
        text = filter(doc)

        expect(text.to_html).to include('</a>+<a href="#">#2</a>')
      end
    end
  end
end
