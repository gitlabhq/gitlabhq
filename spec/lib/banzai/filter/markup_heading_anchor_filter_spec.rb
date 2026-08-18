# frozen_string_literal: true

require 'fast_spec_helper'
require 'html/pipeline'
require_relative '../../../support/shared_examples/lib/banzai/filters/filter_timeout_shared_examples'

RSpec.describe Banzai::Filter::MarkupHeadingAnchorFilter, :aggregate_failures, feature_category: :markdown do
  def filter(html, context = {})
    described_class.call(html, context)
  end

  describe 'adds heading IDs and anchor links' do
    it 'adds id and anchor to headings' do
      result = filter('<h1>Hello World</h1>')
      heading = result.at_css('h1')

      expect(heading['id']).to eq('user-content-hello-world')
      anchor = heading.at_css('a.anchor')
      expect(anchor).to be_present
      expect(anchor['href']).to eq('#hello-world')
      expect(anchor['class']).to eq('anchor')
      expect(anchor['data-heading-content']).to eq('Hello World')
      expect(anchor['aria-label']).to include("Link to heading 'Hello World'")
    end

    it 'adds id and anchor to all heading levels with correct href values' do
      result = filter(
        <<~HTML
          <h1>Heading 1</h1>
          <h2>Heading 2</h2>
          <h3>Heading 3</h3>
          <h4>Heading 4</h4>
          <h5>Heading 5</h5>
          <h6>Heading 6</h6>
          <h2>Another H2</h2>
        HTML
      )

      headings = result.css('h1, h2, h3, h4, h5, h6')
      expect(headings.size).to eq(7)
      headings.each do |heading|
        expect(heading['id']).to be_present
        expect(heading.at_css('a.anchor')).to be_present
      end

      expect(result.at_css('h1')['id']).to eq('user-content-heading-1')
      expect(result.at_css('h1 a.anchor')['href']).to eq('#heading-1')
      expect(result.at_css('h6')['id']).to eq('user-content-heading-6')
      expect(result.at_css('h6 a.anchor')['href']).to eq('#heading-6')
    end

    describe 'heading slug generation' do
      using RSpec::Parameterized::TableSyntax

      where(:heading_text, :expected_slug, :case_name) do
        [
          ['!#$%&*+,./:;=?@\^`|~<>[]{}()', 'h1', 'falls back to heading name when slug would be empty']
        ]
      end

      with_them do
        it 'generates correct id and anchor href' do
          doc = Nokogiri::HTML5.fragment('<h1>')
          doc.at_css('h1').content = heading_text
          result = filter(doc)
          heading = result.at_css('h1')

          expect(heading['id']).to eq("user-content-#{expected_slug}")
          expect(heading.at_css('a.anchor')['href']).to eq("##{expected_slug}")
        end
      end
    end

    it 'handles duplicate heading slugs by appending a suffix' do
      result = filter('<h1>Foo</h1><h2>Foo</h2><h3>Foo</h3>')

      expect(result.at_css('h1')['id']).to eq('user-content-foo')
      expect(result.at_css('h1 a.anchor')['href']).to eq('#foo')
      expect(result.at_css('h2')['id']).to eq('user-content-foo-1')
      expect(result.at_css('h2 a.anchor')['href']).to eq('#foo-1')
      expect(result.at_css('h3')['id']).to eq('user-content-foo-2')
      expect(result.at_css('h3 a.anchor')['href']).to eq('#foo-2')
    end
  end

  describe 'handles headings with existing id' do
    it 'transforms headings with non-prefixed id' do
      result = filter('<h1 id="existing-id">Already Has ID</h1>')

      heading = result.at_css('h1')
      expect(heading['id']).to eq('user-content-existing-id')
      expect(heading.at_css('a.anchor')['href']).to eq('#existing-id')
    end

    it 'does not modify headings with user-content- prefixed id' do
      result = filter('<h1 id="user-content-existing-id">Already Annotated</h1>')

      heading = result.at_css('h1')
      expect(heading['id']).to eq('user-content-existing-id')
      expect(heading.at_css('a.anchor')).to be_nil
    end

    it 'avoids slug collision between existing id and generated slug' do
      result = filter('<h2 id="foo">Existing</h2><h2>Foo</h2>')

      headings = result.css('h2')
      expect(headings[0]['id']).to eq('user-content-foo')
      expect(headings[1]['id']).to eq('user-content-foo-1')
    end

    it 'allows slug collision when existing id follows matching generated slugs, but counter survives' do
      result = filter('<h2>Foo</h2><h2>Foo</h2><h2 id="foo">Existing</h2><h2>Foo</h2>')

      headings = result.css('h2')
      expect(headings[0]['id']).to eq('user-content-foo')
      expect(headings[1]['id']).to eq('user-content-foo-1')
      expect(headings[2]['id']).to eq('user-content-foo')
      expect(headings[3]['id']).to eq('user-content-foo-2')
    end
  end

  describe 'skips empty headings' do
    using RSpec::Parameterized::TableSyntax

    where(:html) do
      [
        ['<h1></h1>'],
        ['<h1>   </h1>']
      ]
    end

    with_them do
      it 'does not add id to empty headings' do
        result = filter(html)
        heading = result.at_css('h1')

        expect(heading['id']).to be_nil
        expect(heading.at_css('a.anchor')).to be_nil
      end
    end
  end

  describe 'heading text extraction' do
    it 'extracts text content ignoring HTML markup inside heading' do
      result = filter('<h1>Hello <em>World</em>!</h1>')
      heading = result.at_css('h1')

      expect(heading['id']).to eq('user-content-hello-world')
      anchor = heading.at_css('a.anchor')
      expect(anchor['href']).to eq('#hello-world')
      expect(anchor['data-heading-content']).to eq('Hello World!')
    end
  end

  describe 'file prefix' do
    context 'when use_filename_in_anchor is true' do
      let(:context) { { use_filename_in_anchor: true, requested_path: requested_path } }

      context 'with duplicate headings in the same document' do
        let(:requested_path) { 'file.org' }

        it 'appends suffix to duplicate slugs after prefix' do
          result = filter('<h1>Foo</h1><h2>Foo</h2><h3>Foo</h3>', context)

          expect(result.at_css('h1')['id']).to eq('user-content-file-foo')
          expect(result.at_css('h1 a.anchor')['href']).to eq('#file-foo')
          expect(result.at_css('h2')['id']).to eq('user-content-file-foo-1')
          expect(result.at_css('h2 a.anchor')['href']).to eq('#file-foo-1')
          expect(result.at_css('h3')['id']).to eq('user-content-file-foo-2')
          expect(result.at_css('h3 a.anchor')['href']).to eq('#file-foo-2')
        end
      end

      context 'when different file paths produce slug collision' do
        using RSpec::Parameterized::TableSyntax

        where(:requested_path, :heading_text) do
          'file.org'          | '1. Overview'
          'file-1.org'        | 'Overview'
          'file-1.rst'        | 'Overview'
          'file-1.wiki'       | 'Overview'
          'file-1.mediawiki'  | 'Overview'
          'file-1.textile'    | 'Overview'
          'file-1.rdoc'       | 'Overview'
          'file-1.creole'     | 'Overview'
        end

        with_them do
          it 'allows slug collision from different file and heading combinations' do
            doc = Nokogiri::HTML5.fragment('<h2>')
            doc.at_css('h2').content = heading_text
            result = filter(doc, context)
            heading = result.at_css('h2')

            expect(heading['id']).to eq('user-content-file-1-overview')
            expect(heading.at_css('a.anchor')['href']).to eq('#file-1-overview')
          end
        end
      end
    end

    describe 'when heading slugs should not be prefixed' do
      using RSpec::Parameterized::TableSyntax

      where(:context, :case_name) do
        { requested_path: '!#$%&*+,./:;=?@\^`|~<>[]{}().org',
          use_filename_in_anchor: true } | 'when slug would be empty'
        { requested_path: 'docs/CONTRIBUTING.rst' } | 'when use_filename_in_anchor is not set'
        { use_filename_in_anchor: true } | 'when requested_path is absent'
      end

      with_them do
        it 'generates heading IDs without file prefix' do
          result = filter('<h2>CoC</h2>', context)
          heading = result.at_css('h2')

          expect(heading['id']).to eq('user-content-coc')
          expect(heading.at_css('a.anchor')['href']).to eq('#coc')
        end
      end
    end
  end

  it_behaves_like 'pipeline timing check'
end
