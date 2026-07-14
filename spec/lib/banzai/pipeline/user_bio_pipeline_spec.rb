# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::UserBioPipeline, feature_category: :markdown do
  subject(:output) { described_class.to_html(markdown, project: nil) }

  describe 'allowed elements' do
    context 'with emphasis' do
      let(:markdown) { '_emphasis_' }

      it { is_expected.to eq('<em>emphasis</em>') }
    end

    context 'with strong emphasis' do
      let(:markdown) { '**strong**' }

      it { is_expected.to eq('<strong>strong</strong>') }
    end

    context 'with code spans' do
      let(:markdown) { '`code`' }

      it { is_expected.to eq('<code>code</code>') }
    end
  end

  describe 'disallowed elements' do
    context 'with links' do
      let(:markdown) { '[text](https://example.com)' }

      it 'strips the link but keeps its text' do
        expect(output).to eq('text')
      end
    end

    context 'with autolinked URLs' do
      let(:markdown) { 'see https://example.com' }

      it 'strips the link but keeps the URL as text' do
        expect(output).to eq('see https://example.com')
      end
    end

    context 'with images' do
      let(:markdown) { '![alt](https://example.com/img.png)' }

      it { is_expected.to eq('') }
    end

    context 'with headings' do
      let(:markdown) { '# heading' }

      it 'strips the heading but keeps its text', :aggregate_failures do
        doc = Nokogiri::HTML.fragment(output)

        expect(doc.css('h1')).to be_empty
        expect(doc.text).to include('heading')
      end
    end

    context 'with lists' do
      let(:markdown) { "- one\n- two" }

      it 'strips the list elements but keeps their text', :aggregate_failures do
        doc = Nokogiri::HTML.fragment(output)

        expect(doc.css('ul, li')).to be_empty
        expect(doc.text).to include('one', 'two')
      end
    end

    context 'with hard line breaks' do
      let(:markdown) { "one\\\ntwo" }

      it 'collapses the break into whitespace' do
        expect(output).to eq("one \ntwo")
      end
    end

    context 'with multiple paragraphs' do
      let(:markdown) { "one\n\ntwo" }

      it 'collapses the paragraphs into whitespace' do
        expect(output).to eq("one \n two")
      end
    end
  end

  describe 'emoji' do
    context 'with emoji shortcodes' do
      let(:markdown) { 'party :tada:' }

      it 'expands shortcodes to gl-emoji', :aggregate_failures do
        doc = Nokogiri::HTML.fragment(output)

        expect(doc.at_css('gl-emoji')['data-name']).to eq('tada')
        expect(doc.text).to eq('party 🎉')
      end
    end

    context 'with unicode emoji' do
      let(:markdown) { 'party 🎉' }

      it 'wraps unicode emoji in gl-emoji', :aggregate_failures do
        doc = Nokogiri::HTML.fragment(output)

        expect(doc.at_css('gl-emoji')['data-name']).to eq('tada')
        expect(doc.text).to eq('party 🎉')
      end
    end
  end

  describe 'sanitization #security' do
    it_behaves_like 'sanitize pipeline', pipeline_renders_links: false

    context 'with script elements' do
      let(:markdown) { '<script>alert(1)</script>' }

      it 'removes the element and its content', :aggregate_failures do
        doc = Nokogiri::HTML.fragment(output)

        expect(doc.css('script')).to be_empty
        expect(doc.text).not_to include('alert')
      end
    end

    context 'with raw anchor elements' do
      let(:markdown) { '<a href="javascript:alert(1)" onclick="alert(1)">text</a>' }

      it 'strips the element and its attributes but keeps its text' do
        expect(output).to eq('text')
      end
    end

    context 'with attributes on allowed elements' do
      let(:markdown) { '<strong class="foo" id="bar" style="color: red" data-x="y" onclick="alert(1)">text</strong>' }

      it 'strips all attributes' do
        expect(output).to eq('<strong>text</strong>')
      end
    end

    context 'with span elements' do
      let(:markdown) { '<span data-math-style="inline">math</span>' }

      it 'strips the element' do
        expect(output).to eq('math')
      end
    end
  end
end
