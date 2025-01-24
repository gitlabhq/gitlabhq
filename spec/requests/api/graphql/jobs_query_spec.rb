# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting job information', feature_category: :continuous_integration do
  include GraphqlHelpers

  let(:query) do
    graphql_query_for(
      :jobs, {}, %(
      count
      nodes {
        #{all_graphql_fields_for(::Types::Ci::JobType, max_depth: 1)}
      })
    )
  end

  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:job) { create(:ci_build, :success, name: 'job1', runner: runner) }

  subject(:request) { post_graphql(query, current_user: current_user) }

  context 'when user is admin' do
    let_it_be(:current_user) { create(:admin) }

    it 'has full access to all jobs', :aggregate_failures do
      request

      expect(graphql_data_at(:jobs, :count)).to eq(1)
      expect(graphql_data_at(:jobs, :nodes)).to contain_exactly(a_graphql_entity_for(job))
    end

    context 'when filtered by status' do
      let_it_be(:pending_job) { create(:ci_build, :pending) }
      let_it_be(:failed_job) { create(:ci_build, :failed) }

      it 'gets pending jobs', :aggregate_failures do
        post_graphql(graphql_query_for(:jobs, { statuses: :PENDING }), current_user: current_user)

        expect(graphql_data_at(:jobs, :count)).to eq(1)
        expect(graphql_data_at(:jobs, :nodes)).to contain_exactly(a_graphql_entity_for(pending_job))
      end

      it 'gets pending and failed jobs', :aggregate_failures do
        post_graphql(graphql_query_for(:jobs, { statuses: [:PENDING, :FAILED] }), current_user: current_user)

        expect(graphql_data_at(:jobs, :count)).to eq(2)
        expect(graphql_data_at(:jobs, :nodes)).to match_array([a_graphql_entity_for(pending_job),
                                                               a_graphql_entity_for(failed_job)])
      end
    end

    context 'when N+1 queries' do
      it 'avoids N+1 queries successfully', :use_sql_query_cache do
        post_graphql(query, current_user: current_user) # warmup

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        create(:ci_build, :success, name: 'job2', runner: create(:ci_runner))

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
      end
    end
  end

  context 'if the user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    it 'has no access to the jobs', :aggregate_failures do
      request

      expect(graphql_data_at(:jobs, :count)).to eq(0)
      expect(graphql_data_at(:jobs, :nodes)).to be_empty
    end
  end
end
