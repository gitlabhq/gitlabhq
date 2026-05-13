# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::BaseSanitizationFilter, feature_category: :markdown do
  include FilterSpecHelper
  using RSpec::Parameterized::TableSyntax

  let(:filter_class) do
    Class.new(described_class) do
      def customize_allowlist(allowlist)
        # no-op
        allowlist
      end
    end
  end

  # Nested <a> tags are invalid HTML and a security concern: later pipeline
  # filters (ReferenceFilter, ReferenceRedactor) operate on <a> nodes
  # independently, so a nested <a> resolved as a reference can leak its content
  # through the outer <a>'s data-original attribute when the viewer has access
  # to the outer link but not the inner reference.
  #
  # The HTML5 parser can produce nested <a>s via several mechanisms (table
  # foster-parenting, foreign content like <svg>/<math>, <template>).
  # BaseSanitizationFilter removes these regardless of how they were produced.
  describe 'nested anchor tags' do
    it 'does not produce nested anchors (li case)' do
      # The HTML5 parser's adoption agency algorithm separates
      # the <a> tags here: '<a>hello<li>hey<a>hi' parses to
      # '<a>hello</a><li><a>hey</a><a>hi</a></li>'.
      # The sanitiser then removes the <li>. No nesting remains, and all text
      # content is preserved across three sibling <a> tags.
      doc = filter_class.call('<a>hello<li>hey<a>hi')

      expect(doc.css('a a')).to be_empty
      expect(doc.to_html).to eq_html('<a>hello</a><a>hey</a><a>hi</a>')
    end

    it 'does not produce nested anchors (table foster-parenting case)' do
      # HTML5 foster-parenting moves the inner <a> before the <table> but keeps
      # it inside the outer <a>: '<a>foo<a>bar</a><table></table></a>'.
      # The unwrap_nested_a transformer strips the inner <a>, keeping its text.
      doc = filter_class.call('<a>foo<table><a>bar</a></table></a>')

      expect(doc.css('a a')).to be_empty
      expect(doc.at_css('a')).to be_present
      expect(doc.text).to include('foo', 'bar')
    end

    it 'does not produce nested anchors (table>tr>td case)' do
      # The inner <a> sits inside a <td> which survives sanitisation. Unlike
      # the bare foster-parenting case, reparsing alone would not fix this; the
      # nesting is valid HTML5. The unwrap_nested_a transformer handles it.
      doc = filter_class.call('<a>x<table><tr><td><a>y</a></td></tr></table></a>')

      expect(doc.css('a a')).to be_empty
      expect(doc.at_css('a')).to be_present
      expect(doc.text).to include('x', 'y')
    end

    it 'does not produce nested anchors (table>caption case)' do
      doc = filter_class.call('<a>x<table><caption><a>y</a></caption></table></a>')

      expect(doc.css('a a')).to be_empty
      expect(doc.at_css('a')).to be_present
      expect(doc.text).to include('x', 'y')
    end

    it 'does not produce nested anchors via foreign content (svg, math)' do
      # Foreign content (SVG, MathML) does not run the adoption agency
      # algorithm, so <a> tags inside them remain nested within the outer <a>.
      #
      # Currently <svg> and <math> are *stripped* by the allowlist, so
      # sanitisation itself removes the nesting. These tests guard against
      # future allowlist changes that might permit these elements.
      [
        "<a>x<svg><a>y</a></svg></a>",
        "<a>x<math><a>y</a></math></a>"
      ].each do |input|
        doc = filter_class.call(input)

        expect(doc.css('a a')).to be_empty
        expect(doc.at_css('a')).to be_present
        expect(doc.text).to include('x', 'y')
      end
    end

    it 'does not produce nested anchors via deeply nested tables' do
      doc = filter_class.call('<a>x<table><tr><td><table><tr><td><a>y</a></td></tr></table></td></tr></table></a>')

      expect(doc.css('a a')).to be_empty
      expect(doc.at_css('a')).to be_present
      expect(doc.text).to include('x', 'y')
    end
  end

  describe 'namespaced attributes from HTML5 foreign content' do
    # The HTML5 parser creates namespaced attributes inside SVG and MathML
    # foreign content.  For example, <a href="x" xlink:href="y"> inside
    # <svg> produces two attribute nodes that both have local name "href"
    # but live in different XML namespaces.  Nokogiri's remove_attribute
    # may remove the wrong one when duplicates exist, so the sanitisation
    # filter must strip all namespaced attributes before anything else runs.

    it 'strips xlink:href from an SVG anchor, leaving only the HTML href' do
      doc = filter_class.call('<svg><a href="https://safe.example" xlink:href="replaced">link</a></svg>')
      anchor = doc.at_css('a')

      expect(anchor).to be_present
      expect(anchor['href']).to eq('https://safe.example')
      expect(anchor.attribute_nodes.count { |a| a.name == 'href' }).to eq(1)
    end

    it 'strips xlink:href even when no null-namespace href is present' do
      doc = filter_class.call('<svg><a xlink:href="https://example.com">link</a></svg>')
      anchor = doc.at_css('a')

      expect(anchor).to be_present
      expect(anchor.attribute_nodes.select { |a| a.name == 'href' }).to be_empty
    end

    it 'strips xlink:title while keeping the HTML title attribute' do
      doc = filter_class.call(
        '<svg><a href="https://safe.example" xlink:title="injected" title="original">link</a></svg>')
      anchor = doc.at_css('a')

      expect(anchor).to be_present
      expect(anchor['title']).to eq('original')
      expect(anchor.attribute_nodes.count { |a| a.name == 'title' }).to eq(1)
    end

    it 'strips xml:lang from SVG elements' do
      doc = filter_class.call('<svg xml:lang="en"><text>hello</text></svg>')

      expect(doc.to_html).not_to include('xml:lang')
    end

    it 'strips namespaced attributes from MathML foreign content' do
      doc = filter_class.call(
        '<math><annotation-xml encoding="application/xhtml+xml">' \
          '<svg><a href="https://safe.example" xlink:href="replaced">link</a></svg>' \
          '</annotation-xml></math>'
      )
      anchor = doc.at_css('a')

      expect(anchor.attribute_nodes.none?(&:namespace)).to be(true)
    end

    it 'does not affect normal HTML attributes' do
      doc = filter_class.call('<a href="https://example.com" title="hi">link</a>')
      anchor = doc.at_css('a')

      expect(anchor['href']).to eq('https://example.com')
      expect(anchor['title']).to eq('hi')
    end
  end
end
