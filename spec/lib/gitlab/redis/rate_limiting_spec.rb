# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RateLimiting do
  include_examples "redis_new_instance_shared_examples", 'rate_limiting', Gitlab::Redis::Cache
end
