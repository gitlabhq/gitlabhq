# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobAnalytics::QueryBuilder, :click_house, :freeze_time, feature_category: :fleet_visibility do
  include_context 'with CI job analytics test data'

  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:instance) { described_class.new(project: project, current_user: user, options: options) }
  let(:options) { {} }

  let(:query_builder) { instance.execute }

  subject(:query_result) { execute_query(query_builder) }

  before do
    stub_application_setting(use_clickhouse_for_analytics: true)
  end

  describe '#initialize' do
    context 'with minimal parameters' do
      let(:options) { {} }

      it 'sets default values correctly', :aggregate_failures do
        expect(instance.project).to eq(project)
        expect(instance.current_user).to eq(user)
        expect(instance.select_fields).to eq([])
        expect(instance.aggregations).to eq([])
        expect(instance.sort).to be_nil
        expect(instance.source).to be_nil
        expect(instance.ref).to be_nil
        expect(instance.from_time).to be_within(1.minute).of(7.days.ago)
        expect(instance.to_time).to be_nil
        expect(instance.name_search).to be_nil
      end
    end

    context 'with all parameters' do
      let(:from_time) { 1.day.ago }
      let(:to_time) { Time.current }
      let(:options) do
        {
          select_fields: [:name, :stage_id],
          aggregations: [:mean_duration_in_seconds],
          sort: 'name_asc',
          source: 'web',
          ref: 'main',
          from_time: from_time,
          to_time: to_time,
          name_search: 'test'
        }
      end

      it 'sets all values correctly', :aggregate_failures do
        expect(instance.project).to eq(project)
        expect(instance.select_fields).to contain_exactly(:name, :stage_id)
        expect(instance.aggregations).to contain_exactly(:mean_duration_in_seconds)
        expect(instance.sort).to eq('name_asc')
        expect(instance.source).to eq('web')
        expect(instance.ref).to eq('main')
        expect(instance.from_time).to eq(from_time)
        expect(instance.to_time).to eq(to_time)
        expect(instance.name_search).to eq('test')
      end
    end

    context 'with invalid project argument' do
      let(:project) { nil }

      it 'raises an error' do
        expect { instance }.to raise_error(ArgumentError, 'project must be a valid Project instance')
      end
    end
  end

  describe '#execute' do
    subject(:execute) { instance.execute }

    context 'with basic configuration' do
      let(:options) { { select_fields: [:name] } }

      it { is_expected.to be_a(ClickHouse::Client::QueryBuilder) }

      it 'returns executable query' do
        expect(query_result).to be_a(Array)
        expect(query_result).not_to be_empty
      end
    end

    context 'with select fields only' do
      let(:options) { { select_fields: [:name, :stage_id] } }

      it { expect(query_result.first.keys).to contain_exactly('name', 'stage_id') }
    end

    context 'with aggregations only' do
      let(:options) { { aggregations: [:mean_duration_in_seconds] } }

      it { expect { query_result }.not_to raise_error }
    end

    context 'with sorting' do
      let(:options) do
        {
          select_fields: [:name],
          aggregations: [:mean_duration_in_seconds],
          sort: 'mean_duration_in_seconds_asc'
        }
      end

      it 'builds query with sorting' do
        durations = query_result.pluck('mean_duration_in_seconds')
        expect(durations).to eq(durations.sort)
      end
    end

    context 'with name search' do
      let(:options) { { select_fields: [:name], name_search: 'compile' } }

      it 'builds query with name filtering' do
        expect(query_result.pluck('name').uniq).to contain_exactly('compile', 'compile-slow')
      end
    end

    context 'with pipeline attributes' do
      let(:options) do
        {
          select_fields: [:name],
          source: 'web',
          ref: 'feature-branch',
          from_time: 1.day.ago,
          to_time: Time.current
        }
      end

      it 'builds query with pipeline filtering' do
        expect { query_result }.not_to raise_error
      end
    end

    context 'with all options combined' do
      let(:options) do
        {
          select_fields: [:name],
          aggregations: [:mean_duration_in_seconds, :rate_of_success],
          sort: 'mean_duration_in_seconds_desc',
          source: 'push',
          ref: 'master',
          from_time: 1.day.ago,
          to_time: Time.current,
          name_search: 'compile'
        }
      end

      it 'builds complex query successfully', :aggregate_failures do
        expect(query_result).to be_a(Array)
        expect(query_result.first.keys).to include('name', 'mean_duration_in_seconds', 'rate_of_success')
        expect(query_result.pluck('name').uniq).to contain_exactly('compile', 'compile-slow')
      end
    end

    context 'when clickhouse is not configured' do
      before do
        allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(false)
      end

      it 'returns nil' do
        expect(execute).to be_nil
      end
    end

    context 'when clickhouse is not enabled for analytics' do
      before do
        stub_application_setting(use_clickhouse_for_analytics: false)
      end

      it 'returns nil' do
        expect(execute).to be_nil
      end
    end

    context 'when the user does not have read_build access to the project' do
      let(:project) { project2 } # user is not part of project2

      it 'returns nil' do
        expect(execute).to be_nil
      end
    end
  end

  describe '#build_finder' do
    let(:options) do
      {
        select_fields: [:name],
        aggregations: [:mean_duration_in_seconds],
        sort: 'name_asc',
        name_search: 'test',
        source: 'web',
        ref: 'main',
        from_time: 2.hours.ago,
        to_time: 1.hour.ago
      }
    end

    subject(:finder) { instance.send(:build_finder) }

    it 'builds finder with all configurations' do
      is_expected.to be_a(ClickHouse::Finders::Ci::FinishedBuildsFinder)
      expect(finder.to_sql).to include('ci_finished_builds')
    end

    it 'applies project filter' do
      expect(finder.to_sql).to include(project.project_namespace.traversal_path)
    end
  end

  describe '#extract_sort_info' do
    subject(:extract_sort_info) { instance.send(:extract_sort_info, sort_value) }

    context 'with ascending sort' do
      let(:sort_value) { 'name_asc' }

      it 'returns correct field and direction' do
        is_expected.to eq([:name, :asc])
      end
    end

    context 'with descending sort' do
      let(:sort_value) { 'mean_duration_in_seconds_desc' }

      it 'returns correct field and direction' do
        is_expected.to eq([:mean_duration_in_seconds, :desc])
      end
    end

    context 'with complex field name' do
      let(:sort_value) { 'rate_of_success_asc' }

      it 'returns correct field and direction' do
        is_expected.to eq([:rate_of_success, :asc])
      end
    end
  end

  describe 'integration with FinishedBuildsFinder' do
    let(:options) do
      {
        select_fields: [:name],
        aggregations: [:mean_duration_in_seconds],
        name_search: 'compile'
      }
    end

    it 'produces same results as direct FinishedBuildsFinder usage' do
      direct_finder_result = ClickHouse::Finders::Ci::FinishedBuildsFinder.new
                                                                          .for_project(project.id)
                                                                          .select(:name)
                                                                          .mean_duration_in_seconds
                                                                          .filter_by_job_name('compile')
                                                                          .execute

      expect(query_result.size).to eq(direct_finder_result.size)
      expect(query_result.pluck('name')).to match_array(direct_finder_result.pluck('name'))
    end
  end

  describe 'SQL generation' do
    let(:options) do
      {
        select_fields: [:name],
        aggregations: [:mean_duration_in_seconds]
      }
    end

    it 'generates valid SQL' do
      sql = query_builder.to_sql
      expected_sql = <<~SQL.squish.lines(chomp: true).join(' ')
        SELECT `ci_finished_builds`.`name`, round((avg(`ci_finished_builds`.`duration`) / 1000.0), 2) AS mean_duration_in_seconds
        FROM `ci_finished_builds` WHERE `ci_finished_builds`.`project_id` = #{project.id} AND `ci_finished_builds`.`pipeline_id` IN
        (SELECT `ci_finished_pipelines`.`id` FROM `ci_finished_pipelines` WHERE `ci_finished_pipelines`.`path` = '#{project.project_namespace.traversal_path}'
        AND `ci_finished_pipelines`.`started_at` >= toDateTime64('#{7.days.ago.utc.strftime('%Y-%m-%d %H:%M:%S')}', 6, 'UTC'))
        GROUP BY `ci_finished_builds`.`name`
      SQL
      expect(sql).to eq(expected_sql)
    end
  end

  describe 'basic query building' do
    it 'returns query builder instance' do
      expect(query_builder).to respond_to(:to_sql)
    end

    it 'can generate SQL' do
      sql = query_builder.to_sql

      expect(sql).to include('SELECT')
      expect(sql).to include('ci_finished_builds')
    end
  end

  describe 'select fields functionality' do
    context 'with valid select fields' do
      let(:options) { { select_fields: [:name] } }

      it 'includes select fields in query' do
        expect(query_result).not_to be_empty
        expect(query_result.first.keys).to contain_exactly('name')
      end
    end

    context 'with multiple select fields' do
      let(:options) { { select_fields: [:name, :stage_id] } }

      it 'includes multiple select fields' do
        expect(query_result.first.keys).to contain_exactly('name', 'stage_id')
      end
    end
  end

  describe 'aggregations functionality' do
    let(:options) { { aggregations: aggregations, select_fields: [:name] } }

    context 'with mean duration aggregation' do
      let(:aggregations) { [:mean_duration_in_seconds] }

      it 'calculates mean duration correctly' do
        is_expected.to include(
          a_hash_including('name' => 'compile', 'mean_duration_in_seconds' => 1.0),
          a_hash_including('name' => 'compile-slow', 'mean_duration_in_seconds' => 5.0)
        )
      end

      it 'rounds results to 2 decimal places' do
        expect(query_result.map { |r| r['mean_duration_in_seconds'].to_s.split('.').last.size }).to all(be <= 2)
      end
    end

    context 'with success rate aggregation' do
      let(:aggregations) { [:rate_of_success] }

      it 'calculates success rate correctly' do
        is_expected.to include(
          a_hash_including('name' => 'compile', 'rate_of_success' => 100.0),
          a_hash_including('name' => 'rspec', 'rate_of_success' => 0.0)
        )
      end
    end

    context 'with multiple aggregations' do
      let(:aggregations) { [:mean_duration_in_seconds, :rate_of_success] }

      it 'applies multiple aggregations' do
        expect(query_result.first.keys).to contain_exactly('name', 'mean_duration_in_seconds', 'rate_of_success')
      end
    end
  end

  describe 'sorting functionality' do
    let(:options) do
      {
        select_fields: [:name],
        aggregations: [:mean_duration_in_seconds],
        sort: sort
      }
    end

    context 'with ascending sort' do
      let(:sort) { 'mean_duration_in_seconds_asc' }

      it 'sorts results in ascending order' do
        durations = query_result.pluck('mean_duration_in_seconds')
        expect(durations).to eq(durations.sort)
      end
    end

    context 'with descending sort' do
      let(:sort) { 'mean_duration_in_seconds_desc' }

      it 'sorts results in descending order' do
        durations = query_result.pluck('mean_duration_in_seconds')
        expect(durations).to eq(durations.sort.reverse)
      end
    end
  end

  describe 'name search functionality' do
    context 'with exact match' do
      let(:options) { { name_search: 'compile' } }

      it 'filters by exact name match' do
        expect(query_result.pluck('name').uniq).to contain_exactly('compile', 'compile-slow')
      end
    end

    context 'with partial match' do
      let(:options) { { name_search: 'comp' } }

      it 'filters by partial name match' do
        expect(query_result.pluck('name').uniq).to contain_exactly('compile', 'compile-slow')
      end
    end

    context 'with case insensitive match' do
      let(:options) { { name_search: 'COMPILE' } }

      it 'filters regardless of case' do
        expect(query_result.pluck('name').uniq).to contain_exactly('compile', 'compile-slow')
      end
    end

    context 'with no matches' do
      let(:options) { { name_search: non_existing_project_hashed_path } }

      it 'returns empty result' do
        expect(query_result).to be_empty
      end
    end
  end

  describe 'pipeline attributes filtering' do
    context 'with time range' do
      let(:options) do
        {
          from_time: 1.day.ago,
          to_time: Time.current
        }
      end

      it 'filters by time range' do
        expect(instance.from_time).to eq(Time.current - 1.day)
        expect(instance.to_time).to eq(Time.current)
        expect(query_result).not_to be_empty
      end
    end

    context 'with source filter' do
      let(:options) { { source: 'web' } }

      it 'filters by pipeline source' do
        expect(query_result.pluck('pipeline_id')).to include(source_pipeline.id)
      end
    end

    context 'with ref filter' do
      let(:options) { { ref: 'feature-branch' } }

      it 'filters by pipeline ref' do
        expect(query_result.pluck('pipeline_id')).to include(ref_pipeline.id)
      end
    end

    context 'with multiple pipeline filters' do
      let(:options) do
        {
          from_time: 1.day.ago,
          to_time: Time.current,
          source: 'push',
          ref: 'feature-branch'
        }
      end

      it 'combines all filters correctly' do
        expect(query_result).not_to be_empty
      end
    end
  end

  describe 'default values' do
    context 'with minimal options' do
      let(:options) { {} }

      it 'uses default from_time of 7 days ago' do
        expect(instance.from_time).to be_within(1.minute).of(7.days.ago)
      end

      it 'has empty select_fields by default' do
        expect(instance.select_fields).to eq([])
      end

      it 'has empty aggregations by default' do
        expect(instance.aggregations).to eq([])
      end
    end
  end

  describe 'real-time scenarios' do
    context 'with comprehensive query' do
      let(:options) do
        {
          select_fields: [:name, :stage_id],
          aggregations: [:mean_duration_in_seconds, :rate_of_success],
          sort: 'mean_duration_in_seconds_desc',
          name_search: 'compile',
          from_time: 1.day.ago,
          to_time: Time.current
        }
      end

      it 'combines all features correctly', :aggregate_failures do
        expect(query_result).not_to be_empty
        expect(query_result.first.keys).to contain_exactly(
          'name', 'stage_id', 'mean_duration_in_seconds', 'rate_of_success'
        )
        expect(query_result.pluck('name').uniq).to contain_exactly('compile', 'compile-slow')

        # Assert sorting
        durations = query_result.pluck('mean_duration_in_seconds')
        expect(durations).to eq(durations.sort.reverse)
      end
    end
  end

  private

  def execute_query(query_builder)
    ::ClickHouse::Client.select(query_builder, :main)
  end
end
