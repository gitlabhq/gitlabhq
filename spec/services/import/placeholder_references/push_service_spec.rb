# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderReferences::PushService, :aggregate_failures, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:import_source) { Import::SOURCE_DIRECT_TRANSFER }
  let(:import_uid) { 1 }

  describe '#execute' do
    let(:composite_key) { nil }
    let(:numeric_key) { 9 }

    subject(:result) do
      described_class.new(
        import_source: import_source,
        import_uid: import_uid,
        source_user_id: 123,
        source_user_namespace_id: 234,
        model: MergeRequest,
        user_reference_column: 'author_id',
        numeric_key: numeric_key,
        composite_key: composite_key
      ).execute
    end

    it 'pushes data to Redis' do
      expected_result = [nil, 'MergeRequest', 234, 9, 123, 'author_id'].to_json

      expect(result).to be_success
      expect(result.payload).to eq(serialized_reference: expected_result)
      expect(set).to contain_exactly(expected_result)
    end

    context 'when composite_key is provided' do
      let(:numeric_key) { nil }
      let(:composite_key) { { 'foo' => 1 } }

      it 'pushes data to Redis containing the composite_key' do
        expected_result = [
          { 'foo' => 1 }, 'MergeRequest', 234, nil, 123, 'author_id'
        ].to_json

        expect(result).to be_success
        expect(result.payload).to eq(serialized_reference: expected_result)
        expect(set).to contain_exactly(expected_result)
      end
    end

    context 'when is invalid' do
      let(:composite_key) { { 'foo' => 1 } }

      it 'does not push data to Redis' do
        expect(result).to be_error
        expect(result.message).to include('numeric_key or composite_key must be present')
        expect(set).to be_empty
      end
    end
  end

  describe '.from_record' do
    let_it_be(:source_user) { create(:import_source_user) }
    let_it_be(:record) { create(:merge_request) }

    subject(:result) do
      described_class.from_record(
        import_source: import_source,
        import_uid: import_uid,
        source_user: source_user,
        record: record,
        user_reference_column: 'author_id'
      ).execute
    end

    it 'pushes data to Redis' do
      expected_result = [nil, 'MergeRequest', source_user.namespace_id, record.id, source_user.id, 'author_id'].to_json

      expect(result).to be_success
      expect(result.payload).to eq(serialized_reference: expected_result)
      expect(set).to contain_exactly(expected_result)
    end
  end

  def set
    Gitlab::Cache::Import::Caching.values_from_set(cache_key)
  end

  def cache_key
    Import::PlaceholderReferences::BaseService.new(
      import_source: import_source,
      import_uid: import_uid
    ).send(:cache_key)
  end
end
