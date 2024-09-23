# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projectBlobsRemove", feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, owner_of: project) }
  let_it_be(:repo) { project.repository }

  let(:async_rewrite_history) { false }
  let(:project_path) { project.full_path }
  let(:mutation_params) { { project_path: project_path, blob_oids: blob_oids } }
  let(:mutation) { graphql_mutation(:project_blobs_remove, mutation_params) }
  let(:blob_oids) { ['53855584db773c3df5b5f61f72974cb298822fbb'] }

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: current_user) }

  before do
    stub_feature_flags(async_rewrite_history: async_rewrite_history)
  end

  describe 'Removing blobs:' do
    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    it 'submits blobs to rewriteHistory RPC' do
      expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        blobs = array_including(gitaly_request_with_params(blobs: blob_oids))
        expect(instance).to receive(:rewrite_history)
          .with(blobs, kind_of(Hash))
          .and_return(Gitaly::RewriteHistoryResponse.new)
      end

      post_mutation

      expect(graphql_mutation_response(:project_blobs_remove)['errors']).not_to be_present
    end

    it 'does not create an audit event' do
      allow_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        blobs = array_including(gitaly_request_with_params(blobs: blob_oids))
        allow(instance).to receive(:rewrite_history)
          .with(blobs, kind_of(Hash))
          .and_return(Gitaly::RewriteHistoryResponse.new)
      end

      expect { post_mutation }.not_to change { AuditEvent.count }
    end

    context 'when async_rewrite_history is enabled' do
      let(:async_rewrite_history) { true }

      it 'processes text redaction asynchoronously' do
        expect(Repositories::RewriteHistoryWorker).to receive(:perform_async).with(
          project_id: project.id, user_id: current_user.id, blob_oids: blob_oids, redactions: []
        )

        post_mutation

        expect(graphql_mutation_response(:project_blobs_remove)['errors']).not_to be_present
      end
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

    context 'when Gitaly RPC returns an error' do
      before do
        ::Gitlab::GitalyClient.clear_stubs!
      end

      let(:error_message) { 'error message' }

      it 'returns a generic error message' do
        expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
          blobs = array_including(gitaly_request_with_params(blobs: blob_oids))
          generic_error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::FAILED_PRECONDITION, error_message)
          expect(instance).to receive(:rewrite_history).with(blobs, kind_of(Hash)).and_raise(generic_error)
        end

        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => "Internal server error: 9:#{error_message}"))
      end
    end
  end
end
