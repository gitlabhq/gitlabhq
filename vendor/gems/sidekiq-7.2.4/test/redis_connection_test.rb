# frozen_string_literal: true

require_relative "helper"
require "sidekiq/redis_connection"
require "sidekiq/capsule"

describe Sidekiq::RedisConnection do
  describe "create" do
    before do
      @config = reset!
      @config.default_capsule.concurrency = 12
    end

    def client_for(redis)
      redis.instance_variable_get(:@client)
    end

    def config_for(redis)
      redis.config
    end

    def client_class
      Sidekiq::RedisClientAdapter::CompatClient
    end

    it "creates a pooled redis connection" do
      pool = Sidekiq::RedisConnection.create
      assert_equal 5, pool.size
      assert_equal client_class, pool.checkout.class
    end

    it "crashes on RESP2" do
      assert_raises RuntimeError do
        Sidekiq::RedisConnection.create(protocol: 2)
      end
    end

    # Readers for these ivars should be available in the next release of
    # `connection_pool`, until then we need to reach into the internal state to
    # verify the setting.
    describe "size" do
      def client_connection(args = {})
        Sidekiq.stub(:server?, nil) do
          @config.redis = args
          @config.redis_pool
        end
      end

      def server_connection(args = {})
        Sidekiq.stub(:server?, "constant") do
          @config.redis = args
          @config.redis_pool
        end
      end

      it "sizes default pool" do
        pool = server_connection
        assert_equal 10, pool.size
      end

      it "defaults client pool sizes" do
        pool = client_connection
        assert_equal 10, pool.size
      end

      it "sizes capsule pools based on concurrency" do
        assert_equal 12, @config.default_capsule.redis_pool.size
      end

      it "does not change client pool sizes with ENV" do
        # Only Sidekiq::CLI looks at ENV
        ENV["RAILS_MAX_THREADS"] = "9"
        pool = client_connection
        assert_equal 10, pool.size
      ensure
        ENV.delete("RAILS_MAX_THREADS")
      end
    end

    it "disables client setname with nil id" do
      pool = Sidekiq::RedisConnection.create(id: nil)
      assert_equal client_class, pool.checkout.class
      client = client_for(pool.checkout)
      assert_nil client.id
    end

    describe "network_timeout" do
      it "sets a custom network_timeout if specified" do
        pool = Sidekiq::RedisConnection.create(network_timeout: 8)
        redis = pool.checkout

        assert_equal 8, client_for(redis).read_timeout
      end

      it "uses the default network_timeout if none specified" do
        pool = Sidekiq::RedisConnection.create
        redis = pool.checkout
        assert_equal 1.0, client_for(redis).read_timeout
      end
    end

    describe "namespace" do
      it "isn't supported" do
        error = assert_raises ArgumentError do
          Sidekiq::RedisConnection.create(namespace: "xxx")
        end
        assert_includes error.message, "Your Redis configuration uses the namespace 'xxx' but this feature is"
      end
    end

    describe "socket path" do
      it "uses a given :path" do
        pool = Sidekiq::RedisConnection.create(path: "/tmp/redis.sock")
        config = config_for(pool.checkout)
        assert_equal "/tmp/redis.sock", config.path
      end

      it "uses a given :path and :db" do
        pool = Sidekiq::RedisConnection.create(path: "/tmp/redis.sock", db: 8)
        config = config_for(pool.checkout)
        assert_equal "/tmp/redis.sock", config.path
        assert_equal 8, config.db
      end
    end

    describe "pool_timeout" do
      it "uses a given :timeout over the default of 1" do
        pool = Sidekiq::RedisConnection.create(pool_timeout: 5)

        assert_equal 5, pool.instance_eval { @timeout }
      end

      it "uses the default timeout of 1 if no override" do
        pool = Sidekiq::RedisConnection.create

        assert_equal 1, pool.instance_eval { @timeout }
      end
    end

    describe "driver" do
      it "uses ruby driver by default" do
        pool = Sidekiq::RedisConnection.create
        config = config_for(pool.checkout)

        assert_equal RedisClient::RubyConnection, config.driver
      end
    end

    describe "logging redis options" do
      it "redacts credentials" do
        options = {
          role: "master",
          master_name: "mymaster",
          sentinel_password: "secret",
          sentinels: [
            {host: "host1", port: 26379, password: "secret"},
            {host: "host2", port: 26379, password: "secret"},
            {host: "host3", port: 26379, password: "secret"}
          ],
          password: "secret"
        }

        output = capture_logging(@config) do |logger|
          Sidekiq::RedisConnection.create(options.merge(logger: logger))
        end

        refute_includes(options.inspect, "REDACTED")
        refute_includes(output, "secret")
        assert_includes(output, ':host=>"host1", :port=>26379, :password=>"REDACTED"')
        assert_includes(output, ':host=>"host2", :port=>26379, :password=>"REDACTED"')
        assert_includes(output, ':host=>"host3", :port=>26379, :password=>"REDACTED"')
        assert_includes(output, ':password=>"REDACTED"')
      end

      it "prunes SSL parameters from the logging" do
        output = capture_logging(@config) do |logger|
          options = {
            ssl_params: {
              cert_store: OpenSSL::X509::Store.new
            },
            logger: logger
          }

          Sidekiq::RedisConnection.create(options)
          assert_includes(options.inspect, "ssl_params")
        end
        refute_includes(output, "ssl_params")
      end
    end
  end

  describe ".determine_redis_provider" do
    before do
      @old_env = ENV.to_hash
    end

    after do
      ENV.update(@old_env)
    end

    def with_env_var(var, uri, skip_provider = false)
      vars = ["REDISTOGO_URL", "REDIS_PROVIDER", "REDIS_URL"] - [var]
      vars.each do |v|
        next if skip_provider
        ENV[v] = nil
      end
      ENV[var] = uri
      assert_equal uri, Sidekiq::RedisConnection.__send__(:determine_redis_provider)
      ENV[var] = nil
    end

    describe "with REDISTOGO_URL and a parallel REDIS_PROVIDER set" do
      it "sets connection URI to the provider" do
        uri = "redis://sidekiq-redis-provider:6379/0"
        provider = "SIDEKIQ_REDIS_PROVIDER"

        ENV["REDIS_PROVIDER"] = provider
        ENV[provider] = uri
        ENV["REDISTOGO_URL"] = "redis://redis-to-go:6379/0"
        with_env_var provider, uri, true

        ENV[provider] = nil
      end
    end

    describe "with REDIS_PROVIDER set" do
      it "rejects URLs in REDIS_PROVIDER" do
        uri = "redis://sidekiq-redis-provider:6379/0"

        ENV["REDIS_PROVIDER"] = uri

        assert_raises RuntimeError do
          Sidekiq::RedisConnection.__send__(:determine_redis_provider)
        end

        ENV["REDIS_PROVIDER"] = nil
      end

      it "sets connection URI to the provider" do
        uri = "redis://sidekiq-redis-provider:6379/0"
        provider = "SIDEKIQ_REDIS_PROVIDER"

        ENV["REDIS_PROVIDER"] = provider
        ENV[provider] = uri

        with_env_var provider, uri, true

        ENV[provider] = nil
      end
    end

    describe "with REDIS_URL set" do
      it "sets connection URI to custom uri" do
        with_env_var "REDIS_URL", "redis://redis-uri:6379/0"
      end
    end
  end
end
