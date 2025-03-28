# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureRunnerTaggingsExist, feature_category: :runner, migration: :gitlab_ci do
  let(:runners_table) { table(:ci_runners, database: :ci, primary_key: :id) }
  let(:runner_taggings_table) { table(:ci_runner_taggings, database: :ci, primary_key: :id) }
  let(:taggings_table) { table(:taggings, database: :ci) }
  let(:tags_table) { table(:tags, database: :ci) }

  let(:instance_runner) { runners_table.create!(runner_type: 1) }
  let(:group_runner) { runners_table.create!(runner_type: 2, sharding_key_id: 10) }
  let(:project_runner) { runners_table.create!(runner_type: 3, sharding_key_id: 11) }

  let(:tag1) { tags_table.create!(name: 'docker') }
  let(:tag2) { tags_table.create!(name: 'postgres') }
  let(:tag3) { tags_table.create!(name: 'ruby') }
  let(:tag4) { tags_table.create!(name: 'golang') }

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

    taggings_table.create!(tag_id: tag3.id, taggable_id: non_existing_record_id,
      taggable_type: 'Ci::Runner', context: :tags)
    taggings_table.create!(tag_id: tag3.id, taggable_id: project_runner.id,
      taggable_type: 'CommitStatus', context: :tags)
  end

  describe '#up' do
    it 'copies records over into ci_runner_taggings' do
      expect { migrate! }
        .to change { runner_taggings_table.count }
        .from(0)
        .to(7)

      expect(tag_ids_from_taggings_for(instance_runner))
        .to match_array(runner_taggings_for(instance_runner).pluck(:tag_id))

      expect(tag_ids_from_taggings_for(group_runner))
        .to match_array(runner_taggings_for(group_runner).pluck(:tag_id))

      expect(tag_ids_from_taggings_for(project_runner))
        .to match_array(runner_taggings_for(project_runner).pluck(:tag_id))

      expect(runner_taggings_for(instance_runner).pluck(:sharding_key_id).uniq)
        .to contain_exactly(nil)

      expect(runner_taggings_for(group_runner).pluck(:sharding_key_id).uniq)
        .to contain_exactly(10)

      expect(runner_taggings_for(project_runner).pluck(:sharding_key_id).uniq)
        .to contain_exactly(11)

      expect(runner_taggings_for(non_existing_record_id)).to be_empty
    end

    context 'when the table is already renamed' do
      before do
        connection.execute(<<~SQL.squish)
          ALTER TABLE ci_runners RENAME TO _test_runners_copy;
          ALTER TABLE ci_runners_e59bb2812d RENAME TO ci_runners;
        SQL
      end

      after do
        connection.execute(<<~SQL.squish)
          ALTER TABLE ci_runners RENAME TO ci_runners_e59bb2812d;
          ALTER TABLE _test_runners_copy RENAME TO ci_runners;
        SQL
      end

      it 'copies records over into ci_runner_taggings' do
        expect { migrate! }
          .to change { runner_taggings_table.count }
          .from(0)
          .to(7)
      end
    end

    context 'when records already exist in ci_runner_taggings' do
      before do
        runner_taggings_table.create!(
          runner_id: instance_runner.id,
          tag_id: tag1.id,
          runner_type: 1
        )
      end

      it 'does not copy records over into ci_runner_taggings' do
        expect { migrate! }
          .not_to change { runner_taggings_table.count }
          .from(1)
      end
    end

    def tag_ids_from_taggings_for(runner)
      taggings_table
        .where(taggable_id: runner, taggable_type: 'Ci::Runner')
        .pluck(:tag_id)
    end

    def runner_taggings_for(runner)
      runner_taggings_table.where(runner_id: runner)
    end
  end
end
