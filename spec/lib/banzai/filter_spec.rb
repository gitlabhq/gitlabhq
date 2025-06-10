# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Banzai::Filter, feature_category: :markdown do
  describe '#filter_item_limit_exceeded?' do
    it 'properly detects limits' do
      expect(described_class.filter_item_limit_exceeded?(described_class::FILTER_ITEM_LIMIT - 1)).to be_falsey
      expect(described_class.filter_item_limit_exceeded?(described_class::FILTER_ITEM_LIMIT + 1)).to be_truthy
    end
  end
end
