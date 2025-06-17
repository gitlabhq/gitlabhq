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
