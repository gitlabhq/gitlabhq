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

  describe 'broken DOMs' do
    it 'does not produce broken DOM via sanitisation' do
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/a#technical_summary:
      # "Permitted content: Transparent, except that no descendant may be interactive
      #  content or an <a> element, ..."
      #
      # Using the HTML4 parser (Nokogiri::HTML), this would parse exactly as it appears (<a>
      # nested within another <a>) and need re-parsing after sanitisation to fix.
      #
      # Using the HTML5 parser (Nokogiri::HTML5), the initial parse step produces
      # '<a>hello</a><li><a>hey</a><a>hi</a></li>', removing the need for any extra hacks.
      doc = filter_class.call('<a>hello<li>hey<a>hi')

      # Our base sanitiser will remove the <li>.
      # There are *no* nested <a>s in the output. This is the main thing we care about,
      # but we assert the whole output for clarity so you can see what actually happens.
      expect(doc.to_html).to eq_html('<a>hello</a><a>hey</a><a>hi</a>')

      # Being super clear:
      expect(doc.css('a a')).to be_empty
    end
  end
end
