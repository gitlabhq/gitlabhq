# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a todo', feature_category: :team_planning do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:current_user) { create(:user) }

  let(:input) do
    {
      'targetId' => target.to_global_id.to_s
    }
  end

  let(:mutation) { graphql_mutation(:todoCreate, input) }

  let(:mutation_response) { graphql_mutation_response(:todoCreate) }

  shared_examples 'creates a todo for the target' do
    context 'the user is not allowed to create todo' do
      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when user has permissions to create todo' do
      before do
        target.project.add_reporter(current_user)
      end

      it_behaves_like 'authorizing granular token permissions for GraphQL', :create_todo do
        let(:user) { current_user }
        let(:boundary_object) { target.project }
        let(:mutation) { graphql_mutation(:todoCreate, input, 'errors') }
        let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
      end

      it 'creates todo' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['todo']['state']).to eq('pending')
      end
    end
  end

  context 'when target is an issue' do
    let_it_be(:target) { create(:issue) }

    it_behaves_like 'creates a todo for the target'
  end

  context 'when target is a merge request' do
    let_it_be(:target) { create(:merge_request) }

    it_behaves_like 'creates a todo for the target'
  end

  context 'when target is a design' do
    let_it_be(:target) { create(:design, :with_versions) }

    before do
      enable_design_management
    end

    it_behaves_like 'creates a todo for the target'
  end
end
