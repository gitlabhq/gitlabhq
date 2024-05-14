# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a release', feature_category: :release_orchestration do
  include GraphqlHelpers
  include Presentable

  let_it_be(:public_user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, guests: guest, reporters: reporter, developers: developer, maintainers: maintainer) }
  let_it_be(:tag_name) { 'v1.1.0' }
  let_it_be(:release) { create(:release, project: project, tag: tag_name) }

  let(:mutation_name) { :release_delete }

  let(:project_path) { project.full_path }
  let(:mutation_arguments) do
    {
      projectPath: project_path,
      tagName: tag_name
    }
  end

  let(:mutation) do
    graphql_mutation(mutation_name, mutation_arguments, <<~FIELDS)
      release {
        tagName
      }
      errors
    FIELDS
  end

  let(:delete_release) { post_graphql_mutation(mutation, current_user: current_user) }
  let(:mutation_response) { graphql_mutation_response(mutation_name)&.with_indifferent_access }

  shared_examples 'unauthorized or not found error' do
    it 'returns a top-level error with message' do
      delete_release

      expect(mutation_response).to be_nil
      expect(graphql_errors.count).to eq(1)
      expect(graphql_errors.first['message']).to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
    end
  end

  context 'when the current user has access to update releases' do
    let(:current_user) { developer }

    it 'deletes the release' do
      expect { delete_release }.to change { Release.count }.by(-1)
    end

    it 'returns the deleted release' do
      delete_release

      expected_release = { tagName: tag_name }.with_indifferent_access

      expect(mutation_response[:release]).to eq(expected_release)
    end

    it 'does not remove the Git tag associated with the deleted release' do
      expect { delete_release }.not_to change { Project.find_by_id(project.id).repository.tag_count }
    end

    it 'returns no errors' do
      delete_release

      expect(mutation_response[:errors]).to eq([])
    end

    context 'validation' do
      context 'when the release does not exist' do
        let_it_be(:tag_name) { 'not-a-real-release' }

        it 'returns the release as null' do
          delete_release

          expect(mutation_response[:release]).to be_nil
        end

        it 'returns an errors-at-data message' do
          delete_release

          expect(mutation_response[:errors]).to eq(['Release does not exist'])
        end
      end

      context 'when the project does not exist' do
        let(:project_path) { 'not/a/real/path' }

        it_behaves_like 'unauthorized or not found error'
      end
    end
  end

  context "when the current user doesn't have access to update releases" do
    context 'when the current user is a Reporter' do
      let(:current_user) { reporter }

      it_behaves_like 'unauthorized or not found error'
    end

    context 'when the current user is a Guest' do
      let(:current_user) { guest }

      it_behaves_like 'unauthorized or not found error'
    end

    context 'when the current user is a public user' do
      let(:current_user) { public_user }

      it_behaves_like 'unauthorized or not found error'
    end
  end
end
