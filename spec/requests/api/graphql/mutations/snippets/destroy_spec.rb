# frozen_string_literal: true

require 'spec_helper'

describe 'Destroying a Snippet' do
  include GraphqlHelpers

  let(:current_user) { snippet.author }
  let(:mutation) do
    variables = {
      id: snippet.to_global_id.to_s
    }

    graphql_mutation(:destroy_snippet, variables)
  end

  def mutation_response
    graphql_mutation_response(:destroy_snippet)
  end

  shared_examples 'graphql delete actions' do
    context 'when the user does not have permission' do
      let(:current_user) { create(:user) }

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

      it 'does not destroy the Snippet' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change { Snippet.count }
      end
    end

    context 'when the user has permission' do
      it 'destroys the Snippet' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { Snippet.count }.by(-1)
      end

      it 'returns an empty Snippet' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to have_key('snippet')
        expect(mutation_response['snippet']).to be_nil
      end
    end
  end

  describe 'PersonalSnippet' do
    it_behaves_like 'graphql delete actions' do
      let_it_be(:snippet) { create(:personal_snippet) }
    end
  end

  describe 'ProjectSnippet' do
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:snippet) { create(:project_snippet, :private, project: project, author: create(:user)) }

    context 'when the author is not a member of the project' do
      it 'returns an an error' do
        post_graphql_mutation(mutation, current_user: current_user)
        errors = json_response['errors']

        expect(errors.first['message']).to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end

    context 'when the author is a member of the project' do
      before do
        project.add_developer(current_user)
      end

      it_behaves_like 'graphql delete actions'

      context 'when the snippet project feature is disabled' do
        it 'returns an an error' do
          project.project_feature.update_attribute(:snippets_access_level, ProjectFeature::DISABLED)

          post_graphql_mutation(mutation, current_user: current_user)
          errors = json_response['errors']

          expect(errors.first['message']).to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
        end
      end
    end
  end
end
