# frozen_string_literal: true

module Ci
  module PartitioningTesting
    module SchemaHelpers
      DEFAULT_PARTITION = 100

      module_function

      def with_routing_tables
        # model.table_name = :routing_table
        yield
        # ensure
        # model.table_name = :regular_table
      end

      # We're dropping the default values here to ensure that the application code
      # populates the `partition_id` value and it's not falling back on the
      # database default one. We should be able to clean this up after
      # partitioning the tables and substituting the routing table in the model:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/377822
      #
      def setup(connection: Ci::ApplicationRecord.connection)
        each_partitionable_table do |table_name|
          change_column_default(table_name, from: DEFAULT_PARTITION, to: nil, connection: connection)
          change_column_default("p_#{table_name}", from: DEFAULT_PARTITION, to: nil, connection: connection)
          create_test_partition("p_#{table_name}", connection: connection)
        end
      end

      def teardown(connection: Ci::ApplicationRecord.connection)
        each_partitionable_table do |table_name|
          drop_test_partition("p_#{table_name}", connection: connection)
          change_column_default(table_name, from: nil, to: DEFAULT_PARTITION, connection: connection)
          change_column_default("p_#{table_name}", from: nil, to: DEFAULT_PARTITION, connection: connection)
        end
      end

      def each_partitionable_table
        ::Ci::Partitionable::Testing::PARTITIONABLE_MODELS.each do |klass|
          model = klass.safe_constantize
          table_name = model.table_name.delete_prefix('p_')

          yield(table_name)

          model.reset_column_information if model.connected?
        end
      end

      def change_column_default(table_name, from:, to:, connection:)
        return unless table_available?(table_name, connection: connection)

        connection.change_column_default(table_name, :partition_id, from: from, to: to)
      end

      def create_test_partition(table_name, connection:)
        return unless table_available?(table_name, connection: connection)

        drop_test_partition(table_name, connection: connection)

        connection.execute(<<~SQL.squish)
          CREATE TABLE #{full_partition_name(table_name)}
            PARTITION OF #{table_name}
            FOR VALUES IN (#{PartitioningTesting::PartitionIdentifiers.ci_testing_partition_id});
        SQL
      end

      def drop_test_partition(table_name, connection:)
        return unless table_available?(table_name, connection: connection)

        connection.execute(<<~SQL.squish)
          DROP TABLE IF EXISTS #{full_partition_name(table_name)};
        SQL
      end

      def table_available?(table_name, connection:)
        connection.table_exists?(table_name) &&
          connection.column_exists?(table_name, :partition_id)
      end

      def full_partition_name(table_name)
        [
          Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA,
          '._test_gitlab_',
          table_name.delete_prefix('p_'),
          '_partition'
        ].join('')
      end
    end
  end
end
