# frozen_string_literal: true

RSpec.shared_context 'with a table structure for converting a table to a list partition' do
  let(:migration_context) do
    Gitlab::Database::Migration[2.1].new.tap do |migration|
      migration.extend Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers
      migration.extend Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
    end
  end

  let(:connection) { migration_context.connection }
  let(:table_name) { '_test_table_to_partition' }
  let(:table_identifier) { "#{connection.current_schema}.#{table_name}" }
  let(:partitioning_column) { :partition_number }
  let(:partitioning_default) { 1 }
  let(:single_partitioning_value) { 1 }
  let(:multiple_partitioning_values) { [1, 2, 3, 4] }
  let(:referenced_table_name) { '_test_referenced_table' }
  let(:other_referenced_table_name) { '_test_other_referenced_table' }
  let(:referencing_table_name) { '_test_referencing_table' }
  let(:other_referencing_table_name) { '_test_other_referencing_table' }
  let(:parent_table_name) { "#{table_name}_parent" }
  let(:parent_table_identifier) { "#{connection.current_schema}.#{parent_table_name}" }

  let(:model) { define_batchable_model(table_name, connection: connection) }

  let(:parent_model) { define_batchable_model(parent_table_name, connection: connection) }
  let(:referencing_model) { define_batchable_model(referencing_table_name, connection: connection) }

  before do
    # Suppress printing migration progress
    allow(migration_context).to receive(:puts)
    allow(migration_context.connection).to receive(:transaction_open?).and_return(false)

    connection.execute(<<~SQL)
        create table #{referenced_table_name} (
          id bigserial primary key not null
        )
    SQL

    connection.execute(<<~SQL)
        create table #{other_referenced_table_name} (
          id bigserial primary key not null
        )
    SQL

    connection.execute(<<~SQL)
        insert into #{referenced_table_name} default values;
        insert into #{other_referenced_table_name} default values;
    SQL

    connection.execute(<<~SQL)
        create table #{table_name} (
          id bigserial not null,
          #{partitioning_column} bigint not null default #{partitioning_default},
          referenced_id bigint not null references #{referenced_table_name} (id) on delete cascade,
          other_referenced_id bigint not null references #{other_referenced_table_name} (id) on delete set null,
          primary key (id, #{partitioning_column})
        )
    SQL

    connection.execute(<<~SQL)
      create table #{referencing_table_name} (
        id bigserial primary key not null,
        #{partitioning_column} bigint not null,
        ref_id bigint not null,
        constraint fk_referencing foreign key (#{partitioning_column}, ref_id) references #{table_name} (#{partitioning_column}, id) on delete cascade
      )
    SQL

    connection.execute(<<~SQL)
      create table #{other_referencing_table_name} (
        id bigserial not null,
        #{partitioning_column} bigint not null,
        ref_id bigint not null,
        primary key (#{partitioning_column}, id),
        constraint fk_referencing_other foreign key (#{partitioning_column}, ref_id) references #{table_name} (#{partitioning_column}, id)
      ) partition by hash(#{partitioning_column});

      create table #{other_referencing_table_name}_1
      partition of #{other_referencing_table_name} for values with (modulus 2, remainder 0);

      create table #{other_referencing_table_name}_2
      partition of #{other_referencing_table_name} for values with (modulus 2, remainder 1);
    SQL

    connection.execute(<<~SQL)
        insert into #{table_name} (referenced_id, other_referenced_id)
        select #{referenced_table_name}.id, #{other_referenced_table_name}.id
        from #{referenced_table_name}, #{other_referenced_table_name};
    SQL
  end
end
