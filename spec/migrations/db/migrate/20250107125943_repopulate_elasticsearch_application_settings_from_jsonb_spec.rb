# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RepopulateElasticsearchApplicationSettingsFromJsonb, :aggregate_failures, feature_category: :global_search do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'updates setting' do
      elasticsearch_jsonb = {
        elasticsearch_aws: false,
        elasticsearch_url: 'http://localhost:9200',
        elasticsearch_search: true,
        elasticsearch_indexing: true,
        elasticsearch_username: 'elastic',
        elasticsearch_aws_region: 'us-west-1',
        elasticsearch_limit_indexing: true,
        elasticsearch_pause_indexing: false,
        elasticsearch_requeue_workers: true,
        elasticsearch_max_bulk_size_mb: 20,
        elasticsearch_retry_on_failure: 10,
        elasticsearch_max_bulk_concurrency: 50,
        elasticsearch_client_request_timeout: 0,
        elasticsearch_worker_number_of_shards: 7,
        elasticsearch_analyzers_smartcn_search: false,
        elasticsearch_analyzers_kuromoji_search: true,
        elasticsearch_analyzers_smartcn_enabled: false,
        elasticsearch_analyzers_kuromoji_enabled: true,
        elasticsearch_indexed_field_length_limit: 20,
        elasticsearch_indexed_file_size_limit_kb: 1024,
        elasticsearch_max_code_indexing_concurrency: 60
      }

      application_settings.create!(
        elasticsearch_search: false,
        elasticsearch_indexing: false,
        elasticsearch_limit_indexing: false,
        elasticsearch_pause_indexing: true,
        elasticsearch_requeue_workers: false,
        elasticsearch_max_code_indexing_concurrency: 30,
        elasticsearch: elasticsearch_jsonb
      )

      migrate!

      actual_application_settings = application_settings.last
      expect(actual_application_settings.elasticsearch_aws).to be(false)
      expect(actual_application_settings.elasticsearch_url).to eq('http://localhost:9200')
      expect(actual_application_settings.elasticsearch_search).to be(true)
      expect(actual_application_settings.elasticsearch_indexing).to be(true)
      expect(actual_application_settings.elasticsearch_username).to eq('elastic')
      expect(actual_application_settings.elasticsearch_aws_region).to eq('us-west-1')
      expect(actual_application_settings.elasticsearch_limit_indexing).to be(true)
      expect(actual_application_settings.elasticsearch_pause_indexing).to be(false)
      expect(actual_application_settings.elasticsearch_requeue_workers).to be(true)
      expect(actual_application_settings.elasticsearch_max_bulk_size_mb).to eq(20)
      expect(actual_application_settings.elasticsearch_retry_on_failure).to be(10)
      expect(actual_application_settings.elasticsearch_max_bulk_concurrency).to eq(50)
      expect(actual_application_settings.elasticsearch_client_request_timeout).to eq(0)
      expect(actual_application_settings.elasticsearch_worker_number_of_shards).to eq(7)
      expect(actual_application_settings.elasticsearch_analyzers_smartcn_search).to be(false)
      expect(actual_application_settings.elasticsearch_analyzers_kuromoji_search).to be(true)
      expect(actual_application_settings.elasticsearch_analyzers_smartcn_enabled).to be(false)
      expect(actual_application_settings.elasticsearch_analyzers_kuromoji_enabled).to be(true)
      expect(actual_application_settings.elasticsearch_indexed_field_length_limit).to eq(20)
      expect(actual_application_settings.elasticsearch_indexed_file_size_limit_kb).to eq(1024)
      expect(actual_application_settings.elasticsearch_max_code_indexing_concurrency).to eq(60)
    end

    it 'ignores jsonb keys that do not exist in the database as columns' do
      elasticsearch_jsonb = {
        not_a_column: false,
        elasticsearch_aws: false,
        elasticsearch_url: 'http://localhost:9200',
        elasticsearch_search: true,
        elasticsearch_indexing: true,
        elasticsearch_username: 'elastic',
        elasticsearch_aws_region: 'us-west-1',
        elasticsearch_limit_indexing: true,
        elasticsearch_pause_indexing: false,
        elasticsearch_requeue_workers: true,
        elasticsearch_max_bulk_size_mb: 20,
        elasticsearch_retry_on_failure: 10,
        elasticsearch_max_bulk_concurrency: 50,
        elasticsearch_client_request_timeout: 0,
        elasticsearch_worker_number_of_shards: 7,
        elasticsearch_analyzers_smartcn_search: false,
        elasticsearch_analyzers_kuromoji_search: true,
        elasticsearch_analyzers_smartcn_enabled: false,
        elasticsearch_analyzers_kuromoji_enabled: true,
        elasticsearch_indexed_field_length_limit: 20,
        elasticsearch_indexed_file_size_limit_kb: 1024,
        elasticsearch_max_code_indexing_concurrency: 60
      }

      application_settings.create!(
        elasticsearch: elasticsearch_jsonb
      )

      expect { migrate! }.not_to raise_exception
    end
  end

  describe '#down' do
    it 'does nothing' do
      elasticsearch_jsonb = {
        elasticsearch_aws: false,
        elasticsearch_url: 'http://notlocal:9200',
        elasticsearch_search: true,
        elasticsearch_indexing: true,
        elasticsearch_username: 'elastic1',
        elasticsearch_aws_region: 'us-west-2',
        elasticsearch_limit_indexing: true,
        elasticsearch_pause_indexing: false,
        elasticsearch_requeue_workers: true,
        elasticsearch_max_bulk_size_mb: 200,
        elasticsearch_retry_on_failure: 2,
        elasticsearch_max_bulk_concurrency: 50,
        elasticsearch_client_request_timeout: 0,
        elasticsearch_worker_number_of_shards: 7,
        elasticsearch_analyzers_smartcn_search: false,
        elasticsearch_analyzers_kuromoji_search: true,
        elasticsearch_analyzers_smartcn_enabled: false,
        elasticsearch_analyzers_kuromoji_enabled: true,
        elasticsearch_indexed_field_length_limit: 20,
        elasticsearch_indexed_file_size_limit_kb: 1024,
        elasticsearch_max_code_indexing_concurrency: 60
      }

      application_settings.create!(
        elasticsearch_search: false,
        elasticsearch_indexing: false,
        elasticsearch_limit_indexing: false,
        elasticsearch_pause_indexing: true,
        elasticsearch_requeue_workers: false,
        elasticsearch_max_code_indexing_concurrency: 30,
        elasticsearch: elasticsearch_jsonb
      )

      migrate!
      schema_migrate_down!

      actual_application_settings = application_settings.last
      expect(actual_application_settings.elasticsearch_aws).to be(false)
      expect(actual_application_settings.elasticsearch_url).to eq('http://notlocal:9200')
      expect(actual_application_settings.elasticsearch_search).to be(true)
      expect(actual_application_settings.elasticsearch_indexing).to be(true)
      expect(actual_application_settings.elasticsearch_username).to eq('elastic1')
      expect(actual_application_settings.elasticsearch_aws_region).to eq('us-west-2')
      expect(actual_application_settings.elasticsearch_limit_indexing).to be(true)
      expect(actual_application_settings.elasticsearch_pause_indexing).to be(false)
      expect(actual_application_settings.elasticsearch_requeue_workers).to be(true)
      expect(actual_application_settings.elasticsearch_max_bulk_size_mb).to eq(200)
      expect(actual_application_settings.elasticsearch_retry_on_failure).to be(2)
      expect(actual_application_settings.elasticsearch_max_bulk_concurrency).to eq(50)
      expect(actual_application_settings.elasticsearch_client_request_timeout).to eq(0)
      expect(actual_application_settings.elasticsearch_worker_number_of_shards).to eq(7)
      expect(actual_application_settings.elasticsearch_analyzers_smartcn_search).to be(false)
      expect(actual_application_settings.elasticsearch_analyzers_kuromoji_search).to be(true)
      expect(actual_application_settings.elasticsearch_analyzers_smartcn_enabled).to be(false)
      expect(actual_application_settings.elasticsearch_analyzers_kuromoji_enabled).to be(true)
      expect(actual_application_settings.elasticsearch_indexed_field_length_limit).to eq(20)
      expect(actual_application_settings.elasticsearch_indexed_file_size_limit_kb).to eq(1024)
      expect(actual_application_settings.elasticsearch_max_code_indexing_concurrency).to eq(60)
    end
  end
end
