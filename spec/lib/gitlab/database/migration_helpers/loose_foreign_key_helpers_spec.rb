# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers do
  let_it_be(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let_it_be(:table_name) { :_test_loose_fk_test_table }

  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = :_test_loose_fk_test_table
    end
  end

  before(:all) do
    migration.create_table table_name do |t|
      t.timestamps
    end
  end

  after(:all) do
    migration.drop_table table_name
  end

  before do
    3.times { model.create! }
  end

  context 'when the record deletion tracker trigger is not installed' do
    it 'does store record deletions' do
      model.delete_all

      expect(LooseForeignKeys::DeletedRecord.count).to eq(0)
    end

    it { expect(migration.has_loose_foreign_key?(table_name)).to be_falsy }
  end

  context 'when the record deletion tracker trigger is installed' do
    before do
      migration.track_record_deletions(table_name)
    end

    it 'stores the record deletion' do
      records = model.all
      record_to_be_deleted = records.last

      record_to_be_deleted.delete

      expect(LooseForeignKeys::DeletedRecord.count).to eq(1)

      arel_table = LooseForeignKeys::DeletedRecord.arel_table
      deleted_record = LooseForeignKeys::DeletedRecord
        .select(arel_table[Arel.star], arel_table[:partition].as('partition_number')) # aliasing the ignored partition column to partition_number
        .all
        .first

      expect(deleted_record.primary_key_value).to eq(record_to_be_deleted.id)
      expect(deleted_record.fully_qualified_table_name).to eq("public.#{table_name}")
      expect(deleted_record.partition_number).to eq(1)
    end

    it 'stores multiple record deletions' do
      model.delete_all

      expect(LooseForeignKeys::DeletedRecord.count).to eq(3)
    end

    it { expect(migration.has_loose_foreign_key?(table_name)).to be_truthy }
  end

  context 'with partitioned tables' do
    let(:current_schema) { migration.connection.current_schema }
    let(:dynamic_partitions_schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }
    let(:partitioned_table) { :_test_partitioned_loose_fk_test_table }
    let(:partitioned_table_identifier) { "#{current_schema}.#{partitioned_table}" }
    let(:partition) { :_test_partition_01 }
    let(:partition_identifier) { "#{dynamic_partitions_schema}.#{partition}" }

    before do
      migration.connection.execute <<~SQL
        CREATE TABLE #{partitioned_table}(
          id serial not null,
          partition_id integer,
          primary key (id, partition_id)
        ) PARTITION BY LIST (partition_id);

        CREATE TABLE #{dynamic_partitions_schema}.#{partition} PARTITION OF #{partitioned_table}
        FOR VALUES IN (1);

        INSERT INTO #{partitioned_table}(id, partition_id) VALUES(1, 1);
        INSERT INTO #{partitioned_table}(id, partition_id) VALUES(2, 1);
        INSERT INTO #{partitioned_table}(id, partition_id) VALUES(3, 1);

        DELETE FROM loose_foreign_keys_deleted_records;
      SQL
    end

    after do
      migration.connection.execute <<~SQL
        DROP TABLE #{partitioned_table} CASCADE;
      SQL
    end

    it 'adds the loose foreign key trigger functionality to the partitioned table' do
      migration.track_record_deletions_override_table_name(partitioned_table_identifier)

      expect do
        migration.connection.execute("DELETE FROM #{partitioned_table}")
      end.to change {
        LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: partitioned_table_identifier).count
      }.by(3)
    end

    it 'adds the loose foreign key trigger functionality to the partition' do
      migration.track_record_deletions_override_table_name(partition_identifier, partitioned_table)

      expect do
        migration.connection.execute("DELETE FROM #{partition_identifier}")
      end.to change {
        # For partitions, we add the LFK deleted_records for the parent partitioned table
        LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: partitioned_table_identifier).count
      }.by(3)
    end

    it 'allows removing the loose foreign key trigger from partitions as well' do
      migration.track_record_deletions_override_table_name(partition_identifier, partitioned_table)
      migration.untrack_record_deletions(partition_identifier)

      expect do
        migration.connection.execute("DELETE FROM #{partition_identifier}")
      end.not_to change {
        LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: partitioned_table_identifier).count
      }
    end
  end
end
