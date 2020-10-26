# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'delete a terraform state' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_projects: [project]) }

  let(:state) { create(:terraform_state, project: project) }
  let(:mutation) { graphql_mutation(:terraform_state_delete, id: state.to_global_id.to_s) }

  before do
    post_graphql_mutation(mutation, current_user: user)
  end

  include_examples 'a working graphql query'

  it 'deletes the state' do
    expect { state.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
