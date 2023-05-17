# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::KeysCountService, :use_clean_rails_memory_store_caching, feature_category: :system_access do
  let(:user) { create(:user) }

  subject { described_class.new(user) }

  it_behaves_like 'a counter caching service'

  describe '#count' do
    before do
      create(:personal_key, user: user)
    end

    it 'returns the number of SSH keys as an Integer' do
      expect(subject.count).to eq(1)
    end

    it 'does not count signing keys' do
      create(:key, usage_type: :signing, user: user)

      expect(subject.count).to eq(1)
    end
  end

  describe '#uncached_count' do
    it 'returns the number of SSH keys' do
      expect(subject.uncached_count).to be_zero
    end
  end

  describe '#cache_key' do
    it 'returns the cache key' do
      expect(subject.cache_key).to eq("users/key-count-service/#{user.id}")
    end
  end
end
