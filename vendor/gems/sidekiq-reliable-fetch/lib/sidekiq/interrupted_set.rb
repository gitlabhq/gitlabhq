require 'sidekiq/api'

module Sidekiq
  class InterruptedSet < ::Sidekiq::JobSet
    DEFAULT_MAX_CAPACITY = 10_000
    DEFAULT_MAX_TIMEOUT = 90 * 24 * 60 * 60 # 3 months

    def initialize
      super "interrupted"
    end

    def put(message, opts = {})
      now = Time.now.to_f

      with_multi_connection(opts[:connection]) do |conn|
        conn.zadd(name, now.to_s, message)
        conn.zremrangebyscore(name, '-inf', now - self.class.timeout)
        conn.zremrangebyrank(name, 0, - self.class.max_jobs)
      end

      true
    end

    # Yield block inside an existing multi connection or creates new one
    def with_multi_connection(conn, &block)
      return yield(conn) if conn

      Sidekiq.redis do |c|
        c.multi do |multi|
          yield(multi)
        end
      end
    end

    def retry_all
      each(&:retry) while size > 0
    end

    def self.max_jobs
      options[:interrupted_max_jobs] || DEFAULT_MAX_CAPACITY
    end

    def self.timeout
      options[:interrupted_timeout_in_seconds] || DEFAULT_MAX_TIMEOUT
    end

    def self.options
      Sidekiq.default_configuration
    end
  end
end
