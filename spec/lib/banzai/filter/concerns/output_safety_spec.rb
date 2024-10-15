# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Banzai::Filter::Concerns::OutputSafety, feature_category: :markdown do
  subject(:filter) do
    Class.new do
      include Banzai::Filter::Concerns::OutputSafety
    end.new
  end

  let(:content) { '<pre><code>foo</code></pre>' }

  context 'when given HTML is safe' do
    let(:html) { content.html_safe } # rubocop:disable Rails/OutputSafety -- need for testing

    it 'returns safe HTML' do
      expect(filter.escape_once(html)).to eq(html)
    end
  end

  context 'when given HTML is not safe' do
    let(:html) { content }

    it 'returns escaped HTML' do
      expect(filter.escape_once(html)).to eq(ERB::Util.html_escape_once(html))
    end
  end
end
