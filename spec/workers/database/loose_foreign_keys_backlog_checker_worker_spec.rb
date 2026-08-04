# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::LooseForeignKeysBacklogCheckerWorker,
  :suppress_gitlab_schemas_validate_connection, feature_category: :database do
  let(:worker) { described_class.new }

  let(:mock_result) do
    {
      'main' => [
        {
          'parent_table' => 'public.projects',
          'pending_records' => 49_459,
          'capped' => false,
          'oldest_pending_age_seconds' => 50_000_000,
          'deferred_records' => 0
        }
      ],
      'ci' => []
    }
  end

  describe '#perform', :use_clean_rails_redis_caching do
    before do
      allow(Gitlab::Database::LooseForeignKeysBacklogChecker).to receive(:run).and_return(mock_result)
    end

    it_behaves_like 'an idempotent worker'

    it 'runs the backlog checker and stores results in the cache', :freeze_time do
      expected_data = {
        'metadata' => {
          'last_run_at' => Time.current.iso8601
        },
        'connections' => mock_result
      }

      worker.perform

      stored_data = Gitlab::Json::SafeParser.parse(Rails.cache.read(described_class::BACKLOG_CHECK_CACHE_KEY))
      expect(stored_data).to eq(expected_data)
    end

    context 'when the checker raises an error' do
      let(:error_message) { 'Database connection failed' }

      before do
        allow(Gitlab::Database::LooseForeignKeysBacklogChecker).to receive(:run)
          .and_raise(StandardError, error_message)
      end

      it 'tracks the exception and caches an error result instead of re-raising' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(StandardError))

        expect { worker.perform }.not_to raise_error

        stored_data = Gitlab::Json::SafeParser.parse(Rails.cache.read(described_class::BACKLOG_CHECK_CACHE_KEY))
        expect(stored_data).to include('error' => true, 'message' => error_message)
      end
    end
  end
end
