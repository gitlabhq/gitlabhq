# frozen_string_literal: true

require 'spec_helper'
require 'active_support/testing/stream'

RSpec.describe Gitlab::Partitioning::ForeignKeysGenerator, :migration, :silence_stdout,
feature_category: :continuous_integration do
  include ActiveSupport::Testing::Stream
  include MigrationsHelpers

  before do
    ActiveRecord::Schema.define do
      create_table :_test_tmp_builds, force: :cascade do |t|
        t.integer :partition_id
        t.index [:id, :partition_id], unique: true
      end

      create_table :_test_tmp_metadata, force: :cascade do |t|
        t.integer :partition_id
        t.references :builds, foreign_key: { to_table: :_test_tmp_builds, on_delete: :cascade }
      end
    end
  end

  after do
    FileUtils.rm_rf(destination_root)

    table(:schema_migrations).where(version: migrations.map(&:version)).delete_all

    active_record_base.connection.execute(<<~SQL)
      DROP TABLE _test_tmp_metadata;
      DROP TABLE _test_tmp_builds;
    SQL
  end

  let_it_be(:destination_root) { File.expand_path("../tmp", __dir__) }

  let(:generator_config) { { destination_root: destination_root } }
  let(:generator_args) { ['--source', '_test_tmp_metadata', '--target', '_test_tmp_builds', '--database', 'main'] }

  context 'without foreign keys' do
    let(:generator_args) { ['--source', '_test_tmp_metadata', '--target', 'projects', '--database', 'main'] }

    it 'does not generate migrations' do
      output = capture(:stderr) { run_generator }

      expect(migrations).to be_empty
      expect(output).to match(/No FK found between _test_tmp_metadata and projects/)
    end
  end

  context 'with one FK' do
    it 'generates foreign key migrations' do
      run_generator

      expect(migrations.sort_by(&:version).map(&:name)).to eq(%w[
        AddFkIndexToTestTmpMetadataOnPartitionIdAndBuildsId
        AddFkToTestTmpMetadataOnPartitionIdAndBuildsId
        ValidateFkOnTestTmpMetadataPartitionIdAndBuildsId
        RemoveFkToTestTmpBuildsTestTmpMetadataOnBuildsId
      ])

      schema_migrate_up!

      fks = Gitlab::Database::PostgresForeignKey
        .by_referenced_table_identifier('public._test_tmp_builds')
        .by_constrained_table_identifier('public._test_tmp_metadata')

      expect(fks.size).to eq(1)

      foreign_key = fks.first

      expect(foreign_key.name).to end_with('_p')
      expect(foreign_key.constrained_columns).to eq(%w[partition_id builds_id])
      expect(foreign_key.referenced_columns).to eq(%w[partition_id id])
      expect(foreign_key.on_delete_action).to eq('cascade')
      expect(foreign_key.on_update_action).to eq('cascade')

      index = active_record_base.connection.indexes('_test_tmp_metadata').find do |index|
        index.columns == %w[partition_id builds_id]
      end

      expect(index).to be_present
    end
  end

  context 'with many FKs' do
    before do
      ActiveRecord::Schema.define do
        add_reference :_test_tmp_metadata, :job,
          foreign_key: { to_table: :_test_tmp_builds, on_delete: :cascade }
      end
    end

    it 'generates migrations for the selected FK' do
      expect(Thor::LineEditor)
        .to receive(:readline)
        .with('Please select one: [0, 1] (0) ', { default: '0', limited_to: %w[0 1] })
        .and_return('1')

      run_generator

      expect(migrations.sort_by(&:version).map(&:name)).to eq(%w[
        AddFkIndexToTestTmpMetadataOnPartitionIdAndJobId
        AddFkToTestTmpMetadataOnPartitionIdAndJobId
        ValidateFkOnTestTmpMetadataPartitionIdAndJobId
        RemoveFkToTestTmpBuildsTestTmpMetadataOnJobId
      ])
    end
  end

  def run_generator(args = generator_args, config = generator_config)
    described_class.start(args, config)
  end

  # We want to execute only the newly generated migrations
  def migrations_paths
    [File.join(destination_root, 'db', 'post_migrate')]
  end

  # There is no need to migrate down before executing the tests because these
  # migrations were not already executed and we don't need to run it after
  # the tests because we're removing the tables.
  def schema_migrate_down!
    # no-op
  end
end
