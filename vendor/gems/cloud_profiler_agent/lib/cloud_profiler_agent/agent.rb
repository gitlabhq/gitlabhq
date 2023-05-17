# frozen_string_literal: true

require "google/cloud/profiler/v2"
require 'googleauth'
require 'stackprof'
require 'logger'

module CloudProfilerAgent
  GoogleCloudProfiler = ::Google::Cloud::Profiler::V2

  PROFILE_TYPES = {
    CPU: :cpu,
    WALL: :wall
  }.freeze
  # This regexp will ensure the service name is valid.
  # See https://cloud.google.com/ruby/docs/reference/google-cloud-profiler-v2/latest/Google-Cloud-Profiler-V2-Deployment#Google__Cloud__Profiler__V2__Deployment_target_instance_
  SERVICE_REGEXP = /^[a-z]([-a-z0-9_.]{0,253}[a-z0-9])?$/

  # Agent interfaces with the CloudProfiler API.
  class Agent
    def initialize(
      service:, project_id:, service_version: nil, instance: nil, zone: nil,
      logger: nil, log_labels: {})
      raise ArgumentError, "service must match #{SERVICE_REGEXP}" unless SERVICE_REGEXP =~ service

      @service = service
      @project_id = project_id

      @labels = { language: 'ruby' }
      @labels[:version] = service_version unless service_version.nil?
      @labels[:zone] = zone unless zone.nil?

      @deployment = GoogleCloudProfiler::Deployment.new(project_id: project_id, target: service, labels: @labels)

      @profile_labels = {}
      @profile_labels[:instance] = instance unless instance.nil?

      @google_profiler = GoogleCloudProfiler::ProfilerService::Client.new

      @logger = logger || ::Logger.new($stdout)
      @log_labels = log_labels
    end

    attr_reader :service, :project_id, :labels, :deployment, :profile_labels, :logger, :log_labels

    def create_google_profile
      google_profile_request = GoogleCloudProfiler::CreateProfileRequest.new(
        deployment: deployment,
        profile_type: PROFILE_TYPES.keys)

      google_profile, wall_time, cpu_time = time { @google_profiler.create_profile(google_profile_request) }

      logger.info(
        gcp_ruby_status: "google profile resource created",
        duration_s: wall_time,
        cpu_s: cpu_time,
        **log_labels
      )

      google_profile
    end

    # start will begin creating profiles in a background thread, looping
    # forever. Exceptions are rescued and logged, and retries are made with
    # exponential backoff.
    def start
      return if @thread&.alive?

      @thread = Thread.new do
        logger.info(
          gcp_ruby_status: "Created new agent thread",
          **log_labels
        )

        Looper.new(logger: logger, log_labels: log_labels).run do
          google_profile = create_google_profile
          google_profile = profile_app(google_profile)
          upload_profile_to_google(google_profile)
        end
      end
    end

    private

    def time
      start_monotonic_time = Gitlab::Metrics::System.monotonic_time
      start_thread_cpu_time = Gitlab::Metrics::System.thread_cpu_time

      result = yield

      finish_monotonic_time = Gitlab::Metrics::System.monotonic_time
      finish_thread_cpu_time = Gitlab::Metrics::System.thread_cpu_time
      [
        result,
        finish_monotonic_time - start_monotonic_time,
        finish_thread_cpu_time - start_thread_cpu_time
      ]
    end

    def stackprof_profile_as_pprof(duration, mode)
      start_time = Time.now

      stackprof, wall_time, cpu_time = time do
        StackProf.run(mode: mode, raw: true, interval: ::Gitlab::StackProf.interval(mode)) do
          sleep(duration)
        end
      end

      logger.info(
        gcp_ruby_status: "stackprof run finished",
        duration_s: wall_time,
        cpu_s: cpu_time,
        **log_labels
      )

      pprof_result, wall_time, cpu_time = time do
        CloudProfilerAgent::PprofBuilder.convert_stackprof(stackprof, start_time, Time.now)
      end

      logger.info(
        gcp_ruby_status: "stackprof to pprof converted",
        duration_s: wall_time,
        cpu_s: cpu_time,
        **log_labels
      )

      pprof_result
    end

    def profile_app(google_profile)
      google_profile.profile_bytes = stackprof_profile_as_pprof(google_profile.duration.seconds,
        PROFILE_TYPES.fetch(google_profile.profile_type))
      google_profile
    end

    def upload_profile_to_google(google_profile)
      start_monotonic_time = Gitlab::Metrics::System.monotonic_time
      start_thread_cpu_time = Gitlab::Metrics::System.thread_cpu_time

      @google_profiler.update_profile(profile: google_profile)

      finish_monotonic_time = Gitlab::Metrics::System.monotonic_time
      finish_thread_cpu_time = Gitlab::Metrics::System.thread_cpu_time
      logger.info(
        gcp_ruby_status: "profile resource updated",
        duration_s: finish_monotonic_time - start_monotonic_time,
        cpu_s: finish_thread_cpu_time - start_thread_cpu_time,
        **log_labels
      )
    end
  end
end
