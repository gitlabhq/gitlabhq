# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::SchemaCheckerWorker, feature_category: :database do
  let(:mock_result) do
    {
      'schema_check_results' => {
        'main' => {
          'missing_tables' => %w[users projects],
          'missing_indexes' => ['index_users_on_email'],
          'missing_foreign_keys' => ['fk_projects_namespace_id'],
          'missing_sequences' => []
        }
      },
      'metadata' => {
        'last_updated_at' => Time.now.iso8601
      }
    }
  end

  subject(:worker) { described_class.new }

  describe '#perform', :use_clean_rails_redis_caching do
    it_behaves_like 'an idempotent worker'

    it 'runs the schema checker and stores results in Redis' do
      expect_next_instance_of(Gitlab::Database::SchemaChecker) do |instance|
        expect(instance).to receive(:execute).and_return(mock_result)
      end

      worker.perform

      stored_data = Gitlab::Json.parse(Rails.cache.read(described_class::SCHEMA_CHECK_CACHE_KEY))
      expect(stored_data).to eq(mock_result)
    end

    context 'when an error occurs', :freeze_time do
      let(:error_message) { 'Database connection failed' }
      let(:exception) { StandardError.new(error_message) }
      let(:current_time) { Time.current.iso8601 }

      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'tracks the exception and stores error result in Redis' do
        expect_next_instance_of(Gitlab::Database::SchemaChecker) do |instance|
          expect(instance).to receive(:execute).and_raise(exception)
        end

        expect(Rails.cache).to receive(:write).with(
          described_class::SCHEMA_CHECK_CACHE_KEY,
          anything,
          expires_in: 1.hour
        ).and_call_original

        worker.perform

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(exception)

        stored_data = Gitlab::Json.parse(Rails.cache.read(described_class::SCHEMA_CHECK_CACHE_KEY))
        expect(stored_data).to eq({
          'error' => true,
          'message' => error_message,
          'metadata' => {
            'last_run_at' => current_time
          }
        })
      end
    end
  end
end
