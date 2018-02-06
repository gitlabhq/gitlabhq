require 'rails_helper'

describe Appearance do
  subject { build(:appearance) }

  it { is_expected.to be_valid }

  it { is_expected.to have_many(:uploads).dependent(:destroy) }

  describe '.current', :use_clean_rails_memory_store_caching do
    let!(:appearance) { create(:appearance) }

    it 'returns the current appearance row' do
      expect(described_class.current).to eq(appearance)
    end

    it 'caches the result' do
      expect(described_class).to receive(:first).once

      2.times { described_class.current }
    end
  end

  describe '#flush_redis_cache' do
    it 'flushes the cache in Redis' do
      appearance = create(:appearance)

      expect(Rails.cache).to receive(:delete).with(described_class::CACHE_KEY)

      appearance.flush_redis_cache
    end
  end

  describe '#single_appearance_row' do
    it 'adds an error when more than 1 row exists' do
      create(:appearance)

      new_row = build(:appearance)
      new_row.save

      expect(new_row.valid?).to eq(false)
    end
  end
end
