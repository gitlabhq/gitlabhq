require 'spec_helper'

describe Gitlab::Redis::SharedState do
  let(:config_file_name) { "config/redis.shared_state.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_SHARED_STATE_CONFIG_FILE" }
  let(:config_old_format_socket) { "spec/fixtures/config/redis_shared_state_old_format_socket.yml" }
  let(:config_new_format_socket) { "spec/fixtures/config/redis_shared_state_new_format_socket.yml" }
  let(:old_socket_path) {"/path/to/old/redis.shared_state.sock" }
  let(:new_socket_path) {"/path/to/redis.shared_state.sock" }
  let(:config_old_format_host) { "spec/fixtures/config/redis_shared_state_old_format_host.yml" }
  let(:config_new_format_host) { "spec/fixtures/config/redis_shared_state_new_format_host.yml" }
  let(:redis_port) { 6382 }
  let(:redis_database) { 12 }
  let(:sentinel_port) { redis_port + 20000 }
  let(:config_with_environment_variable_inside) { "spec/fixtures/config/redis_shared_state_config_with_env.yml"}
  let(:config_env_variable_url) {"TEST_GITLAB_REDIS_SHARED_STATE_URL"}
  let(:class_redis_url) { Gitlab::Redis::SharedState::DEFAULT_REDIS_SHARED_STATE_URL }

  include_examples "redis_shared_examples"
end
