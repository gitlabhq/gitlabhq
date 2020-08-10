# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying a Milestone' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  let(:query) do
    graphql_query_for('milestone', { id: milestone.to_global_id.to_s }, 'title')
  end

  subject { graphql_data['milestone'] }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when the user has access to the milestone' do
    before_all do
      project.add_guest(current_user)
    end

    it_behaves_like 'a working graphql query'

    it { is_expected.to include('title' => milestone.name) }
  end

  context 'when the user does not have access to the milestone' do
    it_behaves_like 'a working graphql query'

    it { is_expected.to be_nil }
  end

  context 'when ID argument is missing' do
    let(:query) do
      graphql_query_for('milestone', {}, 'title')
    end

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' => "Field 'milestone' is missing required arguments: id"))
    end
  end
end
