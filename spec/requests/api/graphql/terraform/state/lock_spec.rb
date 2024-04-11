# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lock a terraform state', feature_category: :infrastructure_as_code do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:state) { create(:terraform_state, project: project) }
  let(:mutation) { graphql_mutation(:terraform_state_lock, id: state.to_global_id.to_s) }

  before do
    expect(state).not_to be_locked
    post_graphql_mutation(mutation, current_user: user)
  end

  include_examples 'a working graphql query'

  it 'locks the state' do
    expect(state.reload).to be_locked
    expect(state.locked_by_user).to eq(user)
  end
end
