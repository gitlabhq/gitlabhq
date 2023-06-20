# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Chat, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  include_examples "redis_new_instance_shared_examples", 'chat', Gitlab::Redis::Cache
end
