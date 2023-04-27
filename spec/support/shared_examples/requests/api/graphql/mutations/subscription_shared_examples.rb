# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a subscribable resource api' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let(:project) { resource.project }
  let(:input) { { subscribed_state: true } }
  let(:resource_ref) { resource.class.name.camelize(:lower) }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: resource.iid.to_s
    }

    graphql_mutation(
      mutation_name,
      variables.merge(input),
      <<-QL.strip_heredoc
        clientMutationId
        errors
        #{resource_ref} {
          id
          subscribed
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(mutation_name)[resource_ref]['subscribed']
  end

  context 'when the user is not authorized' do
    it_behaves_like 'a mutation that returns top-level errors',
      errors: ["The resource that you are attempting to access "\
               "does not exist or you don't have permission to "\
               "perform this action"]
  end

  context 'when user is authorized' do
    before do
      project.add_developer(current_user)
    end

    it 'marks the resource as subscribed' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response).to eq(true)
    end

    context 'when passing subscribe false as input' do
      let(:input) { { subscribed_state: false } }

      it 'unmarks the resource as subscribed' do
        resource.subscribe(current_user, project)

        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response).to eq(false)
      end
    end
  end
end
