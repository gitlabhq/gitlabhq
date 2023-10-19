# frozen_string_literal: true

require 'bundler/setup'
require 'influxdb-client'
require 'json'
require 'date'

module Tooling
  class JobMetrics
    attr_reader :metrics_file_path

    # @return [String] bucket for storing all CI job metrics
    INFLUX_CI_JOB_METRICS_BUCKET = "ci-job-metrics"
    ALLOWED_TYPES = %i[tag field].freeze

    def initialize(metrics_file_path: nil)
      metrics_file_path ||= ENV['JOB_METRICS_FILE_PATH']
      raise "Please specify a path for the job metrics file." unless metrics_file_path

      @metrics_file_path = metrics_file_path
    end

    def create_metrics_file
      if valid_metrics_file?
        warn "A valid job metrics file already exists. We're not going to overwrite it."
        return
      end

      # We always first create tag metrics file with the default values
      persist_metrics_file(default_metrics)
    end

    def update_field(name, value)
      name = name&.to_sym

      unless default_fields.key?(name)
        warn "[job-metrics] ERROR: Could not update field #{name}, as it is not part of the allowed fields."
        return
      end

      update_file(name, value, type: :field)
    end

    def update_tag(name, value)
      name = name&.to_sym

      unless default_tags.key?(name)
        warn "[job-metrics] ERROR: Could not update tag #{name}, as it is not part of the allowed tags."
        return
      end

      update_file(name, value, type: :tag)
    end

    def update_file(name, value, type:)
      unless valid_metrics_file?
        warn "[job-metrics] ERROR: Invalid job metrics file."
        return
      end

      metrics = load_metrics_file
      metrics[:"#{type}s"][name] = value

      persist_metrics_file(metrics)
    end

    def push_metrics
      unless valid_metrics_file?
        warn "[job-metrics] ERROR: Invalid job metrics file. We will not push the metrics to InfluxDB"
        return
      end

      update_field(:job_duration_seconds, (Time.now - job_start_time).to_i)

      metrics = load_metrics_file
      ALLOWED_TYPES.each do |type|
        metrics[:"#{type}s"] = metrics[:"#{type}s"].delete_if { |_, v| v.nil? || v.to_s.empty? }
      end

      influx_write_api.write(data: metrics)

      puts "[job-metrics] Pushed #{metrics.length} CI job metric entries to InfluxDB."
    rescue StandardError => e
      warn "[job-metrics] Failed to push CI job metrics to InfluxDB, error: #{e}"
    end

    def load_metrics_file
      return unless File.exist?(metrics_file_path)

      metrics_hash = JSON.parse(File.read(metrics_file_path), symbolize_names: true) # rubocop:disable Gitlab/Json

      # Inflate the timestamp from string to Time object
      metrics_hash[:time] = Time.parse(metrics_hash[:time]) if metrics_hash[:time]

      metrics_hash
    rescue JSON::ParserError, TypeError
      nil
    end

    def valid_metrics_file?
      metrics = load_metrics_file
      return false unless metrics

      valid_metrics?(metrics)
    end

    def valid_metrics?(metrics_hash)
      default_metrics.keys == metrics_hash.keys &&
        default_tags.keys == metrics_hash[:tags].keys &&
        default_fields.keys == metrics_hash[:fields].keys
    end

    def persist_metrics_file(metrics_hash)
      unless valid_metrics?(metrics_hash)
        warn "cannot persist the metrics, as it doesn't have the correct data structure."
        return
      end

      File.write(metrics_file_path, metrics_hash.to_json)
    end

    def default_metrics
      {
        name: 'job-metrics',
        time: time,
        tags: default_tags,
        fields: default_fields
      }
    end

    def default_tags
      {
        job_name: ENV.fetch('CI_JOB_NAME', nil),
        job_stage: ENV.fetch('CI_JOB_STAGE', nil),
        job_status: ENV.fetch('CI_JOB_STATUS', nil),
        project_id: ENV.fetch('CI_PROJECT_ID', nil),
        rspec_retried_in_new_process: 'false',
        server_host: ENV.fetch('CI_SERVER_HOST', nil)
      }
    end

    def default_fields
      {
        merge_request_iid: ENV.fetch('CI_MERGE_REQUEST_IID', nil),
        pipeline_id: ENV.fetch('CI_PIPELINE_ID', nil),
        job_id: ENV.fetch('CI_JOB_ID', nil),
        job_duration_seconds: nil
      }
    end

    # Single common timestamp for all exported example metrics to keep data points consistently grouped
    #
    # @return [Time]
    def time
      @time ||= begin
        return DateTime.now unless ENV['CI_PIPELINE_CREATED_AT'] # rubocop:disable Lint/NoReturnInBeginEndBlocks

        DateTime.parse(ENV['CI_PIPELINE_CREATED_AT'])
      end
    end

    private

    # Write client
    #
    # @return [WriteApi]
    def influx_write_api
      @write_api ||= influx_client.create_write_api
    end

    # InfluxDb client
    #
    # @return [InfluxDB2::Client]
    def influx_client
      @influx_client ||= InfluxDB2::Client.new(
        ENV["QA_INFLUXDB_URL"] || raise("Missing QA_INFLUXDB_URL env variable"),
        ENV["EP_CI_JOB_METRICS_TOKEN"] || raise("Missing EP_CI_JOB_METRICS_TOKEN env variable"),
        bucket: INFLUX_CI_JOB_METRICS_BUCKET,
        org: "gitlab-qa",
        precision: InfluxDB2::WritePrecision::NANOSECOND
      )
    end

    def job_start_time
      Time.parse(ENV.fetch('CI_JOB_STARTED_AT'))
    end
  end
end
