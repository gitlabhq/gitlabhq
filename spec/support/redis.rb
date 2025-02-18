# frozen_string_literal: true

require 'gitlab/redis'

RSpec.configure do |config|
  config.after(:each, :redis) do
    redis_queues_cleanup!
    redis_queues_metadata_cleanup!
  end

  Gitlab::Redis::ALL_CLASSES.each do |instance_class|
    underscored_name = instance_class.store_name.underscore

    config.around(:each, :"clean_gitlab_redis_#{underscored_name}") do |example|
      public_send("redis_#{underscored_name}_cleanup!")
      redis_queues_metadata_cleanup! if underscored_name == 'queues'

      example.run

      public_send("redis_#{underscored_name}_cleanup!")
      redis_queues_metadata_cleanup! if underscored_name == 'queues'
    end
  end

  config.before(:suite) do
    Gitlab::Redis::ALL_CLASSES.each do |instance_class|
      instance_class.with(&:flushdb)
    end
  end

  config.before(:each, :use_null_store_as_repository_cache) do |example|
    null_store = ActiveSupport::Cache::NullStore.new

    allow(Gitlab::Redis::RepositoryCache).to receive(:cache_store).and_return(null_store)
  end
end
