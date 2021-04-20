# frozen_string_literal: true

require 'connection_pool'
require 'mail/smtp_pool/connection'

module Mail
  class SMTPPool
    POOL_DEFAULTS = {
      pool_size: 5,
      pool_timeout: 5
    }.freeze

    class << self
      def create_pool(settings = {})
        pool_settings = POOL_DEFAULTS.merge(settings)
        smtp_settings = settings.reject { |k, v| POOL_DEFAULTS.keys.include?(k) }

        ConnectionPool.new(size: pool_settings[:pool_size], timeout: pool_settings[:pool_timeout]) do
          Mail::SMTPPool::Connection.new(smtp_settings)
        end
      end
    end

    def initialize(settings)
      raise ArgumentError, 'pool is required. You can create one using Mail::SMTPPool.create_pool.' if settings[:pool].nil?

      @pool = settings[:pool]
    end

    def deliver!(mail)
      @pool.with { |conn| conn.deliver!(mail) }
    end
  end
end
