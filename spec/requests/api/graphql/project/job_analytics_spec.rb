# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.jobAnalytics', :click_house, :freeze_time, feature_category: :fleet_visibility do
  include GraphqlHelpers

  include_context 'with CI job analytics test data', with_pipelines: true, with_siphon: true

  let_it_be_with_reload(:user) { create(:user, maintainer_of: project) }
  let(:current_user) { user }
  let(:job_analytics_args) { {} }

  let(:basic_fields) do
    query_graphql_field(:nodes, nil, [
      :name,
      query_graphql_field(:statistics, nil, [
        query_graphql_field(:duration_statistics, nil, [:p95]),
        aliased_graphql_field(:success_rate, :rate, { status: :SUCCESS }),
        aliased_graphql_field(:failed_rate, :rate, { status: :FAILED }),
        aliased_graphql_field(:other_rate, :rate, { status: :OTHER })
      ])
    ])
  end

  let(:simple_name_fields) do
    query_graphql_field(:nodes, nil, [:name])
  end

  let(:duration_stats_fields) do
    query_graphql_field(:nodes, nil, [
      :name,
      query_graphql_field(:statistics, nil, [
        query_graphql_field(:duration_statistics, nil, [:mean])
      ])
    ])
  end

  let(:pagination_fields) do
    "#{query_graphql_field(:nodes, nil, [
      :name,
      query_graphql_field(:statistics, nil, [
        query_graphql_field(:duration_statistics, nil, [:mean])
      ])
    ])} #{page_info_selection}"
  end

  let(:job_analytics_fields) { basic_fields }
  let(:query) do
    graphql_query_for(
      :project,
      { fullPath: project.full_path },
      query_graphql_field(:jobAnalytics, job_analytics_args, job_analytics_fields)
    )
  end

  let(:nodes) do
    job_analytics_response['nodes'].tap do |response_nodes|
      expect_valid_job_analytics_response(response_nodes)
    end
  end

  before do
    stub_application_setting(use_clickhouse_for_analytics: true)
    post_graphql(query, current_user: current_user) # all the examples use the response of this request
  end

  def job_analytics_response
    graphql_data_at(:project, :job_analytics)
  end

  def expect_valid_job_analytics_response(nodes)
    expect_graphql_errors_to_be_empty
    expect(job_analytics_response).not_to be_nil
    expect(nodes).to be_an(Array)
  end

  context 'when user does not have access' do
    let(:current_user) { create(:user) }

    it { expect(job_analytics_response).to be_nil }
  end

  context 'when user has read_build permission' do
    let(:compile_node_stats) { nodes.find { |n| n['name'] == 'compile' }['statistics'] }
    let(:rspec_node_stats) { nodes.find { |n| n['name'] == 'rspec' }['statistics'] }

    shared_examples 'job analytics data queries' do
      context 'with basic query' do
        it { expect(nodes).to be_present }

        it 'returns aggregated metrics in nested structures' do
          expect(nodes).to all(
            match(
              a_hash_including(
                'name' => an_instance_of(String),
                'statistics' => an_instance_of(Hash)
              )
            )
          )
        end
      end

      context 'with name search filter' do
        let(:job_analytics_args) { { nameSearch: 'compile' } }
        let(:job_analytics_fields) { duration_stats_fields }

        it { expect(nodes).to all(include('name' => a_string_matching(/^compile/))) }
      end

      context 'with time range filters' do
        let(:job_analytics_args) { { fromTime: 13.hours.ago.iso8601, toTime: Time.current.iso8601 } }
        let(:job_analytics_fields) { duration_stats_fields }

        it 'filters by time range' do
          expect(nodes.pluck('name')).to contain_exactly('compile', 'compile-slow', 'rspec',
            'lint', 'ref-build', 'source-build')
        end
      end

      context 'with source filter' do
        let(:job_analytics_args) { { source: :WEB } }

        it { expect(nodes).to all(include('name' => 'source-build')) }
      end

      context 'with ref filter' do
        let(:job_analytics_args) { { ref: 'feature-branch' } }

        it { expect(nodes).to all(include('name' => 'ref-build')) }

        context 'with non existing ref value' do
          let(:job_analytics_args) { { ref: non_existing_project_hashed_path } }
          let(:job_analytics_fields) { simple_name_fields }

          it { expect(nodes).to be_empty }
        end
      end

      context 'with sorting' do
        context 'when sorted by mean duration ascending' do
          let(:job_analytics_args) { { sort: :MEAN_DURATION_ASC } }
          let(:job_analytics_fields) { duration_stats_fields }
          let(:durations) { nodes.map { |n| n.dig('statistics', 'durationStatistics', 'mean') } }

          it { expect(durations).to eq(durations.compact.sort) }
        end

        context 'when sorted by failure rate descending' do
          let(:job_analytics_args) { { sort: :FAILED_RATE_DESC } }
          let(:job_analytics_fields) { basic_fields }
          let(:failed_rates) { nodes.map { |n| n.dig('statistics', 'failedRate') } }

          it 'returns non-nil rates in descending order with nils last' do
            # ClickHouse sorts NULLs last by default in DESC order
            # NULLs come from jobs whose denominator is 0 (success + failed == 0).
            non_nil_count = failed_rates.compact.size

            expect(failed_rates.first(non_nil_count)).to eq(failed_rates.compact.sort.reverse)
            expect(failed_rates.drop(non_nil_count)).to all(be_nil)
          end
        end

        context 'when sorted by stage name ascending' do
          let(:job_analytics_args) { { sort: :STAGE_NAME_ASC } }
          let(:job_analytics_fields) do
            query_graphql_field(:nodes, nil, [:name, :stage_name])
          end

          let(:stage_names) { nodes.pluck('stageName') }

          it { expect(stage_names).to eq(stage_names.sort) }
        end

        context 'when sorted by stage name descending' do
          let(:job_analytics_args) { { sort: :STAGE_NAME_DESC } }
          let(:job_analytics_fields) do
            query_graphql_field(:nodes, nil, [:name, :stage_name])
          end

          let(:stage_names) { nodes.pluck('stageName') }

          it { expect(stage_names).to eq(stage_names.sort.reverse) }
        end

        context 'when sorted by stage name without requesting stage_name field' do
          let(:job_analytics_args) { { sort: :STAGE_NAME_ASC } }
          let(:job_analytics_fields) { simple_name_fields }
          let(:stage_names) { nodes.pluck('stageName') }

          it 'returns results sorted correctly without errors' do
            expect_graphql_errors_to_be_empty
            expect(stage_names).to eq(stage_names.sort)
          end
        end
      end

      context 'with all aggregations' do
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            query_graphql_field(:statistics, nil, [
              query_graphql_field(:duration_statistics, nil, [:mean, :p95]),
              aliased_graphql_field(:success_rate, :rate, { status: :SUCCESS }),
              aliased_graphql_field(:failed_rate, :rate, { status: :FAILED }),
              aliased_graphql_field(:other_rate, :rate, { status: :OTHER })
            ])
          ])
        end

        it 'returns all requested metrics' do
          expect(nodes).to all(
            include('statistics' => a_hash_including(
              'durationStatistics' => include('mean', 'p95'),
              'successRate' => anything,
              'failedRate' => anything,
              'otherRate' => anything
            ))
          )
        end
      end

      context 'with pagination' do
        let(:job_analytics_args) { { first: 2 } }
        let(:job_analytics_fields) { pagination_fields }

        it 'supports pagination' do
          expect(job_analytics_response).to have_key('pageInfo')
          expect(nodes.size).to eq(2)
        end

        context 'for forward pagination' do
          let(:job_analytics_args) { { first: 1, sort: :NAME_ASC } }
          let(:job_analytics_fields) { pagination_fields }

          it { expect(nodes).to all(include('name' => 'compile')) }

          context 'with cursor for next page' do
            before do
              post_graphql(
                graphql_query_for(:project, { fullPath: project.full_path },
                  query_graphql_field(:jobAnalytics,
                    { first: 1, sort: :NAME_ASC,
                      after: job_analytics_response.dig('pageInfo', 'endCursor') },
                    simple_name_fields)),
                current_user: current_user
              )
            end

            it 'returns second page results' do
              expect(nodes).to all(include('name' => 'compile-slow'))
            end
          end
        end

        context 'for backward pagination' do
          let(:job_analytics_args) { { last: 1, sort: :NAME_ASC } }
          let(:job_analytics_fields) { simple_name_fields }

          it 'returns last page of results' do
            expect(nodes).to all(include('name' => 'source-build'))
          end

          context 'with cursor-based backward pagination' do
            let(:job_analytics_args) { { last: 1, sort: :NAME_ASC } }
            let(:job_analytics_fields) { pagination_fields }

            before do
              second_last_page_query = graphql_query_for(
                :project,
                { fullPath: project.full_path },
                query_graphql_field(
                  :jobAnalytics,
                  { last: 1, sort: :NAME_ASC, before: job_analytics_response['pageInfo']['endCursor'] },
                  simple_name_fields
                )
              )

              post_graphql(second_last_page_query, current_user: current_user)
            end

            # When paginating backward by name (ASC), the last page is 'source-build'
            # and the second-to-last page is 'rspec' as per test setup data
            it 'returns second-to-last page when paginating backward from end' do
              expect(nodes).to all match('name' => 'rspec')
            end
          end
        end

        context 'with huge first limit value' do
          let(:job_analytics_args) { { first: 1000, sort: :NAME_ASC } }
          let(:job_analytics_fields) { simple_name_fields }

          before do
            allow_next_instance_of(Gitlab::Graphql::Pagination::ClickHouseAggregatedConnection) do |instance|
              allow(instance).to receive(:limit_value).and_return(5)
            end
            post_graphql(query, current_user: current_user)
          end

          it { expect(nodes.count).to eq(5) }
        end
      end

      context 'with complex filters' do
        let(:job_analytics_args) do
          {
            nameSearch: 'source',
            source: :WEB,
            ref: 'master',
            fromTime: 7.days.ago.iso8601,
            toTime: Time.current.iso8601,
            sort: :FAILED_RATE_ASC
          }
        end

        it { expect(nodes).to all(include('name' => 'source-build')) }
      end

      context 'with stage_name selection' do
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            :stage_name
          ])
        end

        it { expect(nodes).to all(have_key('stageName')) }

        it { expect(nodes.pluck('stageName').uniq).to contain_exactly('build', 'test', 'source-stage', 'ref-stage') }
      end

      context 'when only name is requested' do
        let(:job_analytics_fields) { simple_name_fields }

        it { expect(nodes).to all(match('name' => an_instance_of(String))) }
      end

      describe 'count fields with status parameter' do
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            query_graphql_field(:statistics, nil, [
              aliased_graphql_field(:success_count, :count, { status: :SUCCESS }),
              aliased_graphql_field(:failed_count, :count, { status: :FAILED }),
              aliased_graphql_field(:total_count, :count)
            ])
          ])
        end

        it { expect(nodes).to all(include('statistics' => include('successCount', 'failedCount', 'totalCount'))) }

        # compile: 3 successful builds
        it { expect(compile_node_stats).to include('successCount' => '3', 'failedCount' => '0', 'totalCount' => '3') }

        # rspec: 2 failed, 1 canceled (other)
        it { expect(rspec_node_stats).to include('successCount' => '0', 'failedCount' => '2', 'totalCount' => '3') }
      end

      describe 'combining counts with rates using status parameter' do
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            query_graphql_field(:statistics, nil, [
              aliased_graphql_field(:success_count, :count, { status: :SUCCESS }),
              aliased_graphql_field(:failed_count, :count, { status: :FAILED }),
              aliased_graphql_field(:success_rate, :rate, { status: :SUCCESS }),
              aliased_graphql_field(:failed_rate, :rate, { status: :FAILED }),
              aliased_graphql_field(:total_count, :count)
            ])
          ])
        end

        # Denominator excludes canceled/skipped: only success + failed.
        let(:failed_rate) do
          denominator = rspec_node_stats['successCount'].to_f + rspec_node_stats['failedCount'].to_f
          ((rspec_node_stats['failedCount'].to_f / denominator) * 100).round(2)
        end

        it 'returns both counts and rates' do
          expect(compile_node_stats).to match(
            'successCount' => '3',
            'failedCount' => '0',
            'totalCount' => '3',
            'successRate' => 100.0,
            'failedRate' => 0.0
          )
        end

        it { expect(failed_rate).to be_within(0.01).of(rspec_node_stats['failedRate']) }
      end

      describe 'durationStatistics field' do
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            query_graphql_field(:statistics, nil, [
              query_graphql_field(:duration_statistics, nil, [:mean, :p50, :p95])
            ])
          ])
        end

        it 'returns duration statistics as a nested object' do
          expect(nodes).to all(include('statistics' => include('durationStatistics' => include('mean', 'p50', 'p95'))))
        end

        # compile jobs have 1 second duration
        it { expect(compile_node_stats['durationStatistics']).to include('mean' => 1.0, 'p50' => 1.0, 'p95' => 1.0) }
      end

      describe 'p50 duration field' do
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            query_graphql_field(:statistics, nil, [
              query_graphql_field(:duration_statistics, nil, [:p50])
            ])
          ])
        end

        it { expect(nodes).to all(include('statistics' => include('durationStatistics' => include('p50')))) }
      end

      describe 'sorting by p50 duration' do
        let(:job_analytics_args) { { sort: :P50_DURATION_ASC } }
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            query_graphql_field(:statistics, nil, [
              query_graphql_field(:duration_statistics, nil, [:p50])
            ])
          ])
        end

        let(:durations) { nodes.map { |n| n.dig('statistics', 'durationStatistics', 'p50') } }

        it { expect(durations).to eq(durations.compact.sort) }
      end

      describe 'all percentile values' do
        let(:percentiles) { [:p50, :p75, :p90, :p95, :p99] }
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            query_graphql_field(:statistics, nil, [
              query_graphql_field(:duration_statistics, nil, percentiles)
            ])
          ])
        end

        it 'returns all percentile values' do
          expect(nodes).to all(
            include('statistics' => include('durationStatistics' => include(*percentiles.map(&:to_s))))
          )
        end
      end

      describe 'sorting by different percentiles' do
        where(:percentile, :sort_order, :direction) do
          [
            [:p75, :P75_DURATION_DESC, :desc],
            [:p99, :P99_DURATION_ASC, :asc]
          ]
        end

        with_them do
          let(:job_analytics_args) { { sort: sort_order } }
          let(:job_analytics_fields) do
            query_graphql_field(:nodes, nil, [
              :name,
              query_graphql_field(:statistics, nil, [
                query_graphql_field(:duration_statistics, nil, [percentile])
              ])
            ])
          end

          let(:durations) { nodes.map { |n| n.dig('statistics', 'durationStatistics', percentile.to_s) } }

          it "sorts by #{params[:percentile]} duration #{params[:direction]}ending" do
            expected = direction == :desc ? durations.compact.sort.reverse : durations.compact.sort
            expect(durations).to eq(expected)
          end
        end
      end

      describe 'when no duration aggregations are requested' do
        let(:job_analytics_fields) do
          query_graphql_field(:nodes, nil, [
            :name,
            query_graphql_field(:statistics, nil, [
              aliased_graphql_field(:total_count, :count)
            ])
          ])
        end

        it { expect(nodes.pluck('statistics')).to all(not_include('durationStatistics')) }
      end

      describe 'edge cases for field selection and aggregation detection' do
        context 'when selecting no fields to group' do
          let(:job_analytics_fields) do
            query_graphql_field(:nodes, nil, [
              query_graphql_field(:statistics, nil, [
                query_graphql_field(:duration_statistics, nil, [:mean])
              ])
            ])
          end

          it 'uses name field internally for grouping even when not requested' do
            expect(nodes).to include(
              a_hash_including('statistics' => include('durationStatistics' => include('mean')))
            ).and be_present
          end
        end

        context 'when requesting rate without status argument' do
          let(:job_analytics_fields) do
            query_graphql_field(:nodes, nil, [
              :name,
              query_graphql_field(:statistics, nil, [
                aliased_graphql_field(:overall_rate, :rate)
              ])
            ])
          end

          it { expect(nodes).to all(include('statistics' => include('overallRate' => 100.0))) }
        end

        context 'when no statistics field is selected' do
          let(:job_analytics_fields) { simple_name_fields }

          it { expect(nodes.map(&:keys)).to all(contain_exactly('name')) }
        end

        context 'when using edges instead of nodes' do
          let(:job_analytics_fields) do
            query_graphql_field(:edges, nil, [
              query_graphql_field(:node, nil, [
                :name,
                query_graphql_field(:statistics, nil, [
                  query_graphql_field(:duration_statistics, nil, [:mean])
                ])
              ])
            ])
          end

          let(:edges) { job_analytics_response['edges'] }

          it { expect(edges).to all(include('node' => include('name', 'statistics'))).and be_present }
        end

        context 'when sorting by name' do
          let(:job_analytics_args) { { sort: :NAME_ASC } }

          it { expect(nodes.pluck('name')).to match_array(nodes.pluck('name').sort) }
        end

        context 'when sorting by name descending' do
          let(:job_analytics_args) { { sort: :NAME_DESC } }

          it { expect(nodes.pluck('name')).to match_array(nodes.pluck('name').sort.reverse) }
        end
      end
    end

    context 'with job_analytics_siphon disabled' do
      before do
        stub_feature_flags(job_analytics_siphon: false)
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'job analytics data queries'

      it 'reads through the ci_finished_builds finder' do
        expect(::ClickHouse::Finders::Ci::FinishedBuildsFinder)
          .to receive(:new).at_least(:once).and_call_original

        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_be_empty
      end
    end

    it_behaves_like 'job analytics data queries'

    it 'reads through the siphon finder' do
      expect(::ClickHouse::Finders::Ci::SiphonFinishedBuildsFinder)
        .to receive(:new).at_least(:once).and_call_original

      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_be_empty
    end

    context 'with invalid source value' do
      let(:job_analytics_args) { { source: :INVALID_SOURCE } }
      let(:job_analytics_fields) { simple_name_fields }

      it { expect_graphql_errors_to_include("Argument 'source' on Field 'jobAnalytics' has an invalid value") }
    end

    context 'with invalid sort value' do
      let(:job_analytics_args) { { sort: 'INVALID_SORT' } }
      let(:job_analytics_fields) { simple_name_fields }

      it { expect_graphql_errors_to_include("Argument 'sort' on Field 'jobAnalytics' has an invalid value") }
    end

    context 'when backfill is in progress' do
      let(:job_analytics_fields) do
        query_graphql_field(:nodes, nil, [
          :name,
          query_graphql_field(:statistics, nil, [
            query_graphql_field(:duration_statistics, nil, [:mean, :p95]),
            aliased_graphql_field(:success_rate, :rate, { status: :SUCCESS }),
            aliased_graphql_field(:failed_rate, :rate, { status: :FAILED }),
            aliased_graphql_field(:other_rate, :rate, { status: :OTHER })
          ])
        ])
      end

      before do
        stub_feature_flags(job_analytics_siphon: false)
        allow(::ClickHouse::MigrationSupport::CiFinishedBuildsConsistencyHelper).to receive(:backfill_in_progress?)
          .and_return(true)
      end

      it 'returns result using deduplicated finder' do
        expect_next_instance_of(::ClickHouse::Finders::Ci::FinishedBuildsDeduplicatedFinder) do |instance|
          allow(instance).to receive(:final_query).and_call_original
        end.at_least(:once)

        post_graphql(query, current_user: current_user)

        expect(nodes).to all(
          include('statistics' => a_hash_including(
            'durationStatistics' => include('mean', 'p95'),
            'successRate' => anything,
            'failedRate' => anything,
            'otherRate' => anything
          ))
        )
      end
    end

    context 'when ClickHouse is not configured' do
      before do
        allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(false)
        post_graphql(query, current_user: current_user)
      end

      it 'returns resource not found error' do
        expect_graphql_errors_to_include("The resource that you are attempting to access does not exist or you don't " \
          "have permission to perform this action")
      end
    end

    describe 'fromTime lookback limit' do
      using RSpec::Parameterized::TableSyntax

      let(:job_analytics_fields) { simple_name_fields }
      let(:max_lookback) { Resolvers::Ci::JobAnalyticsResolver::MAX_LOOKBACK }
      let(:error_message) { "`fromTime` cannot be earlier than #{max_lookback.inspect} ago." }

      def from_time_for(scenario)
        case scenario
        when :within           then 30.days.ago
        when :at_boundary      then max_lookback.ago
        when :at_midnight      then max_lookback.ago.utc.beginning_of_day
        when :one_second_over  then max_lookback.ago.utc.beginning_of_day - 1.second
        when :over             then (max_lookback + 1.day).ago
        end
      end

      where(:scenario, :valid) do
        :within          | true
        :at_boundary     | true
        :at_midnight     | true
        :one_second_over | false
        :over            | false
      end

      with_them do
        let(:job_analytics_args) do
          { fromTime: from_time_for(scenario).iso8601, toTime: Time.current.iso8601 }
        end

        it 'validates fromTime against the maximum lookback' do
          if valid
            expect_graphql_errors_to_be_empty
          else
            expect_graphql_errors_to_include(error_message)
          end
        end
      end

      context 'when fromTime is earlier than the maximum lookback' do
        let(:job_analytics_args) do
          { fromTime: (max_lookback + 1.day).ago.iso8601, toTime: Time.current.iso8601 }
        end

        it 'does not query ClickHouse', :aggregate_failures do
          expect(::ClickHouse::Client).not_to receive(:select)

          post_graphql(query, current_user: current_user)

          expect_graphql_errors_to_include(error_message)
        end
      end

      context 'when neither fromTime nor toTime is provided' do
        let(:job_analytics_args) { {} }

        it 'uses the default 7-day lookback and succeeds' do
          expect_graphql_errors_to_be_empty
        end
      end

      context 'when fromTime is explicitly null' do
        let(:job_analytics_args) { { fromTime: nil } }

        it 'is treated as omitted and uses the default lookback' do
          expect_graphql_errors_to_be_empty
        end
      end
    end
  end

  context 'when project is private' do
    let_it_be_with_reload(:private_project) { create(:project, :private) }
    let(:project) { private_project }

    let(:job_analytics_fields) { duration_stats_fields }

    context 'when user is not a member' do
      it { expect(graphql_data_at(:project)).to be_nil }
    end

    context 'when user is a member' do
      before_all do
        private_project.add_maintainer(user)
      end

      it { expect(nodes).not_to be_nil }
    end
  end

  context 'with public project and anonymous user' do
    let(:current_user) { nil }

    it { expect(graphql_data_at(:project)).to be_nil }
  end
end
