# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::BufferedCounter, feature_category: :redis do
  include_examples "redis_new_instance_shared_examples", 'buffered_counter', Gitlab::Redis::SharedState
end
