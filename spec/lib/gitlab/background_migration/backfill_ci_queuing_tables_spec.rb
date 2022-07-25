# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiQueuingTables, :migration,
               :suppress_gitlab_schemas_validate_connection, schema: 20220208115439 do
  let(:namespaces)      { table(:namespaces) }
  let(:projects)        { table(:projects) }
  let(:ci_cd_settings)  { table(:project_ci_cd_settings) }
  let(:builds)          { table(:ci_builds) }
  let(:queuing_entries) { table(:ci_pending_builds) }
  let(:tags)            { table(:tags) }
  let(:taggings)        { table(:taggings) }

  subject { described_class.new }

  describe '#perform' do
    let!(:namespace) do
      namespaces.create!(
        id: 10,
        name: 'namespace10',
        path: 'namespace10',
        traversal_ids: [10])
    end

    let!(:other_namespace) do
      namespaces.create!(
        id: 11,
        name: 'namespace11',
        path: 'namespace11',
        traversal_ids: [11])
    end

    let!(:project) do
      projects.create!(id: 5, namespace_id: 10, name: 'test1', path: 'test1')
    end

    let!(:ci_cd_setting) do
      ci_cd_settings.create!(id: 5, project_id: 5, group_runners_enabled: true)
    end

    let!(:other_project) do
      projects.create!(id: 7, namespace_id: 11, name: 'test2', path: 'test2')
    end

    let!(:other_ci_cd_setting) do
      ci_cd_settings.create!(id: 7, project_id: 7, group_runners_enabled: false)
    end

    let!(:another_project) do
      projects.create!(id: 9, namespace_id: 10, name: 'test3', path: 'test3', shared_runners_enabled: false)
    end

    let!(:ruby_tag) do
      tags.create!(id: 22, name: 'ruby')
    end

    let!(:postgres_tag) do
      tags.create!(id: 23, name: 'postgres')
    end

    it 'creates ci_pending_builds for all pending builds in range' do
      builds.create!(id: 50, status: :pending, name: 'test1', project_id: 5, type: 'Ci::Build')
      builds.create!(id: 51, status: :created, name: 'test2', project_id: 5, type: 'Ci::Build')
      builds.create!(id: 52, status: :pending, name: 'test3', project_id: 5, protected: true, type: 'Ci::Build')

      taggings.create!(taggable_id: 52, taggable_type: 'CommitStatus', tag_id: 22)
      taggings.create!(taggable_id: 52, taggable_type: 'CommitStatus', tag_id: 23)

      builds.create!(id: 60, status: :pending, name: 'test1', project_id: 7, type: 'Ci::Build')
      builds.create!(id: 61, status: :running, name: 'test2', project_id: 7, protected: true, type: 'Ci::Build')
      builds.create!(id: 62, status: :pending, name: 'test3', project_id: 7, type: 'Ci::Build')

      taggings.create!(taggable_id: 60, taggable_type: 'CommitStatus', tag_id: 23)
      taggings.create!(taggable_id: 62, taggable_type: 'CommitStatus', tag_id: 22)

      builds.create!(id: 70, status: :pending, name: 'test1', project_id: 9, protected: true, type: 'Ci::Build')
      builds.create!(id: 71, status: :failed, name: 'test2', project_id: 9, type: 'Ci::Build')
      builds.create!(id: 72, status: :pending, name: 'test3', project_id: 9, type: 'Ci::Build')

      taggings.create!(taggable_id: 71, taggable_type: 'CommitStatus', tag_id: 22)

      subject.perform(1, 100)

      expect(queuing_entries.all).to contain_exactly(
        an_object_having_attributes(
          build_id: 50,
          project_id: 5,
          namespace_id: 10,
          protected: false,
          instance_runners_enabled: true,
          minutes_exceeded: false,
          tag_ids: [],
          namespace_traversal_ids: [10]),
        an_object_having_attributes(
          build_id: 52,
          project_id: 5,
          namespace_id: 10,
          protected: true,
          instance_runners_enabled: true,
          minutes_exceeded: false,
          tag_ids: match_array([22, 23]),
          namespace_traversal_ids: [10]),
        an_object_having_attributes(
          build_id: 60,
          project_id: 7,
          namespace_id: 11,
          protected: false,
          instance_runners_enabled: true,
          minutes_exceeded: false,
          tag_ids: [23],
          namespace_traversal_ids: []),
        an_object_having_attributes(
          build_id: 62,
          project_id: 7,
          namespace_id: 11,
          protected: false,
          instance_runners_enabled: true,
          minutes_exceeded: false,
          tag_ids: [22],
          namespace_traversal_ids: []),
        an_object_having_attributes(
          build_id: 70,
          project_id: 9,
          namespace_id: 10,
          protected: true,
          instance_runners_enabled: false,
          minutes_exceeded: false,
          tag_ids: [],
          namespace_traversal_ids: []),
        an_object_having_attributes(
          build_id: 72,
          project_id: 9,
          namespace_id: 10,
          protected: false,
          instance_runners_enabled: false,
          minutes_exceeded: false,
          tag_ids: [],
          namespace_traversal_ids: [])
      )
    end

    it 'skips builds that already have ci_pending_builds' do
      builds.create!(id: 50, status: :pending, name: 'test1', project_id: 5, type: 'Ci::Build')
      builds.create!(id: 51, status: :created, name: 'test2', project_id: 5, type: 'Ci::Build')
      builds.create!(id: 52, status: :pending, name: 'test3', project_id: 5, protected: true, type: 'Ci::Build')

      taggings.create!(taggable_id: 50, taggable_type: 'CommitStatus', tag_id: 22)
      taggings.create!(taggable_id: 52, taggable_type: 'CommitStatus', tag_id: 23)

      queuing_entries.create!(build_id: 50, project_id: 5, namespace_id: 10)

      subject.perform(1, 100)

      expect(queuing_entries.all).to contain_exactly(
        an_object_having_attributes(
          build_id: 50,
          project_id: 5,
          namespace_id: 10,
          protected: false,
          instance_runners_enabled: false,
          minutes_exceeded: false,
          tag_ids: [],
          namespace_traversal_ids: []),
        an_object_having_attributes(
          build_id: 52,
          project_id: 5,
          namespace_id: 10,
          protected: true,
          instance_runners_enabled: true,
          minutes_exceeded: false,
          tag_ids: [23],
          namespace_traversal_ids: [10])
      )
    end

    it 'upserts values in case of conflicts' do
      builds.create!(id: 50, status: :pending, name: 'test1', project_id: 5, type: 'Ci::Build')
      queuing_entries.create!(build_id: 50, project_id: 5, namespace_id: 10)

      build = described_class::Ci::Build.find(50)
      described_class::Ci::PendingBuild.upsert_from_build!(build)

      expect(queuing_entries.all).to contain_exactly(
        an_object_having_attributes(
          build_id: 50,
          project_id: 5,
          namespace_id: 10,
          protected: false,
          instance_runners_enabled: true,
          minutes_exceeded: false,
          tag_ids: [],
          namespace_traversal_ids: [10])
      )
    end
  end

  context 'Ci::Build' do
    describe '.each_batch' do
      let(:model) { described_class::Ci::Build }

      before do
        builds.create!(id: 1, status: :pending, name: 'test1', project_id: 5, type: 'Ci::Build')
        builds.create!(id: 2, status: :pending, name: 'test2', project_id: 5, type: 'Ci::Build')
        builds.create!(id: 3, status: :pending, name: 'test3', project_id: 5, type: 'Ci::Build')
        builds.create!(id: 4, status: :pending, name: 'test4', project_id: 5, type: 'Ci::Build')
        builds.create!(id: 5, status: :pending, name: 'test5', project_id: 5, type: 'Ci::Build')
      end

      it 'yields an ActiveRecord::Relation when a block is given' do
        model.each_batch do |relation|
          expect(relation).to be_a_kind_of(ActiveRecord::Relation)
        end
      end

      it 'yields a batch index as the second argument' do
        model.each_batch do |_, index|
          expect(index).to eq(1)
        end
      end

      it 'accepts a custom batch size' do
        amount = 0

        model.each_batch(of: 1) { amount += 1 }

        expect(amount).to eq(5)
      end

      it 'does not include ORDER BYs in the yielded relations' do
        model.each_batch do |relation|
          expect(relation.to_sql).not_to include('ORDER BY')
        end
      end

      it 'orders ascending' do
        ids = []

        model.each_batch(of: 1) { |rel| ids.concat(rel.ids) }

        expect(ids).to eq(ids.sort)
      end
    end
  end
end
