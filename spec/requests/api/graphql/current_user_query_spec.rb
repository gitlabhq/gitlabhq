# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information' do
  include GraphqlHelpers

  let(:query) do
    graphql_query_for('currentUser', {}, 'name')
  end

  subject { graphql_data['currentUser'] }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when there is a current_user' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a working graphql query'

    it { is_expected.to include('name' => current_user.name) }
  end

  context 'when there is no current_user' do
    let(:current_user) { nil }

    it_behaves_like 'a working graphql query'

    it { is_expected.to be_nil }
  end
end
