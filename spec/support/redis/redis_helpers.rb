# frozen_string_literal: true

module RedisHelpers
  Gitlab::Redis::ALL_CLASSES.each do |instance_class|
    define_method("redis_#{instance_class.store_name.underscore}_cleanup!") do
      instance_class.with(&:flushdb)
    end
  end
end
