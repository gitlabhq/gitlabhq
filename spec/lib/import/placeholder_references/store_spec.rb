# frozen_string_literal: true

require "spec_helper"

RSpec.describe Import::PlaceholderReferences::Store, :clean_gitlab_redis_shared_state, feature_category: :importers do
  subject(:store) { described_class.new(import_source: 'source', import_uid: 'uid') }

  let(:cache_key) { [:'placeholder-references', 'source', 'uid'].join(':') }

  describe '#add' do
    it 'adds to the set' do
      store.add('foo')

      expect(cache.values_from_set(cache_key)).to eq(['foo'])
    end
  end

  describe '#get' do
    before do
      cache.set_add(cache_key, 'foo')
      cache.set_add(cache_key, 'bar')
      cache.set_add(cache_key, 'baz')
    end

    it 'returns a member in the set' do
      expect(store.get.size).to eq(1)
      expect(store.get.first).to be_in(%w[foo bar baz])
    end

    it 'accepts an argument to return more members' do
      expect(store.get(2).size).to eq(2)
    end
  end

  describe '#remove' do
    it 'removes members from the set' do
      cache.set_add(cache_key, 'foo')
      cache.set_add(cache_key, 'bar')
      cache.set_add(cache_key, 'baz')

      store.remove(%w[foo baz])

      expect(cache.values_from_set(cache_key)).to eq(['bar'])
    end
  end

  describe '#count' do
    it 'returns the count of members in the set' do
      cache.set_add(cache_key, 'foo')
      cache.set_add(cache_key, 'bar')

      expect(store.count).to eq(2)
    end
  end

  describe '#empty?' do
    it 'returns true if the set is empty' do
      expect(store.empty?).to eq(true)
    end

    it 'returns false if the set is not empty' do
      cache.set_add(cache_key, 'foo')

      expect(store.empty?).to eq(false)
    end
  end

  describe '#any?' do
    it 'returns the inverse of #empty?' do
      expect(store).to receive(:empty?).and_return(true)
      expect(store.any?).to eq(false)
    end
  end

  describe '#clear!' do
    it 'removes the values from the cache' do
      store.add('foo')

      expect { store.clear! }.to change { store.count }.from(1).to(0)
    end
  end

  def cache
    Gitlab::Cache::Import::Caching
  end
end
