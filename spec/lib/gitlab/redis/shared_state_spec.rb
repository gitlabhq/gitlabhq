# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::SharedState do
  let(:instance_specific_config_file) { "config/redis.shared_state.yml" }

  include_examples "redis_shared_examples"
  include_examples "multi_store_wrapper_shared_examples"
end
