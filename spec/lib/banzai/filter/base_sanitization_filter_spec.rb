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
  describe 'nested anchor tags' do
    it 'does not produce nested anchors (li case)' do
      # The HTML4 parser produces '<a>hello<li>hey<a>hi</a>\n</li></a>' here.
      # The sanitiser then removes the <li>, resulting in '<a>hellohey<a>hi</a></a>',
      # then unwraps the nested <a>, resulting in '<a>helloheyhi</a>'.
      doc = filter_class.call('<a>hello<li>hey<a>hi')

      expect(doc.css('a a')).to be_empty
      expect(doc.to_html).to eq_html('<a>helloheyhi</a>')
    end

    it 'does not produce nested anchors' do
      # HTML4 parses as: '<a>foo</a><table><a>bar</a></table>'. No problem.
      doc = filter_class.call('<a>foo<table><a>bar</a></table>')

      expect(doc.css('a a')).to be_empty
      expect(doc.at_css('a')).to be_present
      expect(doc.text).to include('foo', 'bar')
    end

    it 'does not produce nested anchors (table>tr>td case)' do
      # HTML4 parses as: '<a>x</a><table><tr><td><a>y</a></td></tr></table>'.
      # No problem.
      doc = filter_class.call('<a>x<table><tr><td><a>y</a></td></tr></table></a>')

      expect(doc.css('a a')).to be_empty
      expect(doc.at_css('a')).to be_present
      expect(doc.text).to include('x', 'y')
    end

    it 'does not produce nested anchors (table>caption case)' do
      # HTML4 parses as: '<a>x</a><table><caption><a>y</a></caption></table>'.
      # No problem.
      doc = filter_class.call('<a>x<table><caption><a>y</a></caption></table></a>')

      expect(doc.css('a a')).to be_empty
      expect(doc.at_css('a')).to be_present
      expect(doc.text).to include('x', 'y')
    end

    it 'does not produce nested anchors via foreign content (svg, math)' do
      # HTML4 parse these as:
      # '<a>x<svg><a>y</a></svg></a>'
      # '<a>x<math><a>y</a></math></a>'
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
      # HTML4 parses as: '<a>x</a><table><tr><td><table><tr><td><a>y</a></td></tr></table></td></tr></table>'.
      # No problem.
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
