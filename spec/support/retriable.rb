# frozen_string_literal: true

Retriable.configure do |config|
  config.multiplier    = 1.0
  config.rand_factor   = 0.0
  config.base_interval = 0
end
