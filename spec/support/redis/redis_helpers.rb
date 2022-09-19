# frozen_string_literal: true

module RedisHelpers
  Gitlab::Redis::ALL_CLASSES.each do |instance_class|
    define_method("redis_#{instance_class.store_name.underscore}_cleanup!") do
      instance_class.with(&:flushdb)
    end
  end

  # Usage: reset cached instance config
  def redis_clear_raw_config!(instance_class)
    instance_class.remove_instance_variable(:@_raw_config)
  rescue NameError
    # raised if @_raw_config was not set; ignore
  end
end
