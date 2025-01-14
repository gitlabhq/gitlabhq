# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CopyRunnerTaggings, feature_category: :runner do
  let(:runners_table) { table(:ci_runners, database: :ci, primary_key: :id) }
  let(:runner_taggings_table) { table(:ci_runner_taggings, database: :ci, primary_key: :id) }
  let(:taggings_table) { table(:taggings, database: :ci) }
  let(:tags_table) { table(:tags, database: :ci) }

  let(:instance_runner) { runners_table.create!(runner_type: 1) }
  let(:group_runner) { runners_table.create!(runner_type: 2, sharding_key_id: 10) }
  let(:project_runner) { runners_table.create!(runner_type: 3, sharding_key_id: 11) }

  let(:old_runner) do
    without_referential_integrity do
      runners_table.create!(runner_type: 2, sharding_key_id: nil)
    end
  end

  let(:deleted_runner) do
    without_referential_integrity do
      runners_table.create!(runner_type: 3, sharding_key_id: 12)
    end
  end

  let(:tag1) { tags_table.create!(name: 'docker') }
  let(:tag2) { tags_table.create!(name: 'postgres') }
  let(:tag3) { tags_table.create!(name: 'ruby') }
  let(:tag4) { tags_table.create!(name: 'golang') }

  let(:migration_attrs) do
    {
      start_id: runners_table.minimum(:id),
      end_id: runners_table.maximum(:id),
      batch_table: :ci_runners,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: connection
    }
  end

  let(:migration) { described_class.new(**migration_attrs) }
  let(:connection) { Ci::ApplicationRecord.connection }

  before do
    taggings_table.create!(tag_id: tag1.id, taggable_id: instance_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag2.id, taggable_id: instance_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag3.id, taggable_id: instance_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag1.id, taggable_id: group_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag2.id, taggable_id: group_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag3.id, taggable_id: project_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag4.id, taggable_id: project_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)

    taggings_table.create!(tag_id: tag3.id, taggable_id: old_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag4.id, taggable_id: deleted_runner.id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag3.id, taggable_id: project_runner.id,
      taggable_type: 'CommitStatus', context: :tags)
  end

  describe '#perform' do
    it 'copies records over into ci_runner_taggings' do
      expect { migration.perform }
        .to change { runner_taggings_table.count }
        .from(0)
        .to(7)

      expect(tag_ids_from_taggings_for(instance_runner))
        .to match_array(runner_tags_for(instance_runner).pluck(:tag_id))

      expect(tag_ids_from_taggings_for(group_runner))
        .to match_array(runner_tags_for(group_runner).pluck(:tag_id))

      expect(tag_ids_from_taggings_for(project_runner))
        .to match_array(runner_tags_for(project_runner).pluck(:tag_id))

      expect(runner_tags_for(instance_runner).pluck(:sharding_key_id).uniq)
        .to contain_exactly(nil)

      expect(runner_tags_for(group_runner).pluck(:sharding_key_id).uniq)
        .to contain_exactly(10)

      expect(runner_tags_for(project_runner).pluck(:sharding_key_id).uniq)
        .to contain_exactly(11)

      expect(runner_tags_for(old_runner)).to be_empty

      expect(runner_tags_for(deleted_runner)).to be_empty
    end

    def tag_ids_from_taggings_for(runner)
      taggings_table
        .where(taggable_id: runner, taggable_type: 'Ci::Runner')
        .pluck(:tag_id)
    end

    def runner_tags_for(runner)
      runner_taggings_table.where(runner_id: runner)
    end
  end

  def without_referential_integrity
    connection.transaction do
      connection.execute('ALTER TABLE ci_runners DISABLE TRIGGER ALL;')
      result = yield
      connection.execute('ALTER TABLE ci_runners ENABLE TRIGGER ALL;')
      result
    end
  end
end
