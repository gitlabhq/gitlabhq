# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::FinishedBuildsFinder, :click_house, :freeze_time, feature_category: :fleet_visibility do
  include_context 'with CI job analytics test data'

  let(:instance) { described_class.new }

  describe '#for_project' do
    let(:result) { instance.for_project(project_id).execute }

    context 'with valid project_id' do
      let(:project_id) { project.id }

      it 'returns builds only for the specified project' do
        expect(result.size).to eq(13) # All builds except other_project_builds
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
        expect(result.size).to eq(6)
        expect(result.first.keys).to eq(['name'])
        expect(result.pluck('name')).to match_array(%w[compile compile-slow lint rspec ref-build source-build])
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
          expect(result.size).to eq(13)
          expect(result.first.keys).to include('name', 'stage_id', 'status', 'project_id')
        end
      end

      context 'with nil' do
        let(:selected_fields) { nil }

        it 'loads *' do
          expect(result.size).to eq(13)
          expect(result.first.keys).to include('name', 'stage_id', 'status', 'project_id')
        end
      end

      context 'with duplicates' do
        let(:selected_fields) { [:name, :name] }

        it 'does not duplicate the fields' do
          expect(result.size).to eq(6)
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
            "p50_duration, p75_duration, p90_duration, p95_duration, p99_duration, p95_duration_in_seconds, " \
            "rate_of_success, rate_of_failed, rate_of_canceled, rate_of_skipped, " \
            "count_success, count_failed, count_canceled, count_skipped, total_count"
        )
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
      is_expected.to include(
        a_hash_including('name' => 'compile', 'mean_duration_in_seconds' => 1.0),
        a_hash_including('name' => 'compile-slow', 'mean_duration_in_seconds' => 5.0),
        a_hash_including('name' => 'rspec', 'mean_duration_in_seconds' => be_within(0.01).of(2.67))
      )
    end

    it 'rounds the result to 2 decimal places' do
      is_expected.to be_rounded_to_decimal_places('mean_duration_in_seconds', decimal_places: 2)
    end
  end

  shared_context 'with percentile test data' do
    let!(:additional_builds) do
      (1..20).map do |i|
        build_stubbed(:ci_build, :success,
          project: project,
          pipeline: pipeline,
          ci_stage: stage1,
          name: 'percentile-test',
          started_at: base_time,
          finished_at: base_time + ((i * 100.0) / 1000.0) # adding [100, 200, ..., 2000]
        )
      end
    end

    before do
      insert_ci_builds_to_click_house(additional_builds)
    end
  end

  shared_examples 'percentile duration calculation' do |percentile, method_name, expected_value:|
    subject(:result) do
      instance.for_project(project.id)
              .select(:name)
              .public_send(method_name)
              .execute
    end

    let(:percentile_result) { result.find { |r| r['name'] == 'percentile-test' } }

    it "calculates #{percentile} percentile duration correctly and rounds the result to 2 decimal places",
      :aggregate_failures do
      expect(percentile_result.fetch(method_name)).to be_within(0.1).of(expected_value)
      is_expected.to be_rounded_to_decimal_places(method_name, decimal_places: 2)
    end
  end

  describe 'percentile duration methods' do
    include_context 'with percentile test data'

    describe '#p50_duration' do
      it_behaves_like 'percentile duration calculation', '50th', 'p50_duration', expected_value: 1.0
    end

    describe '#p75_duration' do
      it_behaves_like 'percentile duration calculation', '75th', 'p75_duration', expected_value: 1.5
    end

    describe '#p90_duration' do
      it_behaves_like 'percentile duration calculation', '90th', 'p90_duration', expected_value: 1.8
    end

    describe '#p95_duration_in_seconds' do
      it_behaves_like 'percentile duration calculation', '95th', 'p95_duration_in_seconds', expected_value: 1.9
    end

    describe '#p99_duration' do
      it_behaves_like 'percentile duration calculation', '99th', 'p99_duration', expected_value: 1.98
    end
  end

  describe '#rate_of_status' do
    subject(:result) do
      instance.for_project(project.id)
              .select(:name)
              .public_send(:"rate_of_#{status}")
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
        let(:rspec_result) { result.find { |r| r['name'] == 'rspec' } }

        it 'calculates failed rate correctly and rounds off to 2 decimal places', :aggregate_failures do
          # rspec: 2 failed out of 3 = 66.67%
          expect(rspec_result.fetch('rate_of_failed')).to be_within(0.01).of(66.67)
          # assert round off
          is_expected.to be_rounded_to_decimal_places('rate_of_failed', decimal_places: 2)
        end
      end
    end
  end

  describe 'dynamic status methods' do
    %w[success failed canceled skipped].each do |status|
      describe "#rate_of_#{status}" do
        subject(:result) do
          instance.for_project(project.id)
            .select(:stage_id)
            .public_send(:"rate_of_#{status}")
            .execute
        end

        it "calculates rate correctly" do
          is_expected.not_to be_empty
          expect(result.first.fetch("rate_of_#{status}")).to be_a(Integer)
        end
      end

      describe "#count_#{status}" do
        subject(:result) do
          instance.for_project(project.id)
            .select(:stage_id)
            .public_send(:"count_#{status}")
            .execute
        end

        it "calculates count correctly" do
          is_expected.not_to be_empty
          expect(result.first.fetch("count_#{status}")).to be_a(Integer)
        end
      end
    end
  end

  describe '#total_count' do
    subject(:result) do
      instance.for_project(project.id)
              .select(:name)
              .total_count
              .execute
    end

    it 'calculates total count correctly' do
      is_expected.to include(
        a_hash_including('name' => 'compile', 'total_count' => 3),
        a_hash_including('name' => 'compile-slow', 'total_count' => 2),
        a_hash_including('name' => 'rspec', 'total_count' => 3)
      )
    end

    it 'returns integer values' do
      expect(result.pluck('total_count')).to all(be_an_instance_of(Integer))
    end
  end

  describe '#count_of_status' do
    subject(:result) do
      instance.for_project(project.id)
              .select(:name)
              .send(:count_of_status, status)
              .execute
    end

    context 'with valid status' do
      let(:status) { :success }

      it 'calculates success count correctly' do
        is_expected.to include(
          a_hash_including('name' => 'compile', 'count_success' => 3),
          a_hash_including('name' => 'rspec', 'count_success' => 0)
        )
      end

      context 'with status - failed' do
        let(:status) { :failed }
        let(:rspec_result) { result.find { |r| r['name'] == 'rspec' } }

        it 'calculates failed count correctly' do
          # rspec: 2 failed out of 3
          expect(rspec_result.fetch('count_failed')).to eq(2)
        end
      end
    end
  end

  describe '#duration_of_percentile' do
    include_context 'with percentile test data'

    subject(:result) do
      instance.for_project(project.id)
              .select(:name)
              .send(:duration_of_percentile, percentile)
              .execute
    end

    context 'with valid percentile' do
      let(:percentile) { 50 }
      let(:percentile_result) { result.find { |r| r['name'] == 'percentile-test' } }

      it 'calculates 50th percentile duration correctly' do
        expect(percentile_result.fetch('p50_duration')).to be_within(0.1).of(1.0)
      end

      it 'rounds the result to 2 decimal places' do
        is_expected.to be_rounded_to_decimal_places('p50_duration', decimal_places: 2)
      end

      context 'with percentile - 95' do
        let(:percentile) { 95 }

        it 'calculates 95th percentile duration correctly' do
          # p95 of 100ms, 200ms, ..., 2000ms should be 1900ms = 1.9 seconds
          expect(percentile_result.fetch('p95_duration')).to be_within(0.1).of(1.9)
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
          expect(result.size).to eq(4) # stage1, stage2, ref_stage, source_stage
          expect(result.pluck('stage_id')).to match_array([stage1.id, stage2.id, ref_stage.id, source_stage.id])
        end
      end

      context 'with multiple columns' do
        let(:selected_fields) { [:name, :stage_id] }

        it 'groups by multiple columns correctly' do
          expect(result.size).to eq(6) # Each unique name-stage combination
        end
      end

      context 'with duplicates' do
        let(:selected_fields) { [:name, :name] }

        it 'handles duplicates in grouping' do
          # Should group by name only once
          expect(result.pluck('name')).to match_array(%w[compile compile-slow lint ref-build rspec source-build])
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
      expect(result.size).to eq(13)
    end

    it 'returns empty array for queries with no matches' do
      result = instance.for_project(non_existing_record_id).execute

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

  describe '#filter_by_pipeline_attrs', :freeze_time do
    subject(:filter_by_pipeline_attrs) do
      instance.filter_by_pipeline_attrs(**attrs).execute
    end

    context 'with project only' do
      let(:attrs) { { project: project } }

      it 'filters builds by pipeline project' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(ref_pipeline.id, source_pipeline.id)
      end
    end

    context 'with time range' do
      let(:from_time) { 1.day.ago }
      let(:to_time) { Time.current }
      let(:attrs) do
        {
          project: project,
          from_time: from_time,
          to_time: to_time
        }
      end

      it 'filters builds by time range' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(ref_pipeline.id, source_pipeline.id)
      end
    end

    context 'with source' do
      let(:attrs) do
        {
          project: project,
          source: 'web'
        }
      end

      it 'filters builds by pipeline source' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(source_pipeline.id)
      end
    end

    context 'with ref' do
      let(:attrs) do
        {
          project: project,
          ref: 'feature-branch'
        }
      end

      it 'filters builds by pipeline ref' do
        expect(filter_by_pipeline_attrs).not_to be_empty
        expect(filter_by_pipeline_attrs.pluck('pipeline_id')).to include(ref_pipeline.id)
      end
    end

    context 'with multiple filters' do
      let(:attrs) do
        {
          project: project,
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

      expect(result.pluck('name')).to match_array(%w[compile compile-slow ref-build source-build])
    end
  end

  private

  RSpec::Matchers.define :be_rounded_to_decimal_places do |field_name, decimal_places:|
    match do |values|
      @unrounded = values.select do |value|
        frac = BigDecimal(value.fetch(field_name)).frac
        frac != frac.round(decimal_places)
      end

      @unrounded.empty?
    end

    failure_message do
      "expected all values in '#{field_name}' to be rounded to #{decimal_places} decimal places, " \
        "but found #{@unrounded.size} unrounded value(s): #{@unrounded.pluck(field_name).inspect}"
    end

    description do
      "have all '#{field_name}' values rounded to #{decimal_places} decimal places"
    end
  end
end
