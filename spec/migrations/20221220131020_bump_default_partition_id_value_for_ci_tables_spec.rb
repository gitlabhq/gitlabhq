# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BumpDefaultPartitionIdValueForCiTables, :migration, feature_category: :continuous_integration do
  context 'when on sass' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'changes default values' do
      reversible_migration do |migration|
        migration.before -> {
          expect(default_values).not_to include(101)
        }

        migration.after -> {
          expect(default_values).to match_array([101])
        }
      end
    end

    context 'with tables already changed' do
      before do
        active_record_base.connection.execute(<<~SQL)
          ALTER TABLE ci_builds ALTER COLUMN partition_id SET DEFAULT 101
        SQL
      end

      after do
        schema_migrate_down!
      end

      let(:alter_query) do
        /ALTER TABLE "ci_builds" ALTER COLUMN "partition_id" SET DEFAULT 101/
      end

      it 'skips updating already changed tables' do
        recorder = ActiveRecord::QueryRecorder.new { migrate! }

        expect(recorder.log.any?(alter_query)).to be_falsey
        expect(default_values).to match_array([101])
      end
    end
  end

  context 'when self-managed' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

    it 'does not change default values' do
      reversible_migration do |migration|
        migration.before -> {
          expect(default_values).not_to include(101)
        }

        migration.after -> {
          expect(default_values).not_to include(101)
        }
      end
    end
  end

  def default_values
    values = described_class::TABLES.flat_map do |table_name, columns|
      active_record_base
        .connection
        .columns(table_name)
        .select { |column| columns.include?(column.name.to_sym) }
        .map { |column| column.default&.to_i }
    end

    values.uniq
  end
end
