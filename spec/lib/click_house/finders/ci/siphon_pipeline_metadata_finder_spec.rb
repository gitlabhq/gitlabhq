# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::SiphonPipelineMetadataFinder, :click_house, :freeze_time,
  feature_category: :fleet_visibility do
  let_it_be(:project) { create(:project) }
  let(:instance) { described_class.new }

  describe 'constants' do
    it 'defines the table and subquery alias', :aggregate_failures do
      expect(described_class::TABLE_NAME).to eq('siphon_ci_pipeline_metadata')
      expect(described_class::SUBQUERY_ALIAS).to eq('pipeline_metadata')
    end
  end

  describe '#to_sql' do
    subject(:sql) { query.to_sql }

    context 'with the bare finder' do
      let(:query) { instance }

      it 'deduplicates on pipeline_id alone and applies the soft-delete filter' do
        ts = '`siphon_ci_pipeline_metadata`.`_siphon_replicated_at`'
        expected_sql =
          'SELECT * FROM (' \
            'SELECT `siphon_ci_pipeline_metadata`.`pipeline_id`, ' \
            "argMax(`siphon_ci_pipeline_metadata`.`traversal_path`, #{ts}) AS traversal_path, " \
            "nullIf(argMax(ifNull(`siphon_ci_pipeline_metadata`.`name`, ''), #{ts}), '') AS name, " \
            "argMax(`siphon_ci_pipeline_metadata`.`_siphon_deleted`, #{ts}) AS _siphon_deleted " \
            'FROM `siphon_ci_pipeline_metadata` GROUP BY pipeline_id) pipeline_metadata ' \
            'WHERE `pipeline_metadata`.`_siphon_deleted` = 0'

        is_expected.to eq(expected_sql)
      end
    end

    describe '.for_container' do
      context 'with a project' do
        let(:project_path) { project.project_namespace.traversal_path(with_organization: true) }
        let(:query) { described_class.for_container(project) }

        it 'matches the exact traversal_path' do
          is_expected.to include("WHERE `siphon_ci_pipeline_metadata`.`traversal_path` = '#{project_path}'")
        end
      end

      context 'with a group' do
        let_it_be(:group) { create(:group) }
        let(:group_path) { group.traversal_path(with_organization: true) }
        let(:query) { described_class.for_container(group) }

        it 'matches the traversal_path prefix' do
          is_expected.to include(
            "WHERE startsWith(`siphon_ci_pipeline_metadata`.`traversal_path`, '#{group_path}')"
          )
        end
      end
    end

    describe '#select narrows the outer projection' do
      let(:query) { instance.select(:pipeline_id, :name) }

      it 'replaces the default *', :aggregate_failures do
        is_expected.to include('SELECT `pipeline_metadata`.`pipeline_id`, `pipeline_metadata`.`name`')
        is_expected.not_to start_with('SELECT *')
      end
    end

    describe '#for_pipeline_ids' do
      context 'with an array of ids' do
        let(:query) { instance.for_pipeline_ids([10, 20]) }

        it { is_expected.to include('`siphon_ci_pipeline_metadata`.`pipeline_id` IN (10, 20)') }
      end

      context 'with a QueryBuilder subquery' do
        let(:query) do
          instance.for_pipeline_ids(ClickHouse::Client::QueryBuilder.new('pipelines').select(:id))
        end

        it 'renders as pipeline_id IN (SELECT ...)' do
          is_expected.to include(
            '`siphon_ci_pipeline_metadata`.`pipeline_id` IN (SELECT `pipelines`.`id` FROM `pipelines`)'
          )
        end
      end
    end
  end

  describe '#to_redacted_sql' do
    subject(:redacted_sql) { described_class.for_container(project).for_pipeline_ids([10, 20]).to_redacted_sql }

    it 'replaces literals with placeholders', :aggregate_failures do
      expect(redacted_sql).to include('?')
      expect(redacted_sql).not_to include(project.project_namespace.traversal_path(with_organization: true))
      expect(redacted_sql).not_to include('10, 20')
    end
  end

  describe 'execution' do
    let_it_be(:pipeline_tier1) { create(:ci_pipeline, project: project) }
    let_it_be(:pipeline_tier2) { create(:ci_pipeline, project: project) }
    let_it_be(:other_project) { create(:project) }

    let(:rows) { ::ClickHouse::Client.select(described_class.for_container(project), :main) }

    subject(:names) { rows.map { |r| r['name'] } }

    before do
      insert_ci_pipeline_metadata_to_siphon([
        { pipeline: pipeline_tier1, name: 'tier-1' },
        { pipeline: pipeline_tier2, name: 'tier-2' }
      ])
    end

    it 'returns one row per pipeline with the deduplicated name' do
      expect(names).to contain_exactly('tier-1', 'tier-2')
    end

    context 'when a row is re-replicated with a newer _siphon_replicated_at' do
      before do
        insert_ci_pipeline_metadata_to_siphon(
          [{ pipeline: pipeline_tier1, name: 'tier-1-renamed' }],
          replicated_at: 1.minute.from_now
        )
      end

      it 'picks the latest version' do
        row = rows.find { |r| r['pipeline_id'] == pipeline_tier1.id }
        expect(row['name']).to eq('tier-1-renamed')
      end
    end

    context 'when the latest version has a NULL name' do
      before do
        insert_ci_pipeline_metadata_to_siphon(
          [{ pipeline: pipeline_tier1, name: nil }],
          replicated_at: 1.minute.from_now
        )
      end

      it 'returns NULL instead of an older non-NULL name' do
        expect(names).to contain_exactly(nil, 'tier-2')
      end
    end

    context 'when the same pipeline_id exists across two partitions' do
      before do
        insert_ci_pipeline_metadata_to_siphon(
          [{ pipeline: pipeline_tier1, name: 'tier-1-moved', partition_id: pipeline_tier1.partition_id + 1 }],
          replicated_at: 1.minute.from_now
        )
      end

      it 'collapses them into one row so the pipelines join does not fan out' do
        expect(names).to contain_exactly('tier-1-moved', 'tier-2')
      end
    end

    context 'when metadata has been soft-deleted' do
      before do
        insert_ci_pipeline_metadata_to_siphon(
          [{ pipeline: pipeline_tier2, name: 'tier-2' }],
          replicated_at: 1.minute.from_now, deleted: true
        )
      end

      it 'excludes the soft-deleted row' do
        expect(names).to contain_exactly('tier-1')
      end
    end

    context 'when the queried project has no metadata' do
      let(:rows) do
        ::ClickHouse::Client.select(described_class.for_container(other_project), :main)
      end

      it { is_expected.to be_empty }
    end

    context 'when metadata from another project is also seeded' do
      let_it_be(:other_pipeline) { create(:ci_pipeline, project: other_project) }

      before do
        insert_ci_pipeline_metadata_to_siphon([{ pipeline: other_pipeline, name: 'other-project-pipeline' }])
      end

      it 'scopes results by traversal_path and excludes other projects' do
        expect(names)
          .to contain_exactly('tier-1', 'tier-2')
          .and not_include('other-project-pipeline')
      end
    end
  end
end
