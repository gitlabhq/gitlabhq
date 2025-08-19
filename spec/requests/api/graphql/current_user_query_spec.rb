# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information', :with_current_organization, feature_category: :system_access do
  include GraphqlHelpers

  let(:fields) do
    <<~GRAPHQL
      name
      namespace { id }
    GRAPHQL
  end

  let(:query) { graphql_query_for('currentUser', {}, fields) }

  subject { graphql_data['currentUser'] }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when there is a current_user' do
    let(:organization) { current_organization }
    let(:user_namespace) { create(:user_namespace, organization: organization) }
    let(:current_user) { create(:user, namespace: user_namespace) }

    it_behaves_like 'a working graphql query that returns data'

    it { is_expected.to include('name' => current_user.name, 'namespace' => { 'id' => user_namespace.to_global_id.to_s }) }

    context 'when namespace does not exist for organization' do
      let(:organization) { create(:organization, path: 'random-org-1', name: 'Random org 2') }

      it { is_expected.to include('namespace' => nil) }
    end
  end

  context 'when there is no current_user' do
    let(:current_user) { nil }

    it_behaves_like 'a working graphql query that returns no data'
  end
end
