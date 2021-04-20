# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Alert Management Alert Assignees' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:first_alert) { create(:alert_management_alert, project: project, assignees: [current_user]) }
  let_it_be(:second_alert) { create(:alert_management_alert, project: project) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        iid
        assignees {
          nodes {
            username
          }
        }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementAlerts', params, fields)
    )
  end

  let(:alerts) { graphql_data.dig('project', 'alertManagementAlerts', 'nodes') }
  let(:assignees) { alerts.to_h { |alert| [alert['iid'], alert['assignees']['nodes']] } }
  let(:first_assignees) { assignees[first_alert.iid.to_s] }
  let(:second_assignees) { assignees[second_alert.iid.to_s] }

  before do
    project.add_developer(current_user)
  end

  it 'returns the correct assignees' do
    post_graphql(query, current_user: current_user)

    expect(first_assignees.length).to eq(1)
    expect(first_assignees.first).to include('username' => current_user.username)
    expect(second_assignees).to be_empty
  end

  it 'applies appropriate filters for non-visible users' do
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(current_user, :read_user, current_user).and_return(false)

    post_graphql(query, current_user: current_user)

    expect(first_assignees).to be_empty
    expect(second_assignees).to be_empty
  end

  describe 'performance' do
    let(:first_n) { var('Int') }
    let(:params) { { first: first_n } }
    let(:limited_query) { with_signature([first_n], query) }

    before do
      create(:alert_management_alert, project: project, assignees: [current_user])
    end

    it 'can limit results' do
      post_graphql(limited_query, current_user: current_user, variables: first_n.with(1))

      expect(alerts.size).to eq 1
      expect(alerts).not_to include(a_hash_including('iid' => first_alert.iid.to_s))
    end

    it 'can include all results' do
      post_graphql(limited_query, current_user: current_user)

      expect(alerts.size).to be > 1
      expect(alerts).to include(a_hash_including('iid' => first_alert.iid.to_s))
    end

    it 'avoids N+1 queries' do
      base_count = ActiveRecord::QueryRecorder.new do
        post_graphql(limited_query, current_user: current_user, variables: first_n.with(1))
      end

      expect { post_graphql(limited_query, current_user: current_user) }.not_to exceed_query_limit(base_count)
    end
  end
end
