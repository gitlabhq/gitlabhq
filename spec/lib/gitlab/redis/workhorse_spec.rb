# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Workhorse, feature_category: :redis do
  include_examples "redis_new_instance_shared_examples", 'workhorse', Gitlab::Redis::SharedState
  include_examples "redis_shared_examples"
end
