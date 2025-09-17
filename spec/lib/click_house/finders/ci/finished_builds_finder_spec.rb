# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::FinishedBuildsFinder, :click_house, :freeze_time, feature_category: :fleet_visibility do
  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:pipeline1) { create(:ci_pipeline, project: project2) }
  let_it_be(:stage1) { create(:ci_stage, pipeline: pipeline, project: project, name: 'build') }
  let_it_be(:stage2) { create(:ci_stage, pipeline: pipeline, project: project, name: 'test') }
  let_it_be(:stage3) { create(:ci_stage, pipeline: pipeline1, project: project2, name: 'deploy') }
  let_it_be(:base_time) { Time.current }

  let_it_be(:successful_fast_builds) do
    create_builds(count: 3, status: :success, stage: stage1, name: 'compile', duration_seconds: 1)
  end

  let_it_be(:successful_slow_builds) do
    create_builds(count: 2, status: :success, stage: stage1, name: 'compile-slow', duration_seconds: 5)
  end

  let_it_be(:failed_builds) do
    create_builds(count: 2, status: :failed, stage: stage2, name: 'rspec', duration_seconds: 3)
  end

  let_it_be(:canceled_builds) do
    create_builds(count: 1, status: :canceled, stage: stage2, name: 'rspec', duration_seconds: 2)
  end

  let_it_be(:skipped_builds) do
    create_builds(count: 1, status: :skipped, stage: stage2, name: 'lint', duration_seconds: 0.5)
  end

  let_it_be(:other_project_builds) do
    create_builds(count: 2, status: :success, stage: stage3, name: 'deploy', duration_seconds: 10)
  end

  let(:instance) { described_class.new }

  before do
    insert_ci_builds_to_click_house(
      successful_fast_builds + successful_slow_builds + failed_builds +
      canceled_builds + skipped_builds + other_project_builds
    )
  end

  describe '#for_project' do
    let(:result) { instance.for_project(project_id).execute }

    context 'with valid project_id' do
      let(:project_id) { project.id }

      it 'returns builds only for the specified project' do
        expect(result.size).to eq(9) # All builds except other_project_builds
        expect(result.pluck('project_id').uniq).to eq([project.id])
      end
    end

    context 'with non-existent project_id' do
      let(:project_id) { non_existing_record_id }

      it 'returns an empty result' do
        expect(result).to be_empty
      end
    end
  end

  describe '#select' do
    subject(:result) { instance.for_project(project.id).select(selected_fields).execute }

    context 'when selecting allowed columns' do
      let(:selected_fields) { [:name] }

      it 'returns only the selected columns grouped appropriately' do
        expect(result.size).to eq(4)
        expect(result.first.keys).to eq(['name'])
        expect(result.pluck('name')).to match_array(%w[compile compile-slow lint rspec])
      end

      context 'with multiple columns selection' do
        let(:selected_fields) { [:name, :stage_id] }

        it 'returns the selections' do
          expect(result.first.keys).to match_array(%w[name stage_id])
          # assert grouping
          compile_results = result.select { |r| r['name'] == 'compile' }
          expect(compile_results.size).to eq(1)
          expect(compile_results.first['stage_id']).to eq(stage1.id)
        end
      end
    end

    context 'when selecting disallowed columns' do
      let(:selected_fields) { [:invalid_column] }

      it 'raises ArgumentError' do
        expect do
          result
        end.to raise_error(ArgumentError, "Cannot select columns: [:invalid_column]. Allowed: name, stage_id")
      end
    end

    context 'with edge cases' do
      context 'with empty array' do
        let(:selected_fields) { [] }

        it 'loads *' do
          expect(result.size).to eq(9)
          expect(result.first.keys).to include('name', 'stage_id', 'status', 'project_id')
        end
      end

      context 'with nil' do
        let(:selected_fields) { nil }

        it 'loads *' do
          expect(result.size).to eq(9)
          expect(result.first.keys).to include('name', 'stage_id', 'status', 'project_id')
        end
      end

      context 'with duplicates' do
        let(:selected_fields) { [:name, :name] }

        it 'does not duplicate the fields' do
          expect(result.size).to eq(4)
          expect(result.first.keys).to eq(['name'])
        end
      end
    end
  end

  describe '#select_aggregations' do
    subject(:result) do
      instance.for_project(project.id).select(:name).select_aggregations(*selected_aggregations).execute
    end

    context 'with single aggregation' do
      let(:selected_aggregations) { [:mean_duration_in_seconds] }

      it 'returns only mean_duration_in_seconds grouped by name' do
        expect(result.first.keys).to contain_exactly('name', 'mean_duration_in_seconds')
      end
    end

    context 'with multiple aggregations' do
      let(:selected_aggregations) { [:mean_duration_in_seconds, :p95_duration_in_seconds] }

      it 'returns multiple aggregations grouped by name' do
        expect(result.first.keys).to contain_exactly('name', 'mean_duration_in_seconds', 'p95_duration_in_seconds')
      end
    end

    context 'with invalid aggregations' do
      let(:selected_aggregations) { [:invalid_aggregation] }

      it 'raises ArgumentError' do
        expect do
          result
        end.to raise_error(ArgumentError,
          "Cannot aggregate columns: [:invalid_aggregation]. Allowed: mean_duration_in_seconds, " \
            "p95_duration_in_seconds, rate_of_success, rate_of_failed, rate_of_canceled, rate_of_skipped")
      end
    end
  end

  describe '#mean_duration_in_seconds' do
    subject(:result) do
      instance.for_project(project.id)
              .select(:name)
              .mean_duration_in_seconds
              .execute
    end

    it 'calculates average duration correctly' do
      expect(result).to include(
        a_hash_including('name' => 'compile', 'mean_duration_in_seconds' => 1.0),
        a_hash_including('name' => 'compile-slow', 'mean_duration_in_seconds' => 5.0),
        a_hash_including('name' => 'rspec', 'mean_duration_in_seconds' => be_within(0.01).of(2.67))
      )
    end

    it 'rounds the result to 2 decimal places' do
      expect(result.all? { |r| r['mean_duration_in_seconds'].to_s.split('.').last.size <= 2 }).to be true
    end
  end

  describe '#p95_duration_in_seconds' do
    before do
      # Creating additional builds to ensure the percentile calculation is more accurate
      additional_builds = (1..20).map do |i|
        create(:ci_build, :success,
          project: project,
          pipeline: pipeline,
          ci_stage: stage1,
          name: 'percentile-test',
          started_at: base_time,
          finished_at: base_time + ((i * 100.0) / 1000.0) # adding [100, 200, ..., 2000]
        )
      end
      insert_ci_builds_to_click_house(additional_builds)
    end

    it 'calculates 95th percentile duration correctly' do
      result = instance.for_project(project.id)
                       .select(:name)
                       .p95_duration_in_seconds
                       .execute

      percentile_result = result.find { |r| r['name'] == 'percentile-test' }

      # p95 of 100ms, 200ms, ..., 2000ms should be 1900ms = 1.9 seconds
      expect(percentile_result['p95_duration_in_seconds']).to be_within(0.1).of(1.9)
    end

    it 'rounds the result to 2 decimal places' do
      result = instance.for_project(project.id)
                       .p95_duration_in_seconds
                       .execute

      expect(result.first['p95_duration_in_seconds'].to_s.split('.').last.size <= 2).to be true
    end
  end

  describe '#rate_of_status' do
    subject(:result) do
      instance.for_project(project.id)
              .select(:name)
              .rate_of_status(status)
              .execute
    end

    context 'with valid status' do
      let(:status) { :success }

      it 'calculates success rate correctly' do
        expect(result).to include(
          a_hash_including('name' => 'compile', 'rate_of_success' => 100),
          a_hash_including('name' => 'rspec', 'rate_of_success' => 0)
        )
      end

      context 'with status - failed' do
        let(:status) { :failed }

        it 'calculates failed rate correctly and rounds off to 2 decimal places', :aggregate_failures do
          rspec_result = result.find { |r| r['name'] == 'rspec' }

          # rspec: 2 failed out of 3 = 66.67%
          expect(rspec_result['rate_of_failed']).to be_within(0.01).of(66.67)
          # assert round off
          expect(result.first['rate_of_failed'].to_s.split('.').last.size <= 2).to be true
        end
      end
    end

    context 'with invalid status' do
      let(:status) { 'invalid_status' }

      it 'raises ArgumentError' do
        expect do
          result
        end.to raise_error(ArgumentError,
          "Invalid status: invalid_status. Must be one of: success, failed, canceled, skipped")
      end
    end
  end

  describe 'dynamic status methods' do
    %w[success failed canceled skipped].each do |status|
      describe "#rate_of_#{status}" do
        it "calculates rate correctly" do
          result = instance.for_project(project.id)
                           .select(:stage_id)
                           .public_send(:"rate_of_#{status}")
                           .execute

          expect(result).not_to be_empty
          expect(result.first.keys).to include("rate_of_#{status}")
        end
      end
    end
  end

  describe '#order_by' do
    subject(:result) do
      instance.for_project(project.id)
              .select(:name)
              .mean_duration_in_seconds
              .order_by(*order_by_args)
              .execute
    end

    context 'with aggregated columns' do
      let(:order_by_args) { [:mean_duration_in_seconds] }

      it 'orders by mean duration correctly' do
        durations = result.pluck('mean_duration_in_seconds')
        expect(durations).to eq(durations.sort)
      end

      context 'with order by desc' do
        let(:order_by_args) { [:mean_duration_in_seconds, :desc] }

        it 'orders by mean duration DESC correctly' do
          durations = result.pluck('mean_duration_in_seconds')
          expect(durations).to eq(durations.sort.reverse)
        end
      end
    end

    context 'with non-aggregated columns' do
      let(:order_by_args) { [:name] }

      it 'orders by name correctly' do
        names = result.pluck('name')
        expect(names).to eq(names.sort)
      end
    end

    context 'with invalid parameters' do
      let(:order_by_args) { [:invalid_column] }

      it 'raises ArgumentError for invalid column' do
        expect do
          result
        end.to raise_error(ArgumentError, /Cannot order by column: invalid_column/)
      end

      it 'raises ArgumentError for invalid direction' do
        expect do
          instance.order_by(:name, :invalid_direction).execute
        end.to raise_error(ArgumentError, /Invalid order direction/)
      end
    end
  end

  describe '#group_by' do
    subject(:result) do
      instance.for_project(project.id)
              .select(selected_fields)
              .execute
    end

    context 'with valid columns' do
      context 'with single column' do
        let(:selected_fields) { [:stage_id] }

        it 'groups by single column correctly' do
          expect(result.size).to eq(2) # stage1 and stage2
          expect(result.pluck('stage_id')).to match_array([stage1.id, stage2.id])
        end
      end

      context 'with multiple columns' do
        let(:selected_fields) { [:name, :stage_id] }

        it 'groups by multiple columns correctly' do
          expect(result.size).to eq(4) # Each unique name-stage combination
        end
      end

      context 'with duplicates' do
        let(:selected_fields) { [:name, :name] }

        it 'handles duplicates in grouping' do
          # Should group by name only once
          expect(result.pluck('name')).to match_array(%w[compile compile-slow lint rspec])
        end
      end
    end

    context 'with invalid columns' do
      it 'raises error for invalid columns' do
        expect do
          instance.group_by(:invalid_column).execute
        end.to raise_error(ArgumentError, "Cannot group by column: invalid_column. Allowed: name, stage_id")
      end
    end
  end

  describe 'method chaining' do
    subject(:result) do
      instance.for_project(project.id)
              .select([:name, :stage_id])
              .mean_duration_in_seconds
              .p95_duration_in_seconds
              .rate_of_success
              .rate_of_failed
              .order_by(:mean_duration_in_seconds, :desc)
              .limit(3)
              .execute
    end

    it 'combines multiple operations correctly' do
      expect(result.size).to be <= 3
      expect(result.first.keys).to include(
        'name', 'stage_id', 'mean_duration_in_seconds',
        'p95_duration_in_seconds', 'rate_of_success', 'rate_of_failed'
      )

      # Assert ordering
      durations = result.pluck('mean_duration_in_seconds')
      expect(durations).to eq(durations.sort.reverse)
    end
  end

  describe 'query examples' do
    it 'finds top 10 slowest builds by p95 duration' do
      result = instance.for_project(project.id)
                       .select(:name)
                       .p95_duration_in_seconds
                       .order_by(:p95_duration_in_seconds, :desc)
                       .limit(10)
                       .execute

      expect(result.size).to be <= 10

      expect(result.first['name']).to eq('compile-slow') # Should be slowest (5 seconds)
    end

    it 'calculates build success rates by stage' do
      result = instance.for_project(project.id)
                       .select(:stage_id)
                       .rate_of_success
                       .rate_of_failed
                       .execute

      stage1_result = result.find { |r| r['stage_id'] == stage1.id }
      stage2_result = result.find { |r| r['stage_id'] == stage2.id }

      # Stage1 has only successful builds
      expect(stage1_result['rate_of_success']).to eq(100.0)
      expect(stage1_result['rate_of_failed']).to eq(0.0)

      # Stage2 has mixed results
      expect(stage2_result['rate_of_success']).to eq(0.0)
      expect(stage2_result['rate_of_failed']).to be > 0
    end
  end

  describe '#execute' do
    it 'returns an array of results' do
      result = instance.for_project(project.id).execute

      expect(result).to be_a(Array)
      expect(result.size).to eq(9)
    end

    it 'returns empty array for queries with no matches' do
      result = instance.for_project(999999).execute

      expect(result).to be_a(Array)
      expect(result).to be_empty
    end
  end

  describe '#to_sql' do
    it 'generates correct SQL for inspection' do
      sql = instance.for_project(123)
                    .select(:name)
                    .mean_duration_in_seconds
                    .to_sql

      expect(sql).to include('SELECT')
      expect(sql).to include('ci_finished_builds')
      expect(sql).to include('project_id')
      expect(sql).to include('mean_duration_in_seconds')
    end
  end

  describe '#to_redacted_sql' do
    it 'redacts sensitive values' do
      sql = instance.for_project(123).to_redacted_sql

      expect(sql).to include('$1')
      expect(sql).not_to include('123')
    end
  end

  describe '#filter_by_job_name' do
    subject(:filter_by_job_name) do
      instance.for_project(project.id)
              .filter_by_job_name(search_term)
              .execute
    end

    context 'with exact match' do
      let(:search_term) { 'compile' }

      it 'returns builds with matching name' do
        expect(filter_by_job_name.size).to eq(5) # 3 successful_fast_builds + 2 successful_slow_builds
        expect(filter_by_job_name.pluck('name').uniq).to match_array(%w[compile compile-slow])
      end
    end

    context 'with partial match' do
      let(:search_term) { 'comp' }

      it 'returns builds with partially matching name' do
        expect(filter_by_job_name.size).to eq(5) # 3 successful_fast_builds + 2 successful_slow_builds
        expect(filter_by_job_name.pluck('name').uniq).to match_array(%w[compile compile-slow])
      end
    end

    context 'with case-insensitive match' do
      let(:search_term) { 'COMPILE' }

      it 'returns builds regardless of case' do
        expect(filter_by_job_name.size).to eq(5) # 3 successful_fast_builds + 2 successful_slow_builds
        expect(filter_by_job_name.pluck('name').uniq).to match_array(%w[compile compile-slow])
      end
    end

    context 'with no match' do
      let(:search_term) { non_existing_project_hashed_path }

      it 'returns empty result' do
        is_expected.to be_empty
      end
    end
  end

  describe '#filter_by_pipeline_attrs' do
    let_it_be(:ref_pipeline) { create(:ci_pipeline, project: project, ref: 'feature-branch', started_at: 6.hours.ago) }
    let_it_be(:source_pipeline) { create(:ci_pipeline, project: project, source: 'web', started_at: 12.hours.ago) }
    let_it_be(:ref_stage) { create(:ci_stage, pipeline: ref_pipeline, project: project, name: 'ref-stage') }
    let_it_be(:source_stage) { create(:ci_stage, pipeline: source_pipeline, project: project, name: 'source-stage') }

    let_it_be(:ref_builds) do
      create_builds(count: 2, status: :success, stage: ref_stage, name: 'ref-build', duration_seconds: 1)
    end

    let_it_be(:source_builds) do
      create_builds(count: 2, status: :success, stage: source_stage, name: 'source-build', duration_seconds: 1)
    end

    let(:filter_params) { {} }

    before do
      insert_ci_builds_to_click_house(ref_builds + source_builds)
      insert_ci_pipelines_to_click_house([ref_pipeline, source_pipeline])
    end

    subject(:filter_by_pipeline_attrs) do
      instance.filter_by_pipeline_attrs(project: project, **filter_params).execute
    end

    context 'with project only' do
      it 'filters builds by pipeline project' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(ref_pipeline.id, source_pipeline.id)
      end
    end

    context 'with time range' do
      let(:from_time) { 1.day.ago }
      let(:to_time) { Time.current }
      let(:filter_params) { { from_time: from_time, to_time: to_time } }

      it 'filters builds by time range' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(ref_pipeline.id, source_pipeline.id)
      end
    end

    context 'with source' do
      let(:filter_params) { { source: 'web' } }

      it 'filters builds by pipeline source' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(source_pipeline.id)
      end
    end

    context 'with ref' do
      let(:filter_params) { { ref: 'feature-branch' } }

      it 'filters builds by pipeline ref' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(ref_pipeline.id)
      end
    end

    context 'with multiple filters' do
      let(:filter_params) do
        {
          from_time: 1.day.ago,
          to_time: Time.current,
          source: 'push',
          ref: 'feature-branch'
        }
      end

      it 'combines all filters correctly' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(ref_pipeline.id)
      end
    end
  end

  describe 'edge cases and error handling' do
    it 'handles empty results gracefully' do
      result = instance.for_project(project.id)
                       .select(:name)
                       .where(name: 'non-existent-build')
                       .execute

      expect(result).to be_empty
    end

    it 'handles filtering correctly' do
      result = instance.for_project(project.id)
                       .where(status: 'success')
                       .select(:name)
                       .execute

      expect(result.pluck('name')).to match_array(%w[compile compile-slow])
    end
  end

  private

  def create_builds(count:, status:, stage:, name:, duration_seconds:)
    create_list(:ci_build, count, status,
      project: stage.project,
      pipeline: stage.pipeline,
      ci_stage: stage,
      name: name,
      started_at: base_time,
      finished_at: base_time + duration_seconds.seconds
    )
  end
end
