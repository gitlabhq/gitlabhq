# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RepositoryCache, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'repository_cache', Gitlab::Redis::Cache
end
