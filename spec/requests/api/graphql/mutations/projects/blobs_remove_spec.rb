# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projectBlobsRemove", feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, owner_of: project) }
  let_it_be(:repo) { project.repository }

  let(:project_path) { project.full_path }
  let(:mutation_params) { { project_path: project_path, blob_oids: blob_oids } }
  let(:mutation) { graphql_mutation(:project_blobs_remove, mutation_params) }
  let(:blob_oids) { ['53855584db773c3df5b5f61f72974cb298822fbb'] }

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: current_user) }

  describe 'Removing blobs:' do
    it 'processes text redaction asynchoronously' do
      expect(::Repositories::RewriteHistoryWorker).to receive(:perform_async).with(
        project_id: project.id, user_id: current_user.id, blob_oids: blob_oids, redactions: []
      )

      post_mutation

      expect(graphql_mutation_response(:project_blobs_remove)['errors']).not_to be_present
    end
  end

  describe 'Invalid requests:' do
    context 'when the current_user is a maintainer' do
      let(:current_user) { create(:user, maintainer_of: project) }

      it_behaves_like 'a mutation on an unauthorized resource'
    end

    context 'when arg `projectPath` is invalid' do
      let(:project_path) { 'gid://Gitlab/User/1' }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE.strip))
          The resource that you are attempting to access does not exist or you don't have permission to perform this action
        MESSAGE
      end
    end

    context 'when arg `blob_oids` is nil' do
      let(:blob_oids) { nil }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE.strip))
          Variable $projectBlobsRemoveInput of type projectBlobsRemoveInput! was provided invalid value for blobOids (Expected value to not be null)
        MESSAGE
      end
    end

    context 'when arg `blob_oids` is an empty list' do
      let(:blob_oids) { [] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'blobOids' on InputObject 'projectBlobsRemoveInput' is required. Expected type [String!]!
        MESSAGE
      end
    end

    context 'when arg `blob_oids` does not contain any valid strings' do
      let(:blob_oids) { ["", ""] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'blobOids' on InputObject 'projectBlobsRemoveInput' is required. Expected type [String!]!
        MESSAGE
      end
    end
  end
end
