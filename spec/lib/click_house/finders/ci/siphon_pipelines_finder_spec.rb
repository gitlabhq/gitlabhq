# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::SiphonPipelinesFinder, :click_house, :freeze_time,
  feature_category: :fleet_visibility do
  let(:instance) { described_class.new }

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project_path) { project.reload.project_namespace.traversal_path(with_organization: true) }
  let_it_be(:group_path) { group.traversal_path(with_organization: true) }

  describe 'class methods' do
    describe '.time_window_valid?' do
      subject { described_class.time_window_valid?(from_time, to_time) }

      context 'with a window of 366 days' do
        let(:from_time) { 1.second.after(366.days.ago) }
        let(:to_time) { Time.current }

        it { is_expected.to be(true) }
      end

      context 'with a window of 367 days' do
        let(:from_time) { 367.days.ago }
        let(:to_time) { Time.current }

        it { is_expected.to be(false) }
      end
    end

    describe '.validate_time_window' do
      subject { described_class.validate_time_window(from_time, to_time) }

      context 'with a window of less than 366 days' do
        let(:from_time) { 1.second.after(366.days.ago) }
        let(:to_time) { Time.current }

        it { is_expected.to be_nil }
      end

      context 'with a window of 367 days' do
        let(:from_time) { 367.days.ago }
        let(:to_time) { Time.current }

        it { is_expected.to eq('Maximum of 366 days can be requested') }
      end
    end

    describe '.for_container' do
      before do
        allow(described_class).to receive(:new).and_return(instance)
      end

      context 'when container is a Project' do
        it 'delegates to #for_project' do
          expect(instance).to receive(:for_project).with(project)

          described_class.for_container(project)
        end
      end

      context 'when container is a Group' do
        it 'delegates to #for_group' do
          expect(instance).to receive(:for_group).with(group)

          described_class.for_container(group)
        end
      end
    end

    describe '.by_status' do
      it 'delegates to the instance' do
        allow(described_class).to receive(:new).and_return(instance)
        expect(instance).to receive(:by_status).with(:success)

        described_class.by_status(:success)
      end
    end

    describe '.group_by_status' do
      it 'delegates to the instance' do
        allow(described_class).to receive(:new).and_return(instance)
        expect(instance).to receive(:group_by_status)

        described_class.group_by_status
      end
    end
  end

  describe '#initialize' do
    context 'with no arguments' do
      it 'builds a base inner and outer query' do
        expect(instance.inner_query).to be_a(ClickHouse::Client::QueryBuilder)
        expect(instance.outer_query).to be_a(ClickHouse::Client::QueryBuilder)
      end
    end

    context 'with caller-provided builders' do
      let(:custom_inner) { ClickHouse::Client::QueryBuilder.new('siphon_p_ci_pipelines') }
      let(:custom_outer) { ClickHouse::Client::QueryBuilder.new('pipelines') }
      let(:finder) { described_class.new(inner_query: custom_inner, outer_query: custom_outer) }

      it 'uses them as-is' do
        expect(finder.inner_query).to eq(custom_inner)
        expect(finder.outer_query).to eq(custom_outer)
      end
    end
  end

  describe 'SQL structure' do
    let(:expected_sql) do
      <<~SQL.squish
        SELECT count() AS all
        FROM
        (SELECT
            `siphon_p_ci_pipelines`.`id`,
            `siphon_p_ci_pipelines`.`partition_id`,
            argMax(`siphon_p_ci_pipelines`.`traversal_path`, `siphon_p_ci_pipelines`.`_siphon_replicated_at`) AS traversal_path,
            argMax(`siphon_p_ci_pipelines`.`status`, `siphon_p_ci_pipelines`.`_siphon_replicated_at`) AS status,
            argMax(`siphon_p_ci_pipelines`.`source`, `siphon_p_ci_pipelines`.`_siphon_replicated_at`) AS source,
            argMax(`siphon_p_ci_pipelines`.`ref`, `siphon_p_ci_pipelines`.`_siphon_replicated_at`) AS ref,
            argMax(`siphon_p_ci_pipelines`.`started_at`, `siphon_p_ci_pipelines`.`_siphon_replicated_at`) AS started_at,
            argMax(`siphon_p_ci_pipelines`.`finished_at`, `siphon_p_ci_pipelines`.`_siphon_replicated_at`) AS finished_at,
            argMax(`siphon_p_ci_pipelines`.`duration`, `siphon_p_ci_pipelines`.`_siphon_replicated_at`) AS duration,
            argMax(`siphon_p_ci_pipelines`.`_siphon_deleted`, `siphon_p_ci_pipelines`.`_siphon_replicated_at`) AS _siphon_deleted
          FROM `siphon_p_ci_pipelines`
          WHERE `siphon_p_ci_pipelines`.`traversal_path` = '#{project_path}'
          GROUP BY id, partition_id) pipelines
        WHERE `pipelines`.`started_at` >= toDateTime64('2024-01-01 00:00:00', 6, 'UTC')
          AND `pipelines`.`started_at` <  toDateTime64('2024-02-01 00:00:00', 6, 'UTC')
          AND `pipelines`.`source` = #{source_int}
          AND `pipelines`.`ref` = 'master'
          AND `pipelines`.`status` IN ('success', 'failed', 'canceled', 'skipped')
          AND `pipelines`.`_siphon_deleted` = 'false'
      SQL
    end

    let(:from_time) { Time.utc(2024, 1, 1, 0, 0, 0) }
    let(:to_time) { Time.utc(2024, 2, 1, 0, 0, 0) }
    let(:source_int) { ::Ci::Pipeline.sources['push'] }

    it 'produces the expected nested argMax dedup query for a canonical aggregate call' do
      actual_sql = described_class
        .for_container(project)
        .within_dates(from_time, to_time)
        .for_source(:push)
        .for_ref('master')
        .by_status(%w[success failed canceled skipped])
        .select(instance.count_pipelines_function.as('all'))
        .to_sql
        .squish

      expect(actual_sql).to eq(expected_sql)
    end
  end

  describe '#for_project' do
    subject(:sql) { instance.for_project(project).to_sql }

    it { is_expected.to include("WHERE `siphon_p_ci_pipelines`.`traversal_path` = '#{project_path}'") }
  end

  describe '#for_group' do
    subject(:sql) { instance.for_group(group).to_sql }

    it { is_expected.to include("WHERE startsWith(`siphon_p_ci_pipelines`.`traversal_path`, '#{group_path}')") }
  end

  describe '#for_subgroups' do
    let_it_be(:subgroup1) { create(:group, parent: group) }
    let_it_be(:subgroup2) { create(:group, parent: group) }

    context 'with an empty array' do
      subject { instance.for_subgroups([]) }

      it { is_expected.to eq(instance) }
    end

    context 'with a single subgroup' do
      subject(:sql) { instance.for_subgroups([subgroup1]).to_sql }

      let(:path) { subgroup1.traversal_path(with_organization: true) }

      it { is_expected.to include("WHERE startsWith(`siphon_p_ci_pipelines`.`traversal_path`, '#{path}')") }
    end

    context 'with multiple subgroups' do
      subject(:sql) { instance.for_subgroups([subgroup1, subgroup2]).to_sql }

      let(:path1) { subgroup1.traversal_path(with_organization: true) }
      let(:path2) { subgroup2.traversal_path(with_organization: true) }
      let(:expected_clause) do
        "WHERE (startsWith(`siphon_p_ci_pipelines`.`traversal_path`, '#{path1}') " \
          "OR startsWith(`siphon_p_ci_pipelines`.`traversal_path`, '#{path2}'))"
      end

      it { is_expected.to include(expected_clause) }
    end
  end

  describe '#within_dates' do
    let(:from_time) { Time.utc(2024, 1, 1, 0, 0, 0) }
    let(:to_time) { Time.utc(2024, 2, 1, 0, 0, 0) }

    context 'with both bounds' do
      subject(:sql) { instance.within_dates(from_time, to_time).to_sql }

      it 'includes both date bounds', :aggregate_failures do
        is_expected.to include("`pipelines`.`started_at` >= toDateTime64('2024-01-01 00:00:00', 6, 'UTC')")
        is_expected.to include("`pipelines`.`started_at` < toDateTime64('2024-02-01 00:00:00', 6, 'UTC')")
      end
    end

    context 'with only from_time' do
      subject(:sql) { instance.within_dates(from_time, nil).to_sql }

      it 'includes only the lower bound', :aggregate_failures do
        is_expected.to include(">= toDateTime64('2024-01-01 00:00:00', 6, 'UTC')")
        is_expected.not_to include("< toDateTime64('2024-02-01")
      end
    end

    context 'with only to_time' do
      subject(:sql) { instance.within_dates(nil, to_time).to_sql }

      it 'includes only the upper bound', :aggregate_failures do
        is_expected.to include("< toDateTime64('2024-02-01 00:00:00', 6, 'UTC')")
        is_expected.not_to include(">= toDateTime64('2024-01-01")
      end
    end

    context 'with both nil' do
      subject(:sql) { instance.within_dates(nil, nil).to_sql }

      it { is_expected.not_to include('`pipelines`.`started_at`') }
    end
  end

  describe '#for_source' do
    subject(:sql) { instance.for_source(source).to_sql }

    context 'with a symbol' do
      let(:source) { :push }

      it { is_expected.to include("`pipelines`.`source` = #{::Ci::Pipeline.sources['push']}") }
    end

    context 'with a string' do
      let(:source) { 'web' }

      it { is_expected.to include("`pipelines`.`source` = #{::Ci::Pipeline.sources['web']}") }
    end

    context 'with an unknown source' do
      let(:source) { :bogus_source }

      it 'raises ArgumentError instead of silently emitting WHERE source IS NULL' do
        expect { sql }.to raise_error(ArgumentError, /Unknown pipeline source: :bogus_source/)
      end
    end
  end

  describe '#for_ref' do
    subject(:sql) { instance.for_ref(ref).to_sql }

    context 'with a single ref' do
      let(:ref) { 'master' }

      it { is_expected.to include("`pipelines`.`ref` = 'master'") }
    end

    context 'with multiple refs' do
      let(:ref) { %w[master main] }

      it { is_expected.to include("`pipelines`.`ref` IN ('master', 'main')") }
    end
  end

  describe '#by_status' do
    subject(:sql) { instance.by_status(%w[success failed]).to_sql }

    it { is_expected.to include("`pipelines`.`status` IN ('success', 'failed')") }
  end

  describe '#group_by_status' do
    subject(:sql) { instance.group_by_status.to_sql }

    it { is_expected.to include('GROUP BY `pipelines`.`status`') }
  end

  describe '#group_by_timestamp_bin' do
    subject(:sql) { instance.group_by_timestamp_bin.to_sql }

    it { is_expected.to include('GROUP BY timestamp') }
  end

  describe '#timestamp_bin_function' do
    subject(:sql) { instance.select(instance.timestamp_bin_function(period)).to_sql }

    %i[day week month].each do |bin_period|
      context "with period :#{bin_period}" do
        let(:period) { bin_period }

        it { is_expected.to include("dateTrunc('#{bin_period}', `pipelines`.`started_at`, 'UTC') AS timestamp") }
      end
    end
  end

  describe '#count_pipelines_function' do
    subject(:sql) { instance.select(instance.count_pipelines_function.as('all')).to_sql }

    it { is_expected.to start_with('SELECT count() AS all') }
  end

  describe '#duration_quantile_function' do
    subject(:sql) { instance.select(instance.duration_quantile_function(quantile)).to_sql }

    [50, 75, 90, 95, 99].each do |q|
      context "with quantile #{q}" do
        let(:quantile) { q }

        it { is_expected.to include("quantile(#{q / 100.0})(`pipelines`.`duration`) AS p#{q}") }
      end
    end
  end

  describe '#select' do
    context 'when called once' do
      subject(:sql) { instance.select(:status).to_sql }

      it { is_expected.to start_with('SELECT `pipelines`.`status`') }
    end

    context 'when chained with other scopes' do
      subject(:sql) { instance.select(:status).by_status(['success']).group_by_status.to_sql }

      it 'produces the correct SELECT, WHERE, and GROUP BY clauses', :aggregate_failures do
        is_expected.to start_with('SELECT `pipelines`.`status`')
        is_expected.to include("`pipelines`.`status` IN ('success')")
        is_expected.to include('GROUP BY `pipelines`.`status`')
      end
    end
  end

  describe '#final_query' do
    subject(:sql) { instance.final_query.to_sql }

    it 'wraps the inner subquery with the alias' do
      is_expected.to match(/\) pipelines /)
    end

    it 'always applies the _siphon_deleted = false filter on the outer query' do
      is_expected.to include("WHERE `pipelines`.`_siphon_deleted` = 'false'")
    end
  end

  describe 'immutability' do
    let(:chained) { instance.for_project(project).by_status(['success']) }

    it 'returns a new instance and does not mutate the original', :aggregate_failures do
      expect(chained).not_to eq(instance)
      expect(instance.to_sql).not_to include(project_path)
      expect(instance.to_sql).not_to include("status` IN ('success')")
    end
  end

  describe 'execution against real ClickHouse' do
    let(:started_at) { Time.utc(2024, 5, 10, 12, 0, 0) }
    let(:from_time) { 1.day.before(started_at) }
    let(:to_time) { 1.day.after(started_at) }

    def execute(finder)
      sql = finder.select(finder.count_pipelines_function.as('count')).to_sql

      ::ClickHouse::Client.select(sql, :main).first['count']
    end

    context 'with one matching pipeline' do
      let(:pipeline) do
        build_stubbed(:ci_pipeline, :success,
          project: project, ref: 'master', source: :push,
          created_at: started_at, started_at: started_at, finished_at: started_at + 5.minutes,
          duration: 300)
      end

      before do
        insert_ci_pipelines_to_siphon([pipeline])
      end

      subject(:count) { execute(described_class.for_container(project).within_dates(from_time, to_time)) }

      it { is_expected.to eq(1) }
    end

    context 'with a soft-deleted pipeline' do
      let(:pipeline) do
        build_stubbed(:ci_pipeline, :success,
          project: project, ref: 'master', source: :push,
          created_at: started_at, started_at: started_at, finished_at: started_at + 5.minutes,
          duration: 300)
      end

      before do
        insert_ci_pipelines_to_siphon([pipeline], deleted: true)
      end

      subject(:count) { execute(described_class.for_container(project).within_dates(from_time, to_time)) }

      it { is_expected.to eq(0) }
    end

    context 'with duplicated rows (multiple versions of the same id)' do
      let(:original_pipeline) do
        build_stubbed(:ci_pipeline, :failed,
          project: project, ref: 'master', source: :push,
          created_at: started_at, started_at: started_at, finished_at: started_at + 5.minutes,
          duration: 300)
      end

      let(:updated_pipeline) do
        # Same id, later replicated_at, success status (overrides original)
        build_stubbed(:ci_pipeline, :success,
          id: original_pipeline.id, project: project, ref: 'master', source: :push,
          created_at: started_at, started_at: started_at, finished_at: started_at + 5.minutes,
          duration: 300)
      end

      before do
        insert_ci_pipelines_to_siphon([original_pipeline], replicated_at: started_at)
        insert_ci_pipelines_to_siphon([updated_pipeline], replicated_at: started_at + 1.minute)
      end

      subject(:count) do
        finder = described_class
          .for_container(project)
          .within_dates(from_time, to_time)
          .by_status(['success'])

        execute(finder)
      end

      it 'uses the latest version and counts the row as success' do
        is_expected.to eq(1)
      end
    end

    context 'with source enum translation' do
      let(:push_pipeline) do
        build_stubbed(:ci_pipeline, :success,
          project: project, ref: 'master', source: :push,
          created_at: started_at, started_at: started_at, finished_at: started_at + 5.minutes,
          duration: 300)
      end

      let(:web_pipeline) do
        build_stubbed(:ci_pipeline, :success,
          project: project, ref: 'master', source: :web,
          created_at: started_at, started_at: started_at, finished_at: started_at + 5.minutes,
          duration: 300)
      end

      before do
        insert_ci_pipelines_to_siphon([push_pipeline, web_pipeline])
      end

      subject(:count) do
        finder = described_class.for_container(project).within_dates(from_time, to_time).for_source(:push)
        execute(finder)
      end

      it { is_expected.to eq(1) }
    end
  end
end
