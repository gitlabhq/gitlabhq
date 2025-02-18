# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::RewriteHistoryService, feature_category: :source_code_management do
  subject(:service) { described_class.new(project, user) }

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, owner_of: project) }

  describe '#execute', :aggregate_failures do
    subject(:execute) { service.execute(blob_oids: blob_oids, redactions: redactions) }

    let(:blob_oids) { ['53855584db773c3df5b5f61f72974cb298822fbb'] }
    let(:redactions) { ['p455w0rd'] }

    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    it 'removes provided blobs and redacts text' do
      expect_rewrite_history_requests([
        gitaly_request_with_params(blobs: blob_oids),
        gitaly_request_with_params(redactions: redactions)
      ])

      is_expected.to be_success
    end

    context 'when only blobs are provided' do
      let(:redactions) { [] }

      it 'only removes blobs' do
        expect_rewrite_history_requests([
          gitaly_request_with_params(blobs: blob_oids)
        ])

        is_expected.to be_success
      end
    end

    context 'when only redactions are provided' do
      let(:blob_oids) { [] }

      it 'only redacts text' do
        expect_rewrite_history_requests([
          gitaly_request_with_params(redactions: redactions)
        ])

        is_expected.to be_success
      end
    end

    context 'when user does not have permissions' do
      let(:user) { create(:user, maintainer_of: project) }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('Access Denied')
      end
    end

    context 'when none of arguments are set' do
      let(:blob_oids) { [] }
      let(:redactions) { [] }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('not enough arguments')
      end
    end

    context 'when provided blob is invalid' do
      let(:blob_oids) { ['wrong'] }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to include('invalid object ID')
      end
    end

    context 'when provided redaction is invalid' do
      let(:redactions) { ["\n"] }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to include('redaction pattern contains newline')
      end
    end

    context 'when repository is already read only' do
      before do
        project.set_repository_read_only!
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('Repository already read-only')
      end

      it 'does not mark repository as writable, because it is locked by a different process' do
        execute

        expect(project.reload.repository_read_only).to eq(true)
      end
    end

    context 'when an error occurs after repository marked as read-only' do
      before do
        allow(Gitlab::GitalyClient::CleanupService).to receive(:new).and_raise(ArgumentError.new('Boom'))
      end

      it 'marks repository as writable' do
        expect(project).to receive(:set_repository_read_only!).and_call_original

        is_expected.to be_error
        expect(execute.message).to eq('Boom')

        expect(project.reload.repository_read_only).to eq(false)
      end
    end

    context 'when Gitaly RPC returns an error' do
      let(:error_message) { 'error message' }

      it 'returns a generic error message' do
        expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
          blobs_removal = array_including(gitaly_request_with_params(blobs: blob_oids))
          generic_error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::FAILED_PRECONDITION, error_message)
          expect(instance).to receive(:rewrite_history).with(blobs_removal, kind_of(Hash)).and_raise(generic_error)
        end

        execute

        expect(execute.message).to eq("9:#{error_message}")
      end
    end

    def expect_rewrite_history_requests(requests)
      expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        rewrite_history_requests = contain_exactly(
          gitaly_request_with_params(repository: project.repository.gitaly_repository),
          *requests
        )
        expect(instance).to receive(:rewrite_history)
          .with(rewrite_history_requests, kind_of(Hash))
          .and_return(Gitaly::RewriteHistoryResponse.new)
      end
    end
  end

  describe '#async_execute', :aggregate_failures do
    subject(:async_execute) { service.async_execute(blob_oids: blob_oids, redactions: redactions) }

    let(:blob_oids) { ['53855584db773c3df5b5f61f72974cb298822fbb'] }
    let(:redactions) { ['p455w0rd'] }

    it 'triggers a RewriteHistoryWorker job' do
      expect(::Repositories::RewriteHistoryWorker).to receive(:perform_async).with(
        project_id: project.id, user_id: user.id, blob_oids: blob_oids, redactions: redactions
      )

      is_expected.to be_success
    end

    context 'when user does not have permissions' do
      let(:user) { create(:user, maintainer_of: project) }

      it 'returns an error' do
        is_expected.to be_error
        expect(async_execute.message).to eq('Access Denied')
      end
    end

    context 'when none of arguments are set' do
      let(:blob_oids) { [] }
      let(:redactions) { [] }

      it 'returns an error' do
        is_expected.to be_error
        expect(async_execute.message).to eq('not enough arguments')
      end
    end
  end
end
