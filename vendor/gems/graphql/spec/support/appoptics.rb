# frozen_string_literal: true
# A stub for the AppOpticsAPM agent, so we can make assertions about how it is used
if defined?(AppOpticsAPM) && !AppOpticsAPM.graphql_test
  raise "Expected AppOpticsAPM to be undefined, so that we can define a stub for it."
end

module AppOpticsAPM
  def self.loaded; true; end

  module SDK
    def self.trace(name, kvs)
      $appoptics_tracing_spans << name
      $appoptics_tracing_kvs << kvs.dup
      yield
    end

    def self.get_transaction_name
      $appoptics_tracing_name
    end

    def self.set_transaction_name(name)
      $appoptics_tracing_name = name
    end
  end

  module Config
    class << self
      def [](key)
        config[key.to_sym]
      end

      def []=(key, value)
        config[key.to_sym] = value
      end

      def clear
        config.clear
      end

      def config
        @config ||= {}
      end
    end
  end

  def self.graphql_test
    true
  end
end
