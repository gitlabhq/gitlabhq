# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::SiphonStagesFinder, :click_house, :freeze_time,
  feature_category: :fleet_visibility do
  let_it_be(:project) { create(:project) }
  let(:instance) { described_class.new }

  describe 'constants' do
    it 'defines the table and subquery alias', :aggregate_failures do
      expect(described_class::TABLE_NAME).to eq('siphon_p_ci_stages')
      expect(described_class::SUBQUERY_ALIAS).to eq('stages')
    end
  end

  describe '#to_sql' do
    subject(:sql) { query.to_sql }

    context 'with the bare finder' do
      let(:query) { instance }

      it 'emits the full deduplicated SQL with the soft-delete filter' do
        ts = '`siphon_p_ci_stages`.`_siphon_replicated_at`'
        expected_sql =
          'SELECT * FROM (' \
            'SELECT `siphon_p_ci_stages`.`id`, `siphon_p_ci_stages`.`partition_id`, ' \
            "argMax(`siphon_p_ci_stages`.`traversal_path`, #{ts}) AS traversal_path, " \
            "argMax(`siphon_p_ci_stages`.`pipeline_id`, #{ts}) AS pipeline_id, " \
            "argMax(`siphon_p_ci_stages`.`name`, #{ts}) AS name, " \
            "argMax(`siphon_p_ci_stages`.`_siphon_deleted`, #{ts}) AS _siphon_deleted " \
            'FROM `siphon_p_ci_stages` GROUP BY id, partition_id) stages ' \
            'WHERE `stages`.`_siphon_deleted` = 0'

        is_expected.to eq(expected_sql)
      end
    end

    describe '.for_project' do
      let(:project_path) { project.project_namespace.traversal_path(with_organization: true) }
      let(:query) { described_class.for_project(project) }

      it 'pushes traversal_path into the inner WHERE' do
        is_expected.to include("WHERE `siphon_p_ci_stages`.`traversal_path` = '#{project_path}'")
      end
    end

    describe '#for_ids' do
      let(:query) { instance.for_ids(ids) }

      context 'with a populated array' do
        let(:ids) { [10, 20] }

        it { is_expected.to include('`siphon_p_ci_stages`.`id` IN (10, 20)') }
      end

      context 'with an empty array' do
        let(:ids) { [] }

        it { is_expected.to eq(instance.to_sql) }
      end

      context 'with nils filtered out' do
        let(:ids) { [nil, 5] }

        it { is_expected.to include('`siphon_p_ci_stages`.`id` IN (5)') }
      end
    end

    describe '#select narrows the outer projection' do
      let(:query) { instance.select(:id, :name) }

      it 'replaces the default *', :aggregate_failures do
        is_expected.to include('SELECT `stages`.`id`, `stages`.`name`')
        is_expected.not_to start_with('SELECT *')
      end
    end
  end

  describe 'execution' do
    let_it_be(:stage_build) { create(:ci_stage, project: project, name: 'build') }
    let_it_be(:stage_deploy) { create(:ci_stage, project: project, name: 'deploy') }
    let_it_be(:other_project) { create(:project) }

    let(:rows) { ::ClickHouse::Client.select(described_class.for_project(project), :main) }

    subject(:names) { rows.map { |r| r['name'] } }

    before do
      insert_ci_stages_to_siphon([stage_build, stage_deploy])
    end

    it 'returns one row per stage with the deduplicated name' do
      expect(names).to contain_exactly('build', 'deploy')
    end

    context 'when a row is re-replicated with a newer _siphon_replicated_at' do
      let(:renamed_build) do
        stage_build.dup.tap do |s|
          s.id = stage_build.id
          s.name = 'compile'
        end
      end

      before do
        insert_ci_stages_to_siphon([renamed_build], replicated_at: 1.minute.from_now)
      end

      it 'picks the latest version' do
        build_row = rows.find { |r| r['id'] == stage_build.id }
        expect(build_row['name']).to eq('compile')
      end
    end

    context 'when the same id exists across two partitions' do
      # (id, partition_id) is the composite PG primary key. Two rows sharing
      # `id` across partitions are logically distinct stages and must NOT be
      # collapsed by the GROUP BY.
      let(:cross_partition_build) do
        stage_build.dup.tap do |s|
          s.id = stage_build.id
          s.partition_id = stage_build.partition_id + 1
          s.name = 'cross-partition-build'
        end
      end

      before do
        insert_ci_stages_to_siphon([cross_partition_build])
      end

      it 'keeps both rows separate' do
        expect(names).to contain_exactly('build', 'deploy', 'cross-partition-build')
      end
    end

    context 'when a stage has been soft-deleted' do
      before do
        insert_ci_stages_to_siphon([stage_deploy], replicated_at: 1.minute.from_now, deleted: true)
      end

      it 'excludes the soft-deleted stage' do
        expect(names).to contain_exactly('build')
      end
    end

    context 'when for_ids is applied' do
      let(:rows) do
        ::ClickHouse::Client.select(described_class.for_project(project).for_ids([stage_build.id]), :main)
      end

      it 'narrows to the specific id' do
        expect(names).to contain_exactly('build')
      end
    end

    context 'when the queried project has no stages' do
      let(:rows) do
        ::ClickHouse::Client.select(described_class.for_project(other_project), :main)
      end

      it { is_expected.to be_empty }
    end

    context 'when stages from another project are also seeded' do
      let_it_be(:other_stage) do
        create(:ci_stage, project: other_project, name: 'other-project-stage')
      end

      before do
        insert_ci_stages_to_siphon([other_stage])
      end

      it 'scopes results by traversal_path and excludes stages from other projects' do
        expect(names)
          .to contain_exactly('build', 'deploy')
          .and not_include('other-project-stage')
      end
    end
  end
end
