# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ConcurrencyLimit, feature_category: :redis do
  include_examples "redis_new_instance_shared_examples", 'concurrency_limit', Gitlab::Redis::SharedState
end
