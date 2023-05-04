# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::SharedState do
  let(:instance_specific_config_file) { "config/redis.shared_state.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_SHARED_STATE_CONFIG_FILE" }

  include_examples "redis_shared_examples"
end
