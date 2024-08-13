# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::PartitionCleanerService, feature_category: :database do
  include MigrationsHelpers

  let(:schema) { ApplicationRecord.connection.current_schema }
  let(:deleted_records) do
    [
      LooseForeignKeys::DeletedRecord.new(
        fully_qualified_table_name: "#{schema}._test_parent_table", primary_key_value: deleted_id
      )
    ]
  end

  let_it_be(:deleted_id) { 1 }

  let(:loose_fk_definition) do
    ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
      '_test_target_table',
      '_test_parent_table',
      {
        column: 'parent_id',
        on_delete: :async_nullify,
        gitlab_schema: :gitlab_main
      }
    )
  end

  subject(:cleaner_service) do
    described_class.new(
      loose_foreign_key_definition: loose_fk_definition,
      connection: ApplicationRecord.connection,
      deleted_parent_records: deleted_records)
  end

  before do
    ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE _test_target_table (
          id bigint NOT NULL,
          parent_id bigint,
          partition_id bigint NOT NULL,
          PRIMARY KEY (id, partition_id)
        ) PARTITION BY LIST(partition_id);

      CREATE TABLE gitlab_partitions_dynamic._test_target_table_100 PARTITION OF _test_target_table
      FOR VALUES IN (100);

      CREATE TABLE gitlab_partitions_dynamic._test_target_table_101 PARTITION OF _test_target_table
      FOR VALUES IN (101);
    SQL

    if ::Gitlab.next_rails?
      table("_test_target_table").create!(id: [1, 100], parent_id: deleted_id)
      table("_test_target_table").create!(id: [2, 101], parent_id: deleted_id)
    else
      table("_test_target_table").create!(id: 1, parent_id: deleted_id, partition_id: 100)
      table("_test_target_table").create!(id: 2, parent_id: deleted_id, partition_id: 101)
    end
  end

  describe 'query generation' do
    context 'when composite primary key is used' do
      it 'generates an IN query for deleting the rows' do
        expected_query = build_expected_query("gitlab_partitions_dynamic\".\"_test_target_table_100")
        expected_query2 = build_expected_query("gitlab_partitions_dynamic\".\"_test_target_table_101")

        expect(ApplicationRecord.connection).to receive(:execute).with(expected_query).and_call_original
        expect(ApplicationRecord.connection).to receive(:execute).with(expected_query2).and_call_original

        cleaner_service.execute
      end

      context 'when the query generation is incorrect (paranoid check)' do
        it 'raises error if the foreign key condition is missing' do
          expect_next_instance_of(LooseForeignKeys::PartitionCleanerService) do |instance|
            expect(instance).to receive(:update_query).and_return('wrong query').twice
          end

          expect(Sidekiq.logger)
            .to receive(:error)
            .with("FATAL: foreign key condition is missing from the generated query: wrong query").twice

          cleaner_service.execute
        end
      end
    end

    context 'when with_skip_locked parameter is true' do
      subject(:cleaner_service) do
        described_class.new(
          loose_foreign_key_definition: loose_fk_definition,
          connection: ApplicationRecord.connection,
          deleted_parent_records: deleted_records,
          with_skip_locked: true
        )
      end

      it 'generates a query with the SKIP LOCKED clause' do
        expect(ApplicationRecord.connection)
          .to receive(:execute)
          .with(/FOR UPDATE SKIP LOCKED/)
          .at_least(:once)
          .and_call_original

        cleaner_service.execute
      end
    end
  end

  def build_expected_query(identifier)
    <<~SQL.squish
      UPDATE \"#{identifier}\" SET "parent_id" = NULL
      WHERE (\"#{identifier}\"."id", \"#{identifier}\"."partition_id")
      IN
        (SELECT \"#{identifier}\"."id", \"#{identifier}\"."partition_id"
        FROM \"#{identifier}\"
        WHERE \"#{identifier}\"."parent_id"
        IN (1)
        LIMIT 500)
    SQL
  end
end
