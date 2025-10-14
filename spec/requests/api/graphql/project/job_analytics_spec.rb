# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.jobAnalytics', :click_house, :freeze_time, feature_category: :fleet_visibility do
  include GraphqlHelpers

  include_context 'with CI job analytics test data', with_pipelines: true

  let_it_be_with_reload(:user) { create(:user) }
  let(:current_user) { user }

  let(:job_analytics_args) do
    {
      select_fields: [:NAME],
      aggregations: [:MEAN_DURATION_IN_SECONDS, :RATE_OF_SUCCESS, :RATE_OF_CANCELED, :RATE_OF_FAILED,
        :P95_DURATION_IN_SECONDS]
    }
  end

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:job_analytics, all_graphql_fields_for('CiJobAnalytics'),
        args: job_analytics_args,
        include_pagination_info: true
      )
    )
  end

  let(:nodes) { job_analytics_response['nodes'] }

  before do
    stub_application_setting(use_clickhouse_for_analytics: true)
  end

  def job_analytics_response
    graphql_data_at(:project, :job_analytics)
  end

  def expect_valid_job_analytics_response
    expect_graphql_errors_to_be_empty
    expect(job_analytics_response).not_to be_nil
    expect(nodes).to be_an(Array)
  end

  context 'when user does not have access' do
    let(:current_user) { create(:user) }

    it 'returns null' do
      post_graphql(query, current_user: current_user)

      expect(job_analytics_response).to be_nil
    end
  end

  context 'when user has read_build permission' do
    before do
      project.add_maintainer(user)
    end

    context 'with basic query' do
      it 'returns job analytics data' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response
      end

      it 'returns aggregated metrics' do
        post_graphql(query, current_user: current_user)
        expect_valid_job_analytics_response

        %w[name meanDurationInSeconds p95DurationInSeconds rateOfFailed].each do |key|
          expect(nodes).to all(have_key(key))
        end
      end
    end

    context 'with name search filter' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME],
          aggregations: [:MEAN_DURATION_IN_SECONDS],
          name_search: 'compile'
        }
      end

      it 'filters jobs by name' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response
        expect(nodes.pluck('name')).to contain_exactly('compile', 'compile-slow')
      end
    end

    context 'with stage selection' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME, :STAGE],
          aggregations: [:MEAN_DURATION_IN_SECONDS, :RATE_OF_SUCCESS],
          name_search: 'compile'
        }
      end

      it 'includes stage information' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response
        expect(nodes).to all(have_key('stage'))
        nodes.each do |node|
          expect(node['stage']).to have_key('id')
          expect(node['stage']).to have_key('name')
        end
      end
    end

    context 'with time range filters' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME],
          aggregations: [:MEAN_DURATION_IN_SECONDS],
          from_time: 13.hours.ago.iso8601,
          to_time: Time.current.iso8601
        }
      end

      it 'filters by time range' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response
        expect(nodes.pluck('name')).to contain_exactly('compile', 'compile-slow', 'rspec',
          'lint', 'ref-build', 'source-build')
      end
    end

    context 'with source filter' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME],
          aggregations: [:RATE_OF_SUCCESS],
          source: :WEB
        }
      end

      it 'filters by pipeline source' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response
        expect(nodes.pluck('name')).to contain_exactly('source-build')
      end

      context 'with invalid source value' do
        let(:job_analytics_args) do
          {
            select_fields: [:NAME],
            aggregations: [:RATE_OF_SUCCESS],
            source: :INVALID_SOURCE
          }
        end

        it 'returns a GraphQL error' do
          post_graphql(query, current_user: current_user)

          expect(graphql_errors).not_to be_empty
          expect_graphql_errors_to_include("Argument 'source' on Field 'jobAnalytics' has an invalid value")
        end
      end
    end

    context 'with ref filter' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME],
          aggregations: [:RATE_OF_SUCCESS],
          ref: 'feature-branch'
        }
      end

      it 'filters by ref' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response
        expect(nodes.pluck('name')).to contain_exactly('ref-build')
      end

      context 'with non existing ref value' do
        let(:job_analytics_args) do
          {
            select_fields: [:NAME],
            aggregations: [:RATE_OF_SUCCESS],
            ref: non_existing_project_hashed_path
          }
        end

        it 'filters by ref' do
          post_graphql(query, current_user: current_user)

          expect_valid_job_analytics_response
          expect(nodes).to be_empty
        end
      end
    end

    context 'with sorting' do
      context 'when sorted by mean duration ascending' do
        let(:job_analytics_args) do
          {
            select_fields: [:NAME],
            aggregations: [:MEAN_DURATION_IN_SECONDS],
            sort: :MEAN_DURATION_ASC
          }
        end

        it 'sorts results by mean duration' do
          post_graphql(query, current_user: current_user)

          expect_valid_job_analytics_response
          durations = nodes.pluck('meanDurationInSeconds')
          expect(durations).to eq(durations.sort)
        end
      end

      context 'when sorted by failure rate descending' do
        let(:job_analytics_args) do
          {
            select_fields: [:NAME],
            aggregations: [:RATE_OF_FAILED],
            sort: :FAILED_RATE_DESC
          }
        end

        it 'sorts results by failure rate' do
          post_graphql(query, current_user: current_user)

          expect_valid_job_analytics_response
          rates = nodes.pluck('rateOfFailed')
          expect(rates).to eq(rates.sort.reverse)
        end
      end
    end

    context 'with all aggregations' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME],
          aggregations: [:MEAN_DURATION_IN_SECONDS, :P95_DURATION_IN_SECONDS, :RATE_OF_SUCCESS, :RATE_OF_FAILED,
            :RATE_OF_CANCELED]
        }
      end

      it 'returns all aggregation metrics' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response

        %w[meanDurationInSeconds p95DurationInSeconds rateOfSuccess rateOfFailed rateOfCanceled].each do |key|
          expect(nodes).to all(have_key(key))
        end
      end
    end

    context 'with pagination' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME],
          aggregations: [:MEAN_DURATION_IN_SECONDS],
          first: 2
        }
      end

      it 'supports pagination' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response
        expect(job_analytics_response).to have_key('pageInfo')
        expect(job_analytics_response['nodes'].size).to eq(2)
      end

      context 'with cursor-based pagination' do
        let(:job_analytics_args) do
          {
            select_fields: [:NAME],
            aggregations: [:MEAN_DURATION_IN_SECONDS],
            first: 1,
            sort: :NAME_ASC
          }
        end

        let(:first_page_query) { query }

        it 'supports cursor-based pagination' do
          post_graphql(first_page_query, current_user: current_user)

          expect(nodes.pluck('name')).to eq(%w[compile])

          page_info = job_analytics_response['pageInfo']
          cursor = page_info['endCursor']

          next_page_query = graphql_query_for(
            :project,
            { full_path: project.full_path },
            query_nodes(:job_analytics, all_graphql_fields_for('CiJobAnalytics'),
              args: job_analytics_args.merge(after: cursor),
              include_pagination_info: true
            )
          )

          post_graphql(next_page_query, current_user: current_user)
          expect_graphql_errors_to_be_empty
          expect(job_analytics_response['nodes'].pluck('name')).to eq(%w[compile-slow])
        end
      end

      context 'for backward pagination' do
        let(:job_analytics_args) do
          {
            select_fields: [:NAME],
            aggregations: [:MEAN_DURATION_IN_SECONDS],
            last: 1,
            sort: :NAME_ASC
          }
        end

        it 'returns last page of results' do
          post_graphql(query, current_user: current_user)

          expect_valid_job_analytics_response
          expect(nodes.pluck('name')).to contain_exactly('source-build')
        end

        context 'with cursor-based backward pagination' do
          let(:last_page_cursor) do
            post_graphql(query, current_user: current_user)
            job_analytics_response['pageInfo']['endCursor']
          end

          let(:second_last_page_query) do
            graphql_query_for(
              :project,
              { full_path: project.full_path },
              query_nodes(:job_analytics, all_graphql_fields_for('CiJobAnalytics'),
                args: job_analytics_args.merge(before: last_page_cursor),
                include_pagination_info: true
              )
            )
          end

          it 'paginates backward' do
            post_graphql(second_last_page_query, current_user: current_user)

            expect_valid_job_analytics_response
            expect(nodes.pluck('name')).to contain_exactly('rspec')
          end
        end
      end

      context 'with huge first limit value' do
        let(:job_analytics_args) do
          {
            select_fields: [:NAME],
            aggregations: [:MEAN_DURATION_IN_SECONDS],
            first: 1000,
            sort: :NAME_ASC
          }
        end

        before do
          allow_next_instance_of(Gitlab::Graphql::Pagination::ClickHouseAggregatedConnection) do |instance|
            allow(instance).to receive(:limit_value).and_return(5)
          end
        end

        it 'returns only 5 nodes' do
          post_graphql(query, current_user: current_user)

          expect_valid_job_analytics_response
          expect(nodes.count).to eq(5)
        end
      end
    end

    context 'with complex filters' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME, :STAGE],
          aggregations: [:MEAN_DURATION_IN_SECONDS, :RATE_OF_FAILED],
          name_search: 'source',
          source: :WEB,
          ref: 'master',
          from_time: 7.days.ago.iso8601,
          to_time: Time.current.iso8601,
          sort: :FAILED_RATE_ASC
        }
      end

      it 'applies multiple filters correctly' do
        post_graphql(query, current_user: current_user)

        expect_valid_job_analytics_response
        expect(nodes.pluck('name')).to contain_exactly('source-build')
      end
    end

    context 'when ClickHouse is not configured' do
      before do
        allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(false)
      end

      it 'returns resource not found error' do
        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_include("The resource that you are attempting to access does not exist or you don't " \
          "have permission to perform this action")
      end
    end

    context 'with invalid sort value' do
      let(:job_analytics_args) do
        {
          select_fields: [:NAME],
          aggregations: [:MEAN_DURATION_IN_SECONDS],
          sort: :INVALID_SORT
        }
      end

      it 'returns a GraphQL error' do
        post_graphql(query, current_user: current_user)

        expect(graphql_errors).not_to be_empty
        expect_graphql_errors_to_include("Argument 'sort' on Field 'jobAnalytics' has an invalid value")
      end
    end
  end

  context 'when project is private' do
    let_it_be_with_reload(:private_project) { create(:project, :private) }
    let(:project) { private_project }

    let(:job_analytics_args) do
      {
        select_fields: [:NAME],
        aggregations: [:MEAN_DURATION_IN_SECONDS]
      }
    end

    context 'when user is not a member' do
      it 'returns null for the entire project' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project)).to be_nil
      end
    end

    context 'when user is a member' do
      before_all do
        private_project.add_maintainer(user)
      end

      it 'returns job analytics data' do
        post_graphql(query, current_user: user)

        expect_graphql_errors_to_be_empty
        expect(graphql_data_at(:project)).not_to be_nil
      end
    end
  end

  context 'with public project and anonymous user' do
    let(:current_user) { nil }

    it 'does not return job analytics data' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_be_empty
      expect(graphql_data_at(:project)).to be_nil
    end
  end
end
