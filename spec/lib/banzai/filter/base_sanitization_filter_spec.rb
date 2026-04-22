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
end
