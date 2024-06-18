# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ObjectCounter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:tracker) { build(:bulk_import_tracker, id: non_existing_record_id) }
  let_it_be(:cache_key) { "bulk_imports/object_counter/#{tracker.id}" }

  describe '.increment' do
    it 'increments counter by 1' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:hash_increment)
        .with(cache_key, described_class::SOURCE_COUNTER, 1)

      described_class.increment(tracker, described_class::SOURCE_COUNTER)
    end

    it 'increments counter by given value' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:hash_increment)
        .with(cache_key, described_class::SOURCE_COUNTER, 10)

      described_class.increment(tracker, described_class::SOURCE_COUNTER, 10)
    end

    context 'when value is not an integer' do
      it 'does not increment counter' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:hash_increment)

        described_class.increment(tracker, described_class::SOURCE_COUNTER, 'foo')
      end
    end

    context 'when value is less than 1' do
      it 'does not increment counter' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:hash_increment)

        described_class.increment(tracker, described_class::SOURCE_COUNTER, 0)
      end
    end

    context 'when counter type is invalid' do
      it 'does not increment counter' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:hash_increment)

        described_class.increment(tracker, 'foo')
      end
    end
  end

  describe '.set' do
    it 'sets counter to given value' do
      expect(Gitlab::Cache::Import::Caching).to receive(:hash_add).with(cache_key, described_class::SOURCE_COUNTER, 10)

      described_class.set(tracker, described_class::SOURCE_COUNTER, 10)
    end

    context 'when value is not an integer' do
      it 'does not set counter' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:hash_add)

        described_class.set(tracker, described_class::SOURCE_COUNTER, 'foo')
      end
    end

    context 'when value is less than 1' do
      it 'does not set counter' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:hash_add)

        described_class.set(tracker, described_class::SOURCE_COUNTER, 0)
      end
    end

    context 'when counter type is invalid' do
      it 'does not set counter' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:hash_add)

        described_class.set(tracker, 'foo')
      end
    end
  end

  describe '.summary' do
    it 'returns symbolized hash' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:values_from_hash)
        .with(cache_key).and_return({ 'source' => 10 })

      expect(described_class.summary(tracker)).to eq(source: 10, fetched: 0, imported: 0)
    end

    context 'when hash is empty' do
      it 'returns nil' do
        expect(Gitlab::Cache::Import::Caching).to receive(:values_from_hash).with(cache_key).and_return({})

        expect(described_class.summary(tracker)).to be_nil
      end
    end

    context 'when return value is not a hash' do
      it 'returns nil' do
        expect(Gitlab::Cache::Import::Caching).to receive(:values_from_hash).with(cache_key).and_return('foo')

        expect(described_class.summary(tracker)).to be_nil
      end
    end
  end

  describe '.persist!' do
    it 'updates tracker with summary' do
      tracker = create(
        :bulk_import_tracker,
        source_objects_count: 0,
        fetched_objects_count: 0,
        imported_objects_count: 0
      )

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:values_from_hash)
        .with("bulk_imports/object_counter/#{tracker.id}")
        .and_return('source' => 10, 'fetched' => 20, 'imported' => 30)

      described_class.persist!(tracker)

      tracker.reload

      expect(tracker.source_objects_count).to eq(10)
      expect(tracker.fetched_objects_count).to eq(20)
      expect(tracker.imported_objects_count).to eq(30)
    end
  end
end
