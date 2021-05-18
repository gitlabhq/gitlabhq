# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.runners' do
  include GraphqlHelpers

  let_it_be(:current_user) { create_default(:user, :admin) }

  describe 'Query.runners' do
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance, version: 'abc', revision: '123', description: 'Instance runner', ip_address: '127.0.0.1') }
    let_it_be(:project_runner) { create(:ci_runner, :project, active: false, version: 'def', revision: '456', description: 'Project runner', projects: [project], ip_address: '127.0.0.1') }

    let(:runners_graphql_data) { graphql_data['runners'] }

    let(:params) { {} }

    let(:fields) do
      <<~QUERY
        nodes {
          #{all_graphql_fields_for('CiRunner')}
        }
      QUERY
    end

    let(:query) do
      %(
        query {
          runners(type:#{runner_type},status:#{status}) {
            #{fields}
          }
        }
      )
    end

    before do
      post_graphql(query, current_user: current_user)
    end

    shared_examples 'a working graphql query returning expected runner' do
      it_behaves_like 'a working graphql query'

      it 'returns expected runner' do
        expect(runners_graphql_data['nodes'].map { |n| n['id'] }).to contain_exactly(expected_runner.to_global_id.to_s)
      end
    end

    context 'runner_type is INSTANCE_TYPE and status is ACTIVE' do
      let(:runner_type) { 'INSTANCE_TYPE' }
      let(:status) { 'ACTIVE' }

      let!(:expected_runner) { instance_runner }

      it_behaves_like 'a working graphql query returning expected runner'
    end

    context 'runner_type is PROJECT_TYPE and status is NOT_CONNECTED' do
      let(:runner_type) { 'PROJECT_TYPE' }
      let(:status) { 'NOT_CONNECTED' }

      let!(:expected_runner) { project_runner }

      it_behaves_like 'a working graphql query returning expected runner'
    end
  end

  describe 'pagination' do
    let(:data_path) { [:runners] }

    def pagination_query(params)
      graphql_query_for(:runners, params, "#{page_info} nodes { id }")
    end

    def pagination_results_data(runners)
      runners.map { |runner| GitlabSchema.parse_gid(runner['id'], expected_type: ::Ci::Runner).model_id.to_i }
    end

    let_it_be(:runners) do
      common_args = {
        version: 'abc',
        revision: '123',
        ip_address: '127.0.0.1'
      }

      [
        create(:ci_runner, :instance, created_at: 4.days.ago, contacted_at: 3.days.ago, **common_args),
        create(:ci_runner, :instance, created_at: 30.hours.ago, contacted_at: 1.day.ago, **common_args),
        create(:ci_runner, :instance, created_at: 1.day.ago, contacted_at: 1.hour.ago, **common_args),
        create(:ci_runner, :instance, created_at: 2.days.ago, contacted_at: 2.days.ago, **common_args),
        create(:ci_runner, :instance, created_at: 3.days.ago, contacted_at: 1.second.ago, **common_args)
      ]
    end

    context 'when sorted by contacted_at ascending' do
      let(:ordered_runners) { runners.sort_by(&:contacted_at) }

      it_behaves_like 'sorted paginated query' do
        let(:sort_param)       { :CONTACTED_ASC }
        let(:first_param)      { 2 }
        let(:expected_results) { ordered_runners.map(&:id) }
      end
    end

    context 'when sorted by created_at' do
      let(:ordered_runners) { runners.sort_by(&:created_at).reverse }

      it_behaves_like 'sorted paginated query' do
        let(:sort_param)       { :CREATED_DESC }
        let(:first_param)      { 2 }
        let(:expected_results) { ordered_runners.map(&:id) }
      end
    end
  end
end
