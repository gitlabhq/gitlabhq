# frozen_string_literal: true

require 'spec_helper'
require './keeps/cleanup_unused_partitioned_indexes'

RSpec.describe Keeps::CleanupUnusedPartitionedIndexes::MigrationBuilder, feature_category: :database do
  let(:migration_file) { 'db/post_migrate/20260701000000_remove_unused_index_p_ci_builds_user_id_idx.rb' }
  let(:generator) { instance_double(::PostDeploymentMigration::PostDeploymentMigrationGenerator) }
  let(:file_helper) { instance_double(::Keeps::Helpers::FileHelper) }

  let(:ctx) do
    {
      name: 'p_ci_builds_user_id_idx',
      tablename: 'p_ci_builds',
      columns: [:user_id]
    }
  end

  subject(:builder) { described_class.new }

  before do
    allow(::PostDeploymentMigration::PostDeploymentMigrationGenerator)
      .to receive(:new).and_return(generator)
    allow(generator).to receive_messages(
      invoke_all: [migration_file],
      migration_number: '20260701000000'
    )
    allow(::Keeps::Helpers::FileHelper).to receive(:new).with(migration_file).and_return(file_helper)
    allow(file_helper).to receive(:replace_method_content)
    allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(a_string_matching(%r{db/schema_migrations/}), 'w').and_yield(StringIO.new)
  end

  describe '#build' do
    it 'returns a Result with the migration file, number, and digest path', :aggregate_failures do
      result = builder.build(ctx)

      expect(result.migration_file).to eq(migration_file)
      expect(result.migration_number).to eq('20260701000000')
      expect(result.digest_file).to eq('db/schema_migrations/20260701000000')
    end

    it 'rewrites the stub with the partitioned removal helpers', :aggregate_failures do
      builder.build(ctx)

      expect(file_helper).to have_received(:replace_method_content).with(
        :change,
        a_string_matching(/include Gitlab::Database::PartitioningMigrationHelpers/)
          .and(a_string_matching(/remove_concurrent_partitioned_index_by_name\(TABLE_NAME, INDEX_NAME\)/))
          .and(a_string_matching(/add_concurrent_partitioned_index\(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME\)/)),
        strip_comments_from_file: true
      )
    end

    it 'runs rubocop autocorrect on the new migration' do
      builder.build(ctx)

      expect(::Gitlab::Housekeeper::Shell).to have_received(:rubocop_autocorrect).with(migration_file)
    end
  end

  describe 'unique migration name (private)' do
    it 'returns the base name when short enough' do
      expect(builder.send(:unique_migration_name_for, 'foo')).to eq('remove_unused_index_foo')
    end

    it 'keeps the full filename within the 100-char FilenameLength cap', :aggregate_failures do
      long_name = "index_#{'x' * 100}"
      result = builder.send(:unique_migration_name_for, long_name)

      # 15-char timestamp prefix + name + '.rb' must stay <= 100.
      expect(15 + result.length + 3).to be <= 100
      expect(result).to match(/_[0-9a-f]{8}\z/)
    end
  end
end
