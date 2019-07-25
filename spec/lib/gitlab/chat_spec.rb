# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Chat, :use_clean_rails_memory_store_caching do
  describe '.available?' do
    it 'returns true when the chatops feature is available' do
      allow(Feature)
        .to receive(:enabled?)
        .with(:chatops, default_enabled: true)
        .and_return(true)

      expect(described_class).to be_available
    end

    it 'returns false when the chatops feature is not available' do
      allow(Feature)
        .to receive(:enabled?)
        .with(:chatops, default_enabled: true)
        .and_return(false)

      expect(described_class).not_to be_available
    end
  end
end
