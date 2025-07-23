# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::CollationCheckerWorker, feature_category: :database do
  let(:worker) { described_class.new }
  let(:mock_result) do
    {
      'main' => {
        'collation_mismatches' => [
          { 'collation_name' => 'en_US.UTF-8', 'stored_version' => '2.28', 'actual_version' => '2.31' }
        ],
        'corrupted_indexes' => [
          { 'index_name' => 'index_projects_on_name', 'corruption_types' => ['structural'] }
        ]
      }
    }
  end

  describe '#perform', :use_clean_rails_redis_caching do
    it_behaves_like 'an idempotent worker'

    it 'runs the collation checker and stores results in Redis' do
      expect(Gitlab::Database::CollationChecker).to receive(:run).with(database_name: 'main').and_return(mock_result)

      expected_data = {
        'metadata' => {
          'last_run_at' => Time.current.iso8601
        },
        'databases' => mock_result
      }

      worker.perform

      stored_data = Gitlab::Json.parse(Rails.cache.read(described_class::COLLATION_CHECK_CACHE_KEY))
      expect(stored_data).to eq(expected_data)
    end

    it 'overwrites previous results when run multiple times' do
      allow(Gitlab::Database::CollationChecker).to receive(:run).with(database_name: 'main').and_return(mock_result)

      worker.perform

      # Second run with different data
      new_result = { 'main' => { 'collation_mismatches' => [], 'corrupted_indexes' => [] } }
      allow(Gitlab::Database::CollationChecker).to receive(:run).with(database_name: 'main').and_return(new_result)

      worker.perform

      stored_data = Gitlab::Json.parse(Rails.cache.read(described_class::COLLATION_CHECK_CACHE_KEY))
      expect(stored_data['databases']).to eq(new_result)
    end

    context 'when CollationChecker raises an error' do
      it 'logs the error and re-raises it' do
        error_message = 'Database connection failed'
        expect(Gitlab::Database::CollationChecker).to receive(:run)
          .with(database_name: 'main')
          .and_raise(StandardError, error_message)

        expect(Gitlab::AppLogger).to receive(:error)
          .with("CollationCheckerWorker failed: #{error_message}")

        expect { worker.perform }.to raise_error(StandardError, error_message)
      end
    end
  end
end
