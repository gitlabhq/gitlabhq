# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReplaceWorkItemTypeBackfillNextBatchStrategy, :migration do
  describe '#up' do
    it 'sets the new strategy for existing migrations' do
      migrations = create_migrations(described_class::OLD_STRATEGY_CLASS, 2)

      expect do
        migrate!

        migrations.each(&:reload)
      end.to change { migrations.pluck(:batch_class_name).uniq }.from([described_class::OLD_STRATEGY_CLASS])
                                                                .to([described_class::NEW_STRATEGY_CLASS])
    end
  end

  describe '#down' do
    it 'sets the old strategy for existing migrations' do
      migrations = create_migrations(described_class::NEW_STRATEGY_CLASS, 2)

      expect do
        migrate!
        schema_migrate_down!

        migrations.each(&:reload)
      end.to change { migrations.pluck(:batch_class_name).uniq }.from([described_class::NEW_STRATEGY_CLASS])
                                                                .to([described_class::OLD_STRATEGY_CLASS])
    end
  end

  def create_migrations(batch_class_name, count)
    Array.new(2) { |index| create_background_migration(batch_class_name, [index]) }
  end

  def create_background_migration(batch_class_name, job_arguments)
    migrations_table = table(:batched_background_migrations)

    migrations_table.create!(
      batch_class_name: batch_class_name,
      job_class_name: described_class::JOB_CLASS_NAME,
      max_value: 10,
      batch_size: 5,
      sub_batch_size: 1,
      interval: 2.minutes,
      table_name: :issues,
      column_name: :id,
      total_tuple_count: 10_000,
      pause_ms: 100,
      job_arguments: job_arguments
    )
  end
end
