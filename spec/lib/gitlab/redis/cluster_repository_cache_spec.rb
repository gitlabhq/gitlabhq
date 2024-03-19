# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ClusterRepositoryCache, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'cluster_repository_cache', Gitlab::Redis::Cache
end
