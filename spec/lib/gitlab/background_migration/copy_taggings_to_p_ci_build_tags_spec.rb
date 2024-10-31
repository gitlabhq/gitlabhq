# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CopyTaggingsToPCiBuildTags, :suppress_partitioning_routing_analyzer,
  feature_category: :continuous_integration do
  let(:ci_pipelines_table) { table(:ci_pipelines, database: :ci, primary_key: :id) }
  let(:ci_builds_table) { table(:p_ci_builds, database: :ci, primary_key: :id) }
  let(:ci_build_tags_table) { table(:p_ci_build_tags, database: :ci, primary_key: :id) }
  let(:taggings_table) { table(:taggings, database: :ci) }
  let(:tags_table) { table(:tags, database: :ci) }

  let(:pipeline1) { ci_pipelines_table.create!(partition_id: 100, project_id: 1) }
  let(:pipeline2) { ci_pipelines_table.create!(partition_id: 101, project_id: 2) }

  let(:job1) { ci_builds_table.create!(partition_id: 100, project_id: 1, commit_id: pipeline1.id) }
  let(:job2) { ci_builds_table.create!(partition_id: 100, project_id: 2, commit_id: pipeline1.id) }

  let(:tag1) { tags_table.create!(name: 'docker') }
  let(:tag2) { tags_table.create!(name: 'postgres') }
  let(:tag3) { tags_table.create!(name: 'ruby') }
  let(:tag4) { tags_table.create!(name: 'golang') }

  let(:migration_attrs) do
    {
      start_id: taggings_table.minimum(:id),
      end_id: taggings_table.maximum(:id),
      batch_table: :taggings,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: connection
    }
  end

  let(:migration) { described_class.new(**migration_attrs) }
  let(:connection) { Ci::ApplicationRecord.connection }

  before do
    taggings_table.create!(tag_id: tag1.id, taggable_id: job1.id, taggable_type: 'CommitStatus', context: :tags)
    taggings_table.create!(tag_id: tag2.id, taggable_id: job1.id, taggable_type: 'CommitStatus', context: :tags)
    taggings_table.create!(tag_id: tag3.id, taggable_id: job1.id, taggable_type: 'CommitStatus', context: :tags)
    taggings_table.create!(tag_id: tag1.id, taggable_id: job2.id, taggable_type: 'CommitStatus', context: :tags)
    taggings_table.create!(tag_id: tag2.id, taggable_id: job2.id, taggable_type: 'CommitStatus', context: :tags)
    taggings_table.create!(tag_id: tag4.id, taggable_id: job2.id, taggable_type: 'CommitStatus', context: :tags)
    taggings_table.create!(tag_id: tag3.id, taggable_id: job2.id, taggable_type: 'Ci::Runner', context: :tags)
  end

  describe '#perform' do
    it 'copies records over into p_ci_build_tags', :aggregate_failures do
      expect { migration.perform }
        .to change { ci_build_tags_table.count }
        .from(0)
        .to(6)

      expect(tag_ids_from_taggings_for(job1))
        .to match_array(build_tags_for(job1).pluck(:tag_id))

      expect(tag_ids_from_taggings_for(job2))
        .to match_array(build_tags_for(job2).pluck(:tag_id))

      expect(build_tags_for(job1).pluck(:project_id).uniq)
        .to contain_exactly(1)

      expect(build_tags_for(job2).pluck(:project_id).uniq)
        .to contain_exactly(2)
    end

    def tag_ids_from_taggings_for(job)
      taggings_table
        .where(taggable_id: job, taggable_type: 'CommitStatus')
        .pluck(:tag_id)
    end

    def build_tags_for(job)
      ci_build_tags_table.where(build_id: job)
    end
  end
end
