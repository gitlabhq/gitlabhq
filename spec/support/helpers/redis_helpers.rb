# frozen_string_literal: true

module RedisHelpers
  Gitlab::Redis::ALL_CLASSES.each do |instance_class|
    define_method("redis_#{instance_class.store_name.underscore}_cleanup!") do
      instance_class.with(&:flushdb)
    end
  end

  # Defines a class of wrapper that uses `resque.yml` regardless of `config/redis.yml.example`
  # this allows us to test against a standalone Redis even if Cache and SharedState are using
  # Redis Cluster. We do not use queue as it does not perform redis cluster validations.
  def define_helper_redis_store_class(store_name = "Workhorse")
    Class.new(Gitlab::Redis::Wrapper) do
      define_singleton_method(:name) { store_name }

      def config_file_name
        config_file_name = "spec/fixtures/config/redis_new_format_host.yml"
        Rails.root.join(config_file_name).to_s
      end
    end
  end

  def create_redis_store(options, extras = {})
    ::Redis::Store.new(options.merge(extras))
  end
end
