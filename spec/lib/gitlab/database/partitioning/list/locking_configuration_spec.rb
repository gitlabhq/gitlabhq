# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::List::LockingConfiguration, feature_category: :database do
  let(:migration_context) do
    Gitlab::Database::Migration[2.1].new.tap do |migration|
      migration.extend Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers
      migration.extend Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
    end
  end

  let(:locking_order) { %w[table_1 table_2 table_3] }

  subject(:locking_configuration) { described_class.new(migration_context, table_locking_order: locking_order) }

  describe '#locking_statement_for' do
    it 'only includes locking information for tables in the locking specification' do
      expect(subject.locking_statement_for(%w[table_1 table_other])).to eq(subject.locking_statement_for('table_1'))
    end

    it 'is nil when none of the tables match the lock configuration' do
      expect(subject.locking_statement_for('table_other')).to be_nil
    end

    it 'is a lock tables statement' do
      expect(subject.locking_statement_for(%w[table_3 table_2])).to eq(<<~SQL)
        LOCK "table_2", "table_3" IN ACCESS EXCLUSIVE MODE
      SQL
    end

    it 'raises if a table name with schema is passed' do
      expect { subject.locking_statement_for('public.test') }.to raise_error(ArgumentError)
    end
  end

  describe '#lock_ordering_for' do
    it 'is the intersection with the locking specification, in the order of the specification' do
      expect(subject.locking_order_for(%w[table_other table_3 table_1])).to eq(%w[table_1 table_3])
    end

    it 'raises if a table name with schema is passed' do
      expect { subject.locking_order_for('public.test') }.to raise_error(ArgumentError)
    end
  end
end
