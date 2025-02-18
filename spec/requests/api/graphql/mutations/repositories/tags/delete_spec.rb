# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deletion of a tag', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }

  let(:input) { { project_path: project_path, name: tag_name } }
  let(:project_path) { project.full_path }
  let(:tag_name) { 'tag1' }

  let(:mutation) { graphql_mutation(:tag_delete, input) }
  let(:mutation_response) { graphql_mutation_response(:tag_delete) }

  shared_examples 'deletes a tag' do
    specify do
      expect(project.repository.find_tag(tag_name)).to be_present

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)

      expect(mutation_response).to have_key('tag')
      expect(mutation_response['tag']).to be_nil
      expect(mutation_response['errors']).to be_empty

      expect(project.repository.find_tag(tag_name)).to be_nil
    end
  end

  context 'when project is public' do
    let(:project) { create(:project, :public, :small_repo, create_tag: 'tag1') }

    context 'when user is not allowed to delete a tag' do
      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when user is a direct project member' do
      context 'and user is a developer' do
        before do
          project.add_developer(current_user)
        end

        it_behaves_like 'deletes a tag'

        context 'when name is not correct' do
          let(:tag_name) { 'unknown' }

          it_behaves_like 'a mutation that returns errors in the response', errors: ['No such tag']
        end

        context 'when name is empty' do
          let(:tag_name) { '' }

          it_behaves_like 'a mutation that returns errors in the response', errors: ['No such tag']
        end

        context 'when path is not correct' do
          let(:project_path) { 'unknown' }

          it_behaves_like 'a mutation that returns a top-level access error'
        end

        context 'when tag is protected' do
          before do
            create(:protected_tag, project: project, name: tag_name)
          end

          it_behaves_like 'a mutation that returns errors in the response',
            errors: ["You don't have access to delete the tag"]
        end
      end
    end
  end
end
