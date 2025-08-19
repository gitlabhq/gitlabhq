# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::FinishedBuildsFinder, :click_house, feature_category: :fleet_visibility do
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
    it 'returns builds only for the specified project' do
      result = instance.for_project(project.id).execute

      expect(result.size).to eq(9) # All builds except other_project_builds
      expect(result.pluck('project_id').uniq).to eq([project.id])
    end

    it 'returns empty result for non-existent project' do
      result = instance.for_project(999999).execute

      expect(result).to be_empty
    end
  end

  describe '#select' do
    context 'when selecting allowed columns' do
      it 'returns only the selected columns grouped appropriately' do
        result = instance.for_project(project.id).select(:name).execute

        expect(result.size).to eq(4)
        expect(result.first.keys).to eq(['name'])
        expect(result.pluck('name')).to match_array(%w[compile compile-slow lint rspec])
      end

      it 'handles multiple columns selection' do
        result = instance.for_project(project.id).select([:name, :stage_id]).execute

        expect(result.first.keys).to match_array(%w[name stage_id])

        # assert grouping
        compile_results = result.select { |r| r['name'] == 'compile' }
        expect(compile_results.size).to eq(1)
        expect(compile_results.first['stage_id']).to eq(stage1.id)
      end
    end

    context 'when selecting disallowed columns' do
      it 'raises ArgumentError' do
        expect do
          instance.select(:invalid_column).execute
        end.to raise_error(ArgumentError, "Cannot select columns: [:invalid_column]. Allowed: name, stage_id")
      end
    end

    context 'with edge cases' do
      it 'loads * when selecting empty array' do
        result = instance.for_project(project.id).select([]).execute

        expect(result.size).to eq(9)
        expect(result.first.keys).to include('name', 'stage_id', 'status', 'project_id')
      end

      it 'loads * when nil is passed' do
        result = instance.for_project(project.id).select(nil).execute

        expect(result.size).to eq(9)
        expect(result.first.keys).to include('name', 'stage_id', 'status', 'project_id')
      end

      it 'handles duplicates properly' do
        result = instance.for_project(project.id).select(:name, :name).execute

        expect(result.size).to eq(4)
        expect(result.first.keys).to eq(['name'])
      end
    end
  end

  describe '#mean_duration_in_seconds' do
    it 'calculates average duration correctly' do
      result = instance.for_project(project.id)
                       .select(:name)
                       .mean_duration_in_seconds
                       .execute

      expect(result).to include(
        a_hash_including('name' => 'compile', 'mean_duration_in_seconds' => 1.0),
        a_hash_including('name' => 'compile-slow', 'mean_duration_in_seconds' => 5.0),
        a_hash_including('name' => 'rspec', 'mean_duration_in_seconds' => be_within(0.01).of(2.67))
      )
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
  end

  describe '#rate_of_status' do
    context 'with valid status' do
      it 'calculates success rate correctly' do
        result = instance.for_project(project.id)
                         .select(:name)
                         .rate_of_status('success')
                         .execute

        expect(result).to include(
          a_hash_including('name' => 'compile', 'rate_of_success' => 100),
          a_hash_including('name' => 'rspec', 'rate_of_success' => 0)
        )
      end

      it 'calculates failed rate correctly' do
        result = instance.for_project(project.id)
                         .select(:name)
                         .rate_of_failed
                         .execute

        rspec_result = result.find { |r| r['name'] == 'rspec' }

        # rspec: 2 failed out of 3 = 66.67%
        expect(rspec_result['rate_of_failed']).to be_within(0.01).of(66.67)
      end
    end

    context 'with invalid status' do
      it 'raises ArgumentError' do
        expect do
          instance.rate_of_status('invalid_status').execute
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
    context 'with aggregated columns' do
      it 'orders by mean duration correctly' do
        result = instance.for_project(project.id)
                         .select(:name)
                         .mean_duration_in_seconds
                         .order_by(:mean_duration_in_seconds)
                         .execute

        durations = result.pluck('mean_duration_in_seconds')
        expect(durations).to eq(durations.sort)
      end

      it 'orders by mean duration DESC correctly' do
        result = instance.for_project(project.id)
                         .select(:name)
                         .mean_duration_in_seconds
                         .order_by(:mean_duration_in_seconds, :desc)
                         .execute

        durations = result.pluck('mean_duration_in_seconds')
        expect(durations).to eq(durations.sort.reverse)
      end
    end

    context 'with non-aggregated columns' do
      it 'orders by name correctly' do
        result = instance.for_project(project.id)
                         .select(:name)
                         .order_by(:name)
                         .execute

        names = result.pluck('name')
        expect(names).to eq(names.sort)
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError for invalid column' do
        expect do
          instance.order_by(:invalid_column).execute
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
    it 'groups by single column correctly' do
      result = instance.for_project(project.id)
                       .select(:stage_id)
                       .execute

      expect(result.size).to eq(2) # stage1 and stage2
      expect(result.pluck('stage_id')).to match_array([stage1.id, stage2.id])
    end

    it 'groups by multiple columns correctly' do
      result = instance.for_project(project.id)
                       .select(:name, :stage_id)
                       .execute

      expect(result.size).to eq(4) # Each unique name-stage combination
    end

    it 'handles duplicates in grouping' do
      result = instance.for_project(project.id)
                       .select(:name, :name)
                       .execute

      # Should group by name only once
      expect(result.pluck('name')).to match_array(%w[compile compile-slow lint rspec])
    end

    it 'raises error for invalid columns' do
      expect do
        instance.group_by(:invalid_column).execute
      end.to raise_error(ArgumentError, "Cannot group by column: invalid_column. Allowed: name, stage_id")
    end
  end

  describe 'method chaining' do
    it 'combines multiple operations correctly' do
      result = instance.for_project(project.id)
                       .select([:name, :stage_id])
                       .mean_duration_in_seconds
                       .p95_duration_in_seconds
                       .rate_of_success
                       .rate_of_failed
                       .order_by(:mean_duration_in_seconds, :desc)
                       .limit(3)
                       .execute

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
