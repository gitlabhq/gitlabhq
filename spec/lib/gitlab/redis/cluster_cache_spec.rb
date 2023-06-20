# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ClusterCache, feature_category: :redis do
  include_examples "redis_new_instance_shared_examples", 'cluster_cache', Gitlab::Redis::Cache
end
