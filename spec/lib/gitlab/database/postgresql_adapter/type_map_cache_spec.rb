# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlAdapter::TypeMapCache do
  let(:db_config) { ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash }
  let(:adapter_class) { ActiveRecord::ConnectionAdapters::PostgreSQLAdapter }

  before do
    adapter_class.type_map_cache.clear
  end

  describe '#initialize_type_map' do
    it 'caches loading of types in memory' do
      recorder_without_cache = ActiveRecord::QueryRecorder.new(skip_schema_queries: false) { initialize_connection.disconnect! }
      expect(recorder_without_cache.log).to include(a_string_matching(/FROM pg_type/)).exactly(4).times

      recorder_with_cache = ActiveRecord::QueryRecorder.new(skip_schema_queries: false) { initialize_connection.disconnect! }

      expect(recorder_with_cache.count).to be < recorder_without_cache.count

      # There's still one pg_type query left here because `#add_pg_decoders` executes another pg_type query
      # in https://github.com/rails/rails/blob/v6.1.3.2/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L912.
      # This query is much cheaper because it only returns very few records.
      expect(recorder_with_cache.log).to include(a_string_matching(/FROM pg_type/)).once
    end

    it 'only reuses the cache if the connection parameters are exactly the same' do
      initialize_connection.disconnect!

      other_config = db_config.dup
      other_config[:connect_timeout] = db_config[:connect_timeout].to_i + 10

      recorder = ActiveRecord::QueryRecorder.new(skip_schema_queries: false) { initialize_connection(other_config).disconnect! }

      expect(recorder.log).to include(a_string_matching(/FROM pg_type/)).exactly(4).times
    end

    it 'gives each connection its own type map object' do
      conn_a = initialize_connection
      conn_b = initialize_connection

      mapping_a = conn_a.send(:type_map).instance_variable_get(:@mapping)
      mapping_b = conn_b.send(:type_map).instance_variable_get(:@mapping)

      expect(mapping_a).not_to equal(mapping_b)
    ensure
      conn_a&.disconnect!
      conn_b&.disconnect!
    end

    it 'isolates type map clears between connections' do
      conn_a = initialize_connection
      conn_b = initialize_connection

      type_map_b = conn_b.send(:type_map)
      mapping_b_size_before = type_map_b.instance_variable_get(:@mapping).size

      # Simulate what reload_type_map does internally: clear one connection's map
      conn_a.send(:type_map).clear

      mapping_b_size_after = type_map_b.instance_variable_get(:@mapping).size

      expect(mapping_b_size_after).to eq(mapping_b_size_before)
      expect(mapping_b_size_after).to be > 0
    ensure
      conn_a&.disconnect!
      conn_b&.disconnect!
    end

    it 'still avoids pg_type queries for cached connections' do
      initialize_connection.disconnect!

      recorder = ActiveRecord::QueryRecorder.new(skip_schema_queries: false) { initialize_connection.disconnect! }

      expect(recorder.log).to include(a_string_matching(/FROM pg_type/)).once
    end
  end

  describe '#reload_type_map' do
    it 'clears the cache and executes the type map query again' do
      initialize_connection.disconnect!

      connection = initialize_connection
      recorder = ActiveRecord::QueryRecorder.new(skip_schema_queries: false) { connection.reload_type_map }

      expect(recorder.log).to include(a_string_matching(/FROM pg_type/)).exactly(3).times
    end
  end

  def initialize_connection(config = db_config)
    adapter_class.new(config).connect!
  end
end
