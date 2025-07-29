# frozen_string_literal: true

module Tooling
  module CiAnalytics
    class CacheEventBuilder
      def initialize(ci_env)
        @job_id = ci_env[:job_id]
        @job_name = ci_env[:job_name]
        @pipeline_id = ci_env[:pipeline_id]
        @project_id = ci_env[:project_id]
        @merge_request_iid = ci_env[:merge_request_iid]
        @merge_request_target_branch = ci_env[:merge_request_target_branch]
        @pipeline_source = ci_env[:pipeline_source]
        @ref = ci_env[:ref]
        @job_url = ci_env[:job_url]
      end

      def build_bigquery_event(cache_data)
        base_event_data(cache_data).merge({
          job_url: @job_url,
          created_at: Time.now.utc.iso8601
        })
      end

      def build_internal_event_properties(cache_data)
        base_data = base_event_data(cache_data)

        {
          # Built-in internal events fields
          label: base_data[:cache_result],
          property: base_data[:cache_type],
          value: base_data[:cache_operation_duration_seconds]&.round(2),

          # Everything else goes to extra_properties (excluding BigQuery-specific fields)
          extra_properties: base_data.except(
            :cache_result, # Used as :label
            :cache_operation_duration_seconds, # Used as :value
            :job_url,         # BigQuery-specific
            :created_at       # BigQuery-specific
          )
        }
      end

      private

      def base_event_data(cache_data)
        merge_request_iid = @merge_request_iid
        merge_request_iid = nil if merge_request_iid.nil? || merge_request_iid.empty?

        {
          job_id: @job_id.to_i,
          job_name: @job_name,
          pipeline_id: @pipeline_id.to_i,
          project_id: @project_id.to_i,
          merge_request_iid: merge_request_iid&.to_i,
          merge_request_target_branch: @merge_request_target_branch,
          pipeline_source: @pipeline_source,
          ref: @ref,
          cache_key: cache_data[:cache_key],
          cache_type: cache_data[:cache_type],
          cache_operation: cache_data[:cache_operation],
          cache_result: cache_data[:cache_result],
          cache_operation_duration_seconds: cache_data[:duration],
          cache_size_bytes: cache_data[:cache_size_bytes],
          operation_command: cache_data[:operation_command],
          operation_duration_seconds: cache_data[:operation_duration],
          operation_success: cache_data[:operation_success]
        }
      end
    end
  end
end
