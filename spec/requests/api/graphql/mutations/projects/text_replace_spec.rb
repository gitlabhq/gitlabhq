# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projectTextReplace", feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, owner_of: project) }
  let_it_be(:repo) { project.repository }

  let(:async_rewrite_history) { false }
  let(:project_path) { project.full_path }
  let(:mutation_params) { { project_path: project_path, replacements: replacements } }
  let(:mutation) { graphql_mutation(:project_text_replace, mutation_params) }
  let(:replacements) do
    %w[
      p455w0rd
      foo==>bar
      literal:MM/DD/YYYY==>YYYY-MM-DD
    ]
  end

  let(:literal_replacements) do
    %w[
      literal:p455w0rd
      literal:foo==>bar
      literal:MM/DD/YYYY==>YYYY-MM-DD
    ]
  end

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: current_user) }

  before do
    stub_feature_flags(async_rewrite_history: async_rewrite_history)
  end

  describe 'Replacing text' do
    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    it 'prepends `literal:` to implicit replacements before submitting to rewriteHistory RPC' do
      expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        redactions = array_including(gitaly_request_with_params(redactions: literal_replacements))
        expect(instance).to receive(:rewrite_history)
          .with(redactions, kind_of(Hash))
          .and_return(Gitaly::RewriteHistoryResponse.new)
      end

      post_mutation

      expect(graphql_mutation_response(:project_text_replace)['errors']).not_to be_present
    end

    it 'does not audit the change in CE' do
      allow_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        redactions = array_including(gitaly_request_with_params(redactions: literal_replacements))
        allow(instance).to receive(:rewrite_history)
          .with(redactions, kind_of(Hash))
          .and_return(Gitaly::RewriteHistoryResponse.new)
      end

      expect { post_mutation }.not_to change { AuditEvent.count }
    end

    context 'when async_rewrite_history is enabled' do
      let(:async_rewrite_history) { true }

      it 'processes text redaction asynchoronously' do
        expect(Repositories::RewriteHistoryWorker).to receive(:perform_async).with(
          project_id: project.id, user_id: current_user.id, redactions: literal_replacements, blob_oids: []
        )

        post_mutation

        expect(graphql_mutation_response(:project_text_replace)['errors']).not_to be_present
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

    context 'when arg `replacements` is nil' do
      let(:replacements) { nil }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE.strip))
          Variable $projectTextReplaceInput of type projectTextReplaceInput! was provided invalid value for replacements (Expected value to not be null)
        MESSAGE
      end
    end

    context 'when arg `replacements` is an empty list' do
      let(:replacements) { [] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'replacements' on InputObject 'projectTextReplaceInput' is required. Expected type [String!]!
        MESSAGE
      end
    end

    context 'when arg `replacements` does not contain any valid strings' do
      let(:replacements) { ["", ""] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'replacements' on InputObject 'projectTextReplaceInput' is required. Expected type [String!]!
        MESSAGE
      end
    end

    context 'when arg `replacements` includes a regex' do
      let(:replacements) { ['regex:\bdriver\b==>pilot'] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'replacements' on InputObject 'projectTextReplaceInput' does not support 'regex:' or 'glob:' values.
        MESSAGE
      end
    end

    context 'when arg `replacements` includes a glob' do
      let(:replacements) { ['glob:**string**==>'] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'replacements' on InputObject 'projectTextReplaceInput' does not support 'regex:' or 'glob:' values.
        MESSAGE
      end
    end

    context 'when Gitaly RPC returns an error' do
      let(:error_message) { 'error message' }

      before do
        ::Gitlab::GitalyClient.clear_stubs!
      end

      it 'returns a generic error message' do
        expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
          redactions = array_including(gitaly_request_with_params(redactions: literal_replacements))
          generic_error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::FAILED_PRECONDITION, error_message)
          expect(instance).to receive(:rewrite_history).with(redactions, kind_of(Hash)).and_raise(generic_error)
        end

        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => "Internal server error: 9:#{error_message}"))
      end
    end
  end
end
