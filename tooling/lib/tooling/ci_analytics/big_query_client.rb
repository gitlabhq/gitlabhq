# frozen_string_literal: true

require 'google/cloud/bigquery'

module Tooling
  module CiAnalytics
    class BigQueryClient
      GCP_PROJECT_ID = 'gitlab-qa-resources'
      DATASET_ID = 'ci_analytics'
      CACHE_EVENTS_TABLE = 'cache_events'

      def initialize(credentials_path:)
        raise 'credentials_path is required' if credentials_path.to_s.empty?

        @bigquery = Google::Cloud::Bigquery.new(
          project_id: GCP_PROJECT_ID,
          credentials: credentials_path
        )
        @dataset = @bigquery.dataset(DATASET_ID)
      end

      def insert_cache_event(event_data)
        insert_into_table(CACHE_EVENTS_TABLE, event_data)
      end

      private

      def insert_into_table(table_name, data)
        table = @dataset.table(table_name)
        result = table.insert([data])

        if result.success?
          puts "📊 BigQuery: inserted #{table_name} record"
        else
          puts "❌ BigQuery error: #{result.insert_errors}"
        end
      end
    end
  end
end
