# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ClusterSessions, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'cluster_sessions', Gitlab::Redis::SharedState
end
