# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedJob, type: :model do
  it_behaves_like 'having unique enum values'

  describe 'associations' do
    it { is_expected.to belong_to(:batched_migration).with_foreign_key(:batched_background_migration_id) }
  end

  describe 'delegated batched_migration attributes' do
    let(:batched_job) { build(:batched_background_migration_job) }
    let(:batched_migration) { batched_job.batched_migration }

    describe '#migration_aborted?' do
      before do
        batched_migration.status = :aborted
      end

      it 'returns the migration aborted?' do
        expect(batched_job.migration_aborted?).to eq(batched_migration.aborted?)
      end
    end

    describe '#migration_job_class' do
      it 'returns the migration job_class' do
        expect(batched_job.migration_job_class).to eq(batched_migration.job_class)
      end
    end

    describe '#migration_table_name' do
      it 'returns the migration table_name' do
        expect(batched_job.migration_table_name).to eq(batched_migration.table_name)
      end
    end

    describe '#migration_column_name' do
      it 'returns the migration column_name' do
        expect(batched_job.migration_column_name).to eq(batched_migration.column_name)
      end
    end

    describe '#migration_job_arguments' do
      it 'returns the migration job_arguments' do
        expect(batched_job.migration_job_arguments).to eq(batched_migration.job_arguments)
      end
    end
  end
end
