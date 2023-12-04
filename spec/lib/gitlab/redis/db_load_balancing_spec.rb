# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::DbLoadBalancing, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'db_load_balancing', Gitlab::Redis::SharedState
  include_examples "redis_shared_examples"
end
