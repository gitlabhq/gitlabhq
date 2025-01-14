# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a tag', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }

  let(:input) { { project_path: project_path, name: tag_name, ref: ref, message: message } }
  let(:project_path) { project.full_path }
  let(:tag_name) { 'tag1' }
  let(:ref) { 'master' }
  let(:message) { '' }

  let(:mutation) { graphql_mutation(:tag_create, input) }
  let(:mutation_response) { graphql_mutation_response(:tag_create) }

  shared_examples 'creates a tag' do
    specify do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['tag']).to include(
        'name' => tag_name,
        'message' => message,
        'commit' => a_hash_including('id')
      )
      expect(mutation_response['errors']).to eq([])
    end
  end

  context 'when project is public' do
    let(:project) { create(:project, :public, :small_repo) }

    context 'when user is not allowed to create a tag' do
      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when user is a direct project member' do
      context 'and user is a developer' do
        before do
          project.add_developer(current_user)
        end

        it_behaves_like 'creates a tag'

        context 'when message is not provided' do
          let(:input) { { project_path: project_path, name: tag_name, ref: ref } }

          it_behaves_like 'creates a tag'
        end

        context 'when arguments are incorrect' do
          let(:tag_name) { '' }

          it_behaves_like 'a mutation that returns errors in the response', errors: ['Tag name invalid']
        end

        context 'when path is not correct' do
          let(:project_path) { 'unknown' }

          it_behaves_like 'a mutation that returns a top-level access error'
        end
      end
    end
  end
end
