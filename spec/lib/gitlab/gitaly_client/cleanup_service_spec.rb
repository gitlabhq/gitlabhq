# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::CleanupService, feature_category: :gitaly do
  let(:project) { create(:project) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:client) { described_class.new(project.repository) }

  describe '#apply_bfg_object_map_stream' do
    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    it 'sends an apply_bfg_object_map_stream message' do
      expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        expect(instance).to receive(:apply_bfg_object_map_stream)
          .with(kind_of(Enumerator), kind_of(Hash))
          .and_return([])
      end

      client.apply_bfg_object_map_stream(StringIO.new)
    end
  end

  describe '#rewrite_history' do
    let(:blobs) { ['53855584db773c3df5b5f61f72974cb298822fbb'] }
    let(:redactions) { %w[hello world] }

    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    subject(:rewrite_history) { client.rewrite_history(blobs: blobs, redactions: redactions) }

    it 'sends a rewrite_history message' do
      expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        expect(instance).to receive(:rewrite_history)
          .with(array_including(
            gitaly_request_with_params(blobs: blobs),
            gitaly_request_with_params(redactions: redactions)
          ), kind_of(Hash))
          .and_return(Gitaly::RewriteHistoryResponse.new)
      end

      rewrite_history
    end

    context 'with a generic BadStatus error' do
      let(:generic_error) do
        GRPC::BadStatus.new(
          GRPC::Core::StatusCodes::FAILED_PRECONDITION,
          "error message"
        )
      end

      it 'raises the BadStatus error' do
        expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
          expect(instance).to receive(:rewrite_history)
            .with(array_including(
              gitaly_request_with_params(blobs: blobs),
              gitaly_request_with_params(redactions: redactions)
            ), kind_of(Hash))
            .and_raise(generic_error)
        end

        expect { rewrite_history }.to raise_error(GRPC::BadStatus)
      end
    end

    context 'with an empty request' do
      let(:blobs) { [] }
      let(:redactions) { [] }
      let(:empty_error) do
        GRPC::InvalidArgument.new('no object IDs or text replacements specified')
      end

      it 'raises an InvalidArgument error' do
        expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
          expect(instance).to receive(:rewrite_history)
            .with(array_including(
              gitaly_request_with_params(blobs: blobs),
              gitaly_request_with_params(redactions: redactions)
            ), kind_of(Hash))
            .and_raise(empty_error)
        end

        expect { rewrite_history }.to raise_error(ArgumentError, '3:no object IDs or text replacements specified')
      end
    end
  end
end
