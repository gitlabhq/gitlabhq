# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Queues do
  let(:instance_specific_config_file) { "config/redis.queues.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_QUEUES_CONFIG_FILE" }
  let(:class_redis_url) { 'redis://localhost:6381' }

  include_examples "redis_shared_examples"
end
