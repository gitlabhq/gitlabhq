# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MoveElasticsearchApplicationSettingsToElasticsearchColumn, feature_category: :global_search do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'updates setting' do
      application_settings.create!(
        elasticsearch_aws: true,
        elasticsearch_url: 'http://localhost:9200',
        elasticsearch_search: true,
        elasticsearch_indexing: true,
        elasticsearch_username: 'elastic',
        elasticsearch_aws_region: 'us-east-1',
        elasticsearch_limit_indexing: true,
        elasticsearch_pause_indexing: true,
        elasticsearch_requeue_workers: true,
        elasticsearch_max_bulk_size_mb: 10,
        elasticsearch_retry_on_failure: true,
        elasticsearch_max_bulk_concurrency: 10,
        elasticsearch_client_request_timeout: 0,
        elasticsearch_worker_number_of_shards: 4,
        elasticsearch_analyzers_smartcn_search: true,
        elasticsearch_analyzers_kuromoji_search: true,
        elasticsearch_analyzers_smartcn_enabled: true,
        elasticsearch_analyzers_kuromoji_enabled: true,
        elasticsearch_indexed_field_length_limit: 10,
        elasticsearch_indexed_file_size_limit_kb: 1024,
        elasticsearch_max_code_indexing_concurrency: 30
      )

      migrate!

      expect(application_settings.last.elasticsearch_url).to eq('http://localhost:9200')
      expect(application_settings.last.elasticsearch).to include(
        {
          'elasticsearch_aws' => true,
          'elasticsearch_search' => true,
          'elasticsearch_indexing' => true,
          'elasticsearch_username' => 'elastic',
          'elasticsearch_aws_region' => 'us-east-1',
          'elasticsearch_aws_access_key' => nil,
          'elasticsearch_limit_indexing' => true,
          'elasticsearch_pause_indexing' => true,
          'elasticsearch_requeue_workers' => true,
          'elasticsearch_max_bulk_size_mb' => 10,
          'elasticsearch_retry_on_failure' => 1,
          'elasticsearch_max_bulk_concurrency' => 10,
          'elasticsearch_client_request_timeout' => 0,
          'elasticsearch_worker_number_of_shards' => 4,
          'elasticsearch_analyzers_smartcn_search' => true,
          'elasticsearch_analyzers_kuromoji_search' => true,
          'elasticsearch_analyzers_smartcn_enabled' => true,
          'elasticsearch_analyzers_kuromoji_enabled' => true,
          'elasticsearch_indexed_field_length_limit' => 10,
          'elasticsearch_indexed_file_size_limit_kb' => 1024,
          'elasticsearch_max_code_indexing_concurrency' => 30
        }
      )
    end
  end

  describe '#down' do
    it 'updates setting' do
      application_settings.create!(
        elasticsearch: {
          elasticsearch_aws: true,
          elasticsearch_search: true,
          elasticsearch_indexing: true,
          elasticsearch_username: 'elastic',
          elasticsearch_aws_region: 'us-east-1',
          elasticsearch_aws_access_key: 'access_key',
          elasticsearch_limit_indexing: true,
          elasticsearch_pause_indexing: true,
          elasticsearch_requeue_workers: true,
          elasticsearch_max_bulk_size_mb: 10,
          elasticsearch_retry_on_failure: 1,
          elasticsearch_max_bulk_concurrency: 10,
          elasticsearch_client_request_timeout: 0,
          elasticsearch_worker_number_of_shards: 4,
          elasticsearch_analyzers_smartcn_search: true,
          elasticsearch_analyzers_kuromoji_search: true,
          elasticsearch_analyzers_smartcn_enabled: true,
          elasticsearch_analyzers_kuromoji_enabled: true,
          elasticsearch_indexed_field_length_limit: 10,
          elasticsearch_indexed_file_size_limit_kb: 1024,
          elasticsearch_max_code_indexing_concurrency: 30
        }
      )

      migrate!
      schema_migrate_down!

      expect(application_settings.last.elasticsearch).to eq({})
    end
  end
end
