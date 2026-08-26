# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query current user merge request saved views', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:saved_view) do
    create(:merge_request_saved_view, :with_filters, user: current_user, name: 'My reviews')
  end

  let_it_be(:second_saved_view) { create(:merge_request_saved_view, user: current_user, name: 'Team MRs') }
  let_it_be(:other_saved_view) { create(:merge_request_saved_view, user: other_user) }

  let(:fields) do
    <<~GRAPHQL
      nodes {
        id
        name
        filters
        userPermissions {
          updateSavedView
          deleteSavedView
        }
      }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('mergeRequestSavedViews', {}, fields))
  end

  subject(:saved_views) { graphql_data.dig('currentUser', 'mergeRequestSavedViews', 'nodes') }

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query that returns data'

  it 'returns exactly the current user views in id ascending order' do
    expect(saved_views).to match([
      a_graphql_entity_for(saved_view),
      a_graphql_entity_for(second_saved_view)
    ])
  end

  it 'returns the stored filters camelcased', :aggregate_failures do
    expect(saved_views.first['filters']).to eq({
      'state' => 'opened',
      'assigneeUsernames' => ['root'],
      'labelName' => ['bug'],
      'not' => { 'authorUsername' => 'someone-else' }
    })
    expect(saved_views.second['filters']).to eq({})
  end

  it 'returns the owner permissions' do
    permissions = saved_views.first['userPermissions']

    expect(permissions).to eq({ 'updateSavedView' => true, 'deleteSavedView' => true })
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(mr_dashboard_saved_views: false)
      post_graphql(query, current_user: current_user)
    end

    it 'returns an empty result' do
      expect(saved_views).to eq([])
    end
  end

  describe 'N+1 queries', :request_store do
    let(:fields) do
      <<~GRAPHQL
        nodes {
          id
          name
          filters
          userPermissions {
            updateSavedView
          }
        }
      GRAPHQL
    end

    it 'does not increase with more saved views' do
      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

      create(:merge_request_saved_view, user: current_user)
      create(:merge_request_saved_view, user: current_user)

      expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
    end
  end

  describe 'granular PAT authorization' do
    let(:fields) { 'nodes { id }' }

    it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_user, :read_saved_view] do
      let(:user) { current_user }
      let(:boundary_object) { :user }
      let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
    end
  end
end
