# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a Snippet', feature_category: :source_code_management do
  include GraphqlHelpers

  let(:current_user) { snippet.author }
  let(:snippet_gid) { snippet.to_global_id.to_s }
  let(:mutation) do
    variables = {
      id: snippet_gid
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

      context 'when a bad gid is given' do
        let!(:project) { create(:project, :private) }
        let!(:snippet) { create(:project_snippet, :private, project: project, author: create(:user)) }
        let!(:snippet_gid) { project.to_gid.to_s }

        it 'returns an error' do
          err_message = %("#{snippet_gid}" does not represent an instance of Snippet)

          post_graphql_mutation(mutation, current_user: current_user)

          expect(graphql_errors).to include(a_hash_including('message' => a_string_including(err_message)))
        end

        it 'does not destroy the Snippet' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.not_to change { Snippet.count }
        end

        it 'does not destroy the Project' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.not_to change { Project.count }
        end
      end
    end
  end

  describe 'PersonalSnippet' do
    let_it_be(:snippet) { create(:personal_snippet) }

    it_behaves_like 'graphql delete actions'

    it_behaves_like 'when the snippet is not found'
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

    it_behaves_like 'when the snippet is not found'
  end
end
