# frozen_string_literal: true

require 'spec_helper'

# The gem CI has no Postgres, so the gem's catalog queries are tested here against the test database.
RSpec.describe Gitlab::Schema::Validation::Sources::Database, feature_category: :database do
  subject(:database) { described_class.new(connection) }

  let(:connection) { ApplicationRecord.connection }

  describe '#indexes' do
    let(:index_names) { database.indexes.map(&:name) }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE _test_schema_validation (id bigint, value bigint);
        CREATE INDEX _test_schema_validation_valid ON _test_schema_validation (id);
        CREATE INDEX _test_schema_validation_invalid ON _test_schema_validation (value);
        UPDATE pg_index SET indisvalid = false WHERE indexrelid = '_test_schema_validation_invalid'::regclass;
      SQL
    end

    it 'includes a valid index' do
      expect(index_names).to include('_test_schema_validation_valid')
    end

    it 'excludes an invalid index' do
      expect(index_names).not_to include('_test_schema_validation_invalid')
    end

    context 'when a partition lacks its index' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_schema_validation_partitioned (id bigint, created_at date)
            PARTITION BY RANGE (created_at);
          CREATE TABLE gitlab_partitions_static._test_schema_validation_partitioned_1
            PARTITION OF _test_schema_validation_partitioned FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
          CREATE INDEX _test_schema_validation_partitioned_on_id ON ONLY _test_schema_validation_partitioned (id);
        SQL
      end

      it 'includes the invalid partitioned index' do
        expect(index_names).to include('_test_schema_validation_partitioned_on_id')
      end
    end
  end
end
