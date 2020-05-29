# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Chat, :use_clean_rails_memory_store_caching do
  describe '.available?' do
    it 'returns true when the chatops feature is available' do
      stub_feature_flags(chatops: true)

      expect(described_class).to be_available
    end

    it 'returns false when the chatops feature is not available' do
      stub_feature_flags(chatops: false)

      expect(described_class).not_to be_available
    end
  end
end
