# frozen_string_literal: true

require 'spec_helper'

describe 'Updating a Snippet' do
  include GraphqlHelpers

  let_it_be(:original_content) { 'Initial content' }
  let_it_be(:original_description) { 'Initial description' }
  let_it_be(:original_title) { 'Initial title' }
  let_it_be(:original_file_name) { 'Initial file_name' }
  let(:updated_content) { 'Updated content' }
  let(:updated_description) { 'Updated description' }
  let(:updated_title) { 'Updated_title' }
  let(:updated_file_name) { 'Updated file_name' }
  let(:current_user) { snippet.author }

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(snippet).to_s,
      content: updated_content,
      description: updated_description,
      visibility_level: 'public',
      file_name: updated_file_name,
      title: updated_title
    }

    graphql_mutation(:update_snippet, variables)
  end

  def mutation_response
    graphql_mutation_response(:update_snippet)
  end

  shared_examples 'graphql update actions' do
    context 'when the user does not have permission' do
      let(:current_user) { create(:user) }

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

      it 'does not update the Snippet' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change { snippet.reload }
      end
    end

    context 'when the user has permission' do
      it 'updates the Snippet' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(snippet.reload.title).to eq(updated_title)
      end

      it 'returns the updated Snippet' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['snippet']['content']).to eq(updated_content)
        expect(mutation_response['snippet']['title']).to eq(updated_title)
        expect(mutation_response['snippet']['description']).to eq(updated_description)
        expect(mutation_response['snippet']['fileName']).to eq(updated_file_name)
        expect(mutation_response['snippet']['visibilityLevel']).to eq('public')
      end

      context 'when there are ActiveRecord validation errors' do
        let(:updated_title) { '' }

        it_behaves_like 'a mutation that returns errors in the response', errors: ["Title can't be blank"]

        it 'does not update the Snippet' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(snippet.reload.title).to eq(original_title)
        end

        it 'returns the Snippet with its original values' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['snippet']['content']).to eq(original_content)
          expect(mutation_response['snippet']['title']).to eq(original_title)
          expect(mutation_response['snippet']['description']).to eq(original_description)
          expect(mutation_response['snippet']['fileName']).to eq(original_file_name)
          expect(mutation_response['snippet']['visibilityLevel']).to eq('private')
        end
      end
    end
  end

  describe 'PersonalSnippet' do
    it_behaves_like 'graphql update actions' do
      let_it_be(:snippet) do
        create(:personal_snippet,
               :private,
               file_name: original_file_name,
               title: original_title,
               content: original_content,
               description: original_description)
      end
    end
  end

  describe 'ProjectSnippet' do
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:snippet) do
      create(:project_snippet,
             :private,
             project: project,
             author: create(:user),
             file_name: original_file_name,
             title: original_title,
             content: original_content,
             description: original_description)
    end

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

      it_behaves_like 'graphql update actions'

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
