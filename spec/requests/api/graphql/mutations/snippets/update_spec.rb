# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a Snippet' do
  include GraphqlHelpers

  let_it_be(:original_content) { 'Initial content' }
  let_it_be(:original_description) { 'Initial description' }
  let_it_be(:original_title) { 'Initial title' }
  let_it_be(:original_file_name) { 'Initial file_name' }

  let(:updated_content) { 'Updated content' }
  let(:updated_description) { 'Updated description' }
  let(:updated_title) { 'Updated_title' }
  let(:current_user) { snippet.author }
  let(:updated_file) { 'CHANGELOG' }
  let(:deleted_file) { 'README' }
  let(:snippet_gid) { GitlabSchema.id_from_object(snippet).to_s }
  let(:mutation_vars) do
    {
      id: snippet_gid,
      description: updated_description,
      visibility_level: 'public',
      title: updated_title,
      blob_actions: [
        { action: :update, filePath: updated_file, content: updated_content },
        { action: :delete, filePath: deleted_file }
      ]
    }
  end

  let(:mutation) do
    graphql_mutation(:update_snippet, mutation_vars)
  end

  def mutation_response
    graphql_mutation_response(:update_snippet)
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'graphql update actions' do
    context 'when the user does not have permission' do
      let(:current_user) { create(:user) }

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

      it 'does not update the Snippet' do
        expect do
          subject
        end.not_to change { snippet.reload }
      end
    end

    context 'when the user has permission' do
      it 'updates the snippet record' do
        subject

        expect(snippet.reload.title).to eq(updated_title)
      end

      it 'updates the Snippet' do
        blob_to_update = blob_at(updated_file)
        blob_to_delete = blob_at(deleted_file)

        expect(blob_to_update.data).not_to eq updated_content
        expect(blob_to_delete).to be_present

        subject

        blob_to_update = blob_at(updated_file)
        blob_to_delete = blob_at(deleted_file)

        aggregate_failures do
          expect(blob_to_update.data).to eq updated_content
          expect(blob_to_delete).to be_nil
          expect(mutation_response['snippet']['title']).to eq(updated_title)
          expect(mutation_response['snippet']['description']).to eq(updated_description)
          expect(mutation_response['snippet']['visibilityLevel']).to eq('public')
        end
      end

      context 'when there are ActiveRecord validation errors' do
        let(:updated_title) { '' }

        it_behaves_like 'a mutation that returns errors in the response', errors: ["Title can't be blank"]

        it 'does not update the Snippet' do
          subject

          expect(snippet.reload.title).to eq(original_title)
        end

        it 'returns the Snippet with its original values' do
          blob_to_update = blob_at(updated_file)
          blob_to_delete = blob_at(deleted_file)

          subject

          aggregate_failures do
            expect(blob_at(updated_file).data).to eq blob_to_update.data
            expect(blob_at(deleted_file).data).to eq blob_to_delete.data
            expect(mutation_response['snippet']['title']).to eq(original_title)
            expect(mutation_response['snippet']['description']).to eq(original_description)
            expect(mutation_response['snippet']['visibilityLevel']).to eq('private')
          end
        end
      end

      it_behaves_like 'a mutation which can mutate a spammable' do
        let(:service) { Snippets::UpdateService }
      end

      def blob_at(filename)
        snippet.repository.blob_at('HEAD', filename)
      end
    end
  end

  describe 'PersonalSnippet' do
    let(:snippet) do
      create(:personal_snippet,
             :private,
             :repository,
             file_name: original_file_name,
             title: original_title,
             content: original_content,
             description: original_description)
    end

    it_behaves_like 'graphql update actions'
    it_behaves_like 'when the snippet is not found'
    it_behaves_like 'snippet edit usage data counters'
    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::Snippets::Update }
    end
  end

  describe 'ProjectSnippet' do
    let_it_be(:project) { create(:project, :private) }

    let(:snippet) do
      create(:project_snippet,
             :private,
             :repository,
             project: project,
             author: create(:user),
             file_name: original_file_name,
             title: original_title,
             content: original_content,
             description: original_description)
    end

    context 'when the author is not a member of the project' do
      it 'returns an an error' do
        subject
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

          subject
          errors = json_response['errors']

          expect(errors.first['message']).to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
        end
      end

      it_behaves_like 'snippet edit usage data counters'

      it_behaves_like 'has spam protection' do
        let(:mutation_class) { ::Mutations::Snippets::Update }
      end
    end

    it_behaves_like 'when the snippet is not found'
  end
end
