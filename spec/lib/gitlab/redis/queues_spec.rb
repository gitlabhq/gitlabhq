require 'spec_helper'

describe Gitlab::Redis::Queues do
  let(:config_file_name) { "config/redis.queues.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_QUEUES_CONFIG_FILE" }
  let(:config_old_format_socket) { "spec/fixtures/config/redis_queues_old_format_socket.yml" }
  let(:config_new_format_socket) { "spec/fixtures/config/redis_queues_new_format_socket.yml" }
  let(:old_socket_path) {"/path/to/old/redis.queues.sock" }
  let(:new_socket_path) {"/path/to/redis.queues.sock" }
  let(:config_old_format_host) { "spec/fixtures/config/redis_queues_old_format_host.yml" }
  let(:config_new_format_host) { "spec/fixtures/config/redis_queues_new_format_host.yml" }
  let(:redis_port) { 6381 }
  let(:redis_database) { 11 }
  let(:sentinel_port) { redis_port + 20000 }
  let(:config_with_environment_variable_inside) { "spec/fixtures/config/redis_queues_config_with_env.yml"}
  let(:config_env_variable_url) {"TEST_GITLAB_REDIS_QUEUES_URL"}
  let(:class_redis_url) { Gitlab::Redis::Queues::DEFAULT_REDIS_QUEUES_URL }

  include_examples "redis_shared_examples"
end
