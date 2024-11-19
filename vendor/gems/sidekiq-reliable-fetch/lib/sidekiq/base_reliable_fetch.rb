# frozen_string_literal: true

require_relative 'interrupted_set'

module Sidekiq
  class BaseReliableFetch
    DEFAULT_CLEANUP_INTERVAL = 60 * 60  # 1 hour
    HEARTBEAT_INTERVAL       = 20       # seconds
    HEARTBEAT_LIFESPAN       = 60       # seconds
    HEARTBEAT_RETRY_DELAY    = 1        # seconds
    WORKING_QUEUE_PREFIX     = 'working'

    # Defines how often we try to take a lease to not flood our
    # Redis server with SET requests
    DEFAULT_LEASE_INTERVAL = 2 * 60 # seconds
    LEASE_KEY              = 'reliable-fetcher-cleanup-lock'

    # Defines the COUNT parameter that will be passed to Redis SCAN command
    SCAN_COUNT = 1000

    # How much time a job can be interrupted
    DEFAULT_MAX_RETRIES_AFTER_INTERRUPTION = 3

    # Regexes for matching working queue keys
    WORKING_QUEUE_REGEX = /#{WORKING_QUEUE_PREFIX}:(queue:.*):([^:]*:[0-9]*:[0-9a-f]*)\z/.freeze
    LEGACY_WORKING_QUEUE_REGEX = /#{WORKING_QUEUE_PREFIX}:(queue:.*):([^:]*:[0-9]*)\z/.freeze

    UnitOfWork = Struct.new(:queue, :job) do
      def acknowledge
        Sidekiq.redis { |conn| conn.lrem(Sidekiq::BaseReliableFetch.working_queue_name(queue), 1, job) }
      end

      def queue_name
        queue.sub(/.*queue:/, '')
      end

      def requeue
        Sidekiq.redis do |conn|
          conn.multi do |multi|
            multi.lpush(queue, job)
            multi.lrem(Sidekiq::BaseReliableFetch.working_queue_name(queue), 1, job)
          end
        end
      end
    end

    def self.setup_reliable_fetch!(config)
      config = config.options unless config.respond_to?(:[])

      fetch_strategy = if config[:semi_reliable_fetch]
                         Sidekiq::SemiReliableFetch
                       else
                         Sidekiq::ReliableFetch
                       end

      config[:fetch_class] = fetch_strategy

      Sidekiq.logger.info('GitLab reliable fetch activated!')

      # Set the heartbeat immediately to prevent a race condition where
      # worker_dead? returns true in another thread. `start_heartbeat_thread`
      # isn't guaranteed to have run before Sidekiq attempts to fetch jobs.
      heartbeat

      start_heartbeat_thread
    end

    def self.start_heartbeat_thread
      Thread.new do
        loop do
          begin
            heartbeat

            sleep HEARTBEAT_INTERVAL
          rescue => e
            Sidekiq.logger.error("Heartbeat thread error: #{e.message}")

            sleep HEARTBEAT_RETRY_DELAY
          end
        end
      end
    end

    def self.hostname
      Socket.gethostname
    end

    def self.process_nonce
      @@process_nonce ||= SecureRandom.hex(6)
    end

    def self.identity
      @@identity ||= "#{hostname}:#{$$}:#{process_nonce}"
    end

    def self.heartbeat
      Sidekiq.redis do |conn|
        conn.set(heartbeat_key(identity), 1, ex: HEARTBEAT_LIFESPAN)
      end

      Sidekiq.logger.debug("Heartbeat for #{identity}")
    end

    def self.worker_dead?(identity, conn)
      !conn.get(heartbeat_key(identity))
    end

    def self.heartbeat_key(identity)
      "reliable-fetcher-heartbeat-#{identity.gsub(':', '-')}"
    end

    def self.working_queue_name(queue)
      "#{WORKING_QUEUE_PREFIX}:#{queue}:#{identity}"
    end

    attr_reader :cleanup_interval, :last_try_to_take_lease_at, :lease_interval,
                :queues, :use_semi_reliable_fetch,
                :strictly_ordered_queues, :config

    def initialize(capsule)
      raise ArgumentError, 'missing queue list' unless capsule.config.queues

      @config = capsule.config
      @interrupted_set = Sidekiq::InterruptedSet.new
      @cleanup_interval = config.fetch(:cleanup_interval, DEFAULT_CLEANUP_INTERVAL)
      @lease_interval = config.fetch(:lease_interval, DEFAULT_LEASE_INTERVAL)
      @last_try_to_take_lease_at = 0
      @strictly_ordered_queues = !!config[:strict]
      @queues = config.queues.map { |q| "queue:#{q}" }
    end

    def retrieve_work
      clean_working_queues! if take_lease

      retrieve_unit_of_work
    end

    def retrieve_unit_of_work
      raise NotImplementedError,
            "#{self.class} does not implement #{__method__}"
    end

    def bulk_requeue(inprogress)
      return if inprogress.empty?

      Sidekiq.redis do |conn|
        inprogress.each do |unit_of_work|
          conn.multi do |multi|
            preprocess_interrupted_job(unit_of_work.job, unit_of_work.queue, multi)

            multi.lrem(self.class.working_queue_name(unit_of_work.queue), 1, unit_of_work.job)
          end
        end
      end
    rescue => e
      Sidekiq.logger.warn("Failed to requeue #{inprogress.size} jobs: #{e.message}")
    end

    private

    def preprocess_interrupted_job(job, queue, conn = nil)
      msg = Sidekiq.load_json(job)
      msg['interrupted_count'] = msg['interrupted_count'].to_i + 1

      if interruption_exhausted?(msg)
        send_to_quarantine(msg, conn)
      else
        requeue_job(queue, msg, conn)
      end
    end

    # If you want this method to be run in a scope of multi connection
    # you need to pass it
    def requeue_job(queue, msg, conn)
      with_connection(conn) do |conn|
        conn.lpush(queue, Sidekiq.dump_json(msg))
      end

      Sidekiq.logger.info(
        message: "Pushed job #{msg['jid']} back to queue #{queue}",
        jid: msg['jid'],
        class: msg['class'],
        queue: queue
      )
    end

    def extract_queue_and_identity(key)
      # New identity format is "{hostname}:{pid}:{randomhex}
      # Old identity format is "{hostname}:{pid}"
      # Queue names may also have colons (namespaced).
      # Expressing this in a single regex is unreadable

      # Test the newer expected format first, only checking the older if necessary
      original_queue, identity = key.scan(WORKING_QUEUE_REGEX).flatten
      return original_queue, identity unless original_queue.nil? || identity.nil?

      key.scan(LEGACY_WORKING_QUEUE_REGEX).flatten
    end

    # Detect "old" jobs and requeue them because the worker they were assigned
    # to probably failed miserably.
    def clean_working_queues!
      Sidekiq.logger.info('Cleaning working queues')

      Sidekiq.redis do |conn|
        conn.scan(match: "#{WORKING_QUEUE_PREFIX}:queue:*", count: SCAN_COUNT) do |key|
          original_queue, identity = extract_queue_and_identity(key)

          next if original_queue.nil? || identity.nil?

          clean_working_queue!(original_queue, key) if self.class.worker_dead?(identity, conn)
        end
      end
    end

    def clean_working_queue!(original_queue, working_queue)
      Sidekiq.redis do |conn|
        while job = conn.rpop(working_queue)
          preprocess_interrupted_job(job, original_queue)
        end
      end
    end

    def interruption_exhausted?(msg)
      return false if max_retries_after_interruption(msg['class']) < 0

      msg['interrupted_count'].to_i >= max_retries_after_interruption(msg['class'])
    end

    def max_retries_after_interruption(worker_class)
      max_retries_after_interruption = nil

      max_retries_after_interruption ||= begin
        Object.const_get(worker_class).sidekiq_options['max_retries_after_interruption']
      rescue NameError
      end

      max_retries_after_interruption ||= config[:max_retries_after_interruption]
      max_retries_after_interruption ||= DEFAULT_MAX_RETRIES_AFTER_INTERRUPTION
      max_retries_after_interruption
    end

    def send_to_quarantine(msg, multi_connection = nil)
      Sidekiq.logger.warn(
        class: msg['class'],
        jid: msg['jid'],
        message: %(Reliable Fetcher: adding dead #{msg['class']} job #{msg['jid']} to interrupted queue)
      )

      begin
        job_class = Object.const_get(msg['class'])
        if job_class.respond_to?(:sidekiq_interruptions_exhausted)
          job_class.interruptions_exhausted_block.call(msg)
        end
      rescue => e
        Sidekiq.logger.error(
          message: 'Failed to call sidekiq_interruption_exhausted',
          class: msg['class'],
          jid: msg['jid'],
          exception: {
            class: e.class.name,
            message: e.message
          }
        )
      end

      job = Sidekiq.dump_json(msg)
      @interrupted_set.put(job, connection: multi_connection)
    end

    # Yield block with an existing connection or creates another one
    def with_connection(conn)
      return yield(conn) if conn

      Sidekiq.redis { |redis_conn| yield(redis_conn) }
    end

    def take_lease
      return unless allowed_to_take_a_lease?

      @last_try_to_take_lease_at = Time.now.to_f

      Sidekiq.redis do |conn|
        conn.set(LEASE_KEY, 1, 'nx', 'ex', cleanup_interval)
      end
    end

    def allowed_to_take_a_lease?
      Time.now.to_f - last_try_to_take_lease_at > lease_interval
    end
  end
end
