# frozen_string_literal: true
require 'gitlab/redis'

RSpec.configure do |config|
  config.after(:each, :redis) do
    Sidekiq.redis do |connection|
      connection.redis.flushdb
    end
  end

  Gitlab::Redis::ALL_CLASSES.each do |instance_class|
    underscored_name = instance_class.store_name.underscore

    config.around(:each, :"clean_gitlab_redis_#{underscored_name}") do |example|
      public_send("redis_#{underscored_name}_cleanup!")

      example.run

      public_send("redis_#{underscored_name}_cleanup!")
    end
  end

  config.before(:suite) do
    Gitlab::Redis::ALL_CLASSES.each do |instance_class|
      instance_class.with(&:flushdb)
    end
  end
end
