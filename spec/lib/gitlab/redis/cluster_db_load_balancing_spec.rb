# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ClusterDbLoadBalancing, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'cluster_db_load_balancing', Gitlab::Redis::SharedState
end
