# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information', feature_category: :system_access do
  include GraphqlHelpers

  let(:fields) do
    <<~GRAPHQL
      name
      namespace { id }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('currentUser', {}, fields)
  end

  subject { graphql_data['currentUser'] }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when there is a current_user' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a working graphql query that returns data'

    it { is_expected.to include('name' => current_user.name, 'namespace' => { 'id' => current_user.namespace.to_global_id.to_s }) }
  end

  context 'when there is no current_user' do
    let(:current_user) { nil }

    it_behaves_like 'a working graphql query that returns no data'
  end
end
