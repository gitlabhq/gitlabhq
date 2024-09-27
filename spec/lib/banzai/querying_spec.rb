# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Banzai::Querying, feature_category: :markdown do
  describe '.css' do
    it 'optimizes queries for elements with classes' do
      document = double(:document)

      expect(document).to receive(:xpath).with(/^descendant::a/)

      described_class.css(document, 'a.gfm')
    end
  end
end
