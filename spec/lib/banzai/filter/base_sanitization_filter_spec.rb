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
    it 'reparses the output to avoid operating on broken DOMs' do
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/a#technical_summary:
      # "Permitted content: Transparent, except that no descendant may be interactive content
      #  or an <a> element, ..."
      doc = filter_class.call('<a>hello<li><a>hi')

      # Our base sanitiser will remove the <li>. The result should still
      # contain two <a>s, but one must not be nested within another.
      expect(doc.css('a').count).to eq(2)
      expect(doc.css('a a')).to be_empty
      expect(doc.css('li')).to be_empty
    end
  end
end
