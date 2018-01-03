require 'spec_helper'

describe Gitlab::Redis::Cache do
  let(:config_file_name) { "config/redis.cache.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_CACHE_CONFIG_FILE" }
  let(:config_old_format_socket) { "spec/fixtures/config/redis_cache_old_format_socket.yml" }
  let(:config_new_format_socket) { "spec/fixtures/config/redis_cache_new_format_socket.yml" }
  let(:old_socket_path) {"/path/to/old/redis.cache.sock" }
  let(:new_socket_path) {"/path/to/redis.cache.sock" }
  let(:config_old_format_host) { "spec/fixtures/config/redis_cache_old_format_host.yml" }
  let(:config_new_format_host) { "spec/fixtures/config/redis_cache_new_format_host.yml" }
  let(:redis_port) { 6380 }
  let(:redis_database) { 10 }
  let(:sentinel_port) { redis_port + 20000 }
  let(:config_with_environment_variable_inside) { "spec/fixtures/config/redis_cache_config_with_env.yml"}
  let(:config_env_variable_url) {"TEST_GITLAB_REDIS_CACHE_URL"}
  let(:class_redis_url) { Gitlab::Redis::Cache::DEFAULT_REDIS_CACHE_URL }

  include_examples "redis_shared_examples"
end
