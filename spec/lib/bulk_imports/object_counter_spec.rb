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

  describe '.increment_by_object' do
    it 'increments counter only once for the same entry data' do
      entry_data = { 'id' => 123, 'title' => 'Test Issue' }

      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, entry_data)
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, entry_data)

      summary = described_class.summary(tracker)
      expect(summary[:fetched]).to eq(1)
    end

    it 'increments counter for different entry data' do
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, { 'id' => 1 })
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, { 'id' => 2 })
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, { 'id' => 3 })

      summary = described_class.summary(tracker)

      expect(summary[:fetched]).to eq(3)
    end

    it 'tracks fetched and imported separately' do
      entry_data = { 'id' => 1 }
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, entry_data)
      described_class.increment_by_object(tracker, described_class::IMPORTED_COUNTER, entry_data)

      summary = described_class.summary(tracker)

      expect(summary[:fetched]).to eq(1)
      expect(summary[:imported]).to eq(1)
    end

    it 'handles retry scenario without double-counting any object' do
      # Object 1: succeeds
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, { 'iid' => 1 })
      described_class.increment_by_object(tracker, described_class::IMPORTED_COUNTER, { 'iid' => 1 })

      # Object 2: fails and retries
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, { 'iid' => 2 })
      described_class.increment_by_object(tracker, described_class::IMPORTED_COUNTER, { 'iid' => 2 })

      # Retry object 2
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, { 'iid' => 2 })
      described_class.increment_by_object(tracker, described_class::IMPORTED_COUNTER, { 'iid' => 2 })

      # Object 3: succeeds
      described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, { 'iid' => 3 })
      described_class.increment_by_object(tracker, described_class::IMPORTED_COUNTER, { 'iid' => 3 })

      summary = described_class.summary(tracker)

      expect(summary[:fetched]).to eq(3)
      expect(summary[:imported]).to eq(3)
    end

    context 'when entry is nil' do
      it 'does not increment counter' do
        described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, nil)

        summary = described_class.summary(tracker)

        expect(summary).to be_nil
      end
    end

    context 'when counter type is invalid' do
      it 'does not increment counter' do
        described_class.increment_by_object(tracker, :invalid, { 'id' => 123 })

        summary = described_class.summary(tracker)

        expect(summary).to be_nil
      end
    end

    context 'with NdjsonPipeline entry format [relation_hash, line_num]' do
      it 'increments only once for same entry array' do
        entry_data = { 'id' => 123, 'title' => 'Test Issue' }

        described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, [entry_data, 0])
        described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, [entry_data, 0])

        summary = described_class.summary(tracker)

        expect(summary[:fetched]).to eq(1)
      end

      it 'increments for different objects' do
        described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, [{ 'id' => 1 }, 0])
        described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, [{ 'id' => 2 }, 0])

        summary = described_class.summary(tracker)

        expect(summary[:fetched]).to eq(2)
      end

      it 'increments multiple times when same object data appears at different line numbers' do
        entry_data = { 'id' => 123, 'title' => 'Test Issue' }

        described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, [entry_data, 0])
        described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, [entry_data, 5])

        expect(described_class.summary(tracker)[:fetched]).to eq(2)
      end

      it 'does not increment when first element is not present' do
        described_class.increment_by_object(tracker, described_class::FETCHED_COUNTER, [nil, 0])

        summary = described_class.summary(tracker)

        expect(summary).to be_nil
      end
    end
  end
end
