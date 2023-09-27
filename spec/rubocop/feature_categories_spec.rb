# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../rubocop/feature_categories'

RSpec.describe RuboCop::FeatureCategories, feature_category: :tooling do
  describe '.available' do
    it 'returns a list of available feature categories in a set of strings' do
      expect(described_class.available).to be_a(Set)
      expect(described_class.available).to all(be_a(String))
    end
  end

  describe '.available_with_custom' do
    it 'returns a list of available feature categories' do
      expect(described_class.available_with_custom).to include(described_class.available)
    end

    it 'returns a list containing the custom feature categories' do
      expect(described_class.available_with_custom).to include(described_class::CUSTOM_CATEGORIES)
    end
  end

  describe '.config_checksum' do
    it 'returns a SHA256 digest used by RuboCop to invalid cache' do
      expect(described_class.config_checksum).to match(/^\h{64}$/)
    end
  end
end
