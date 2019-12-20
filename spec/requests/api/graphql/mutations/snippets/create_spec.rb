# frozen_string_literal: true

require 'spec_helper'

describe 'Creating a Snippet' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:content) { 'Initial content' }
  let(:description) { 'Initial description' }
  let(:title) { 'Initial title' }
  let(:file_name) { 'Initial file_name' }
  let(:visibility_level) { 'public' }
  let(:project_path) { nil }

  let(:mutation) do
    variables = {
      content: content,
      description: description,
      visibility_level: visibility_level,
      file_name: file_name,
      title: title,
      project_path: project_path
    }

    graphql_mutation(:create_snippet, variables)
  end

  def mutation_response
    graphql_mutation_response(:create_snippet)
  end

  context 'when the user does not have permission' do
    let(:current_user) { nil }

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

    it 'does not create the Snippet' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { Snippet.count }
    end

    context 'when user is not authorized in the project' do
      let(:project_path) { project.full_path }

      it 'does not create the snippet when the user is not authorized' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change { Snippet.count }
      end
    end
  end

  context 'when the user has permission' do
    let(:current_user) { user }

    context 'with PersonalSnippet' do
      it 'creates the Snippet' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { Snippet.count }.by(1)
      end

      it 'returns the created Snippet' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['snippet']['content']).to eq(content)
        expect(mutation_response['snippet']['title']).to eq(title)
        expect(mutation_response['snippet']['description']).to eq(description)
        expect(mutation_response['snippet']['fileName']).to eq(file_name)
        expect(mutation_response['snippet']['visibilityLevel']).to eq(visibility_level)
        expect(mutation_response['snippet']['project']).to be_nil
      end
    end

    context 'with ProjectSnippet' do
      let(:project_path) { project.full_path }

      before do
        project.add_developer(current_user)
      end

      it 'creates the Snippet' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { Snippet.count }.by(1)
      end

      it 'returns the created Snippet' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['snippet']['content']).to eq(content)
        expect(mutation_response['snippet']['title']).to eq(title)
        expect(mutation_response['snippet']['description']).to eq(description)
        expect(mutation_response['snippet']['fileName']).to eq(file_name)
        expect(mutation_response['snippet']['visibilityLevel']).to eq(visibility_level)
        expect(mutation_response['snippet']['project']['fullPath']).to eq(project_path)
      end

      context 'when the project path is invalid' do
        let(:project_path) { 'foobar' }

        it 'returns an an error' do
          post_graphql_mutation(mutation, current_user: current_user)
          errors = json_response['errors']

          expect(errors.first['message']).to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
        end
      end

      context 'when the feature is disabled' do
        it 'returns an an error' do
          project.project_feature.update_attribute(:snippets_access_level, ProjectFeature::DISABLED)

          post_graphql_mutation(mutation, current_user: current_user)
          errors = json_response['errors']

          expect(errors.first['message']).to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
        end
      end
    end

    context 'when there are ActiveRecord validation errors' do
      let(:title) { '' }

      it_behaves_like 'a mutation that returns errors in the response', errors: ["Title can't be blank"]

      it 'does not create the Snippet' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change { Snippet.count }
      end

      it 'does not return Snippet' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['snippet']).to be_nil
      end
    end
  end
end
