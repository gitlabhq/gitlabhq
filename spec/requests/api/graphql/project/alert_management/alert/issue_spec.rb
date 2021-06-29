# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Alert Management Alert Issue' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let(:payload) { {} }
  let(:query) { 'avg(metric) > 1.0' }

  let(:fields) do
    <<~QUERY
      nodes {
        iid
        issue {
          iid
          state
        }
      }
    QUERY
  end

  let(:graphql_query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementAlerts', {}, fields)
    )
  end

  let(:alerts) { graphql_data.dig('project', 'alertManagementAlerts', 'nodes') }
  let(:first_alert) { alerts.first }

  before do
    project.add_developer(current_user)
  end

  context 'with gitlab alert' do
    before do
      create(:alert_management_alert, :with_issue, project: project, payload: payload)
    end

    it 'includes the correct alert issue payload data' do
      post_graphql(graphql_query, current_user: current_user)

      expect(first_alert).to include('issue' => { "iid" => "1", "state" => "opened" })
    end
  end

  describe 'performance' do
    let(:first_n) { var('Int') }
    let(:params) { { first: first_n } }
    let(:limited_query) { with_signature([first_n], query) }

    context 'with gitlab alert' do
      before do
        create(:alert_management_alert, :with_issue, project: project, payload: payload)
      end

      it 'avoids N+1 queries' do
        base_count = ActiveRecord::QueryRecorder.new do
          post_graphql(limited_query, current_user: current_user, variables: first_n.with(1))
        end

        expect { post_graphql(limited_query, current_user: current_user) }.not_to exceed_query_limit(base_count)
      end
    end
  end
end
